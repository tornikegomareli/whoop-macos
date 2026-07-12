import Foundation
import WhoopScopeDomain

@MainActor
public final class WhoopBrokerAuthenticationService: AuthenticationService {
    private let brokerBaseURL: URL
    private let keychain: KeychainStore
    private let webAuthorizer: any OAuthAuthorizing
    private let session: URLSession
    private let refreshCoordinator = OAuthTokenRefreshCoordinator()

    public init(
        brokerBaseURL: URL,
        webAuthorizer: any OAuthAuthorizing,
        session: URLSession = .shared
    ) {
        self.brokerBaseURL = brokerBaseURL
        self.keychain = KeychainStore()
        self.webAuthorizer = webAuthorizer
        self.session = session
    }

    public func status() async -> AuthenticationStatus {
        try? await keychain.delete(.legacyClientCredentials)
        do {
            let tokenSet = try await keychain.read(OAuthTokenSet.self, for: .tokenSet)
            return tokenSet == nil ? .signedOut : .signedIn
        } catch {
            return .signedOut
        }
    }

    public func signIn() async throws {
        try validateBrokerURL()
        let installationID = try await installationID()
        let publicConfiguration = try await fetchPublicConfiguration(
            installationID: installationID
        )
        let state = String(UUID().uuidString.replacing("-", with: "").prefix(8))
        let authorizationURL = try publicConfiguration.authorizationURL(state: state)
        let callbackURL = try await webAuthorizer.authorize(
            using: authorizationURL,
            callbackScheme: publicConfiguration.callbackScheme
        )
        let code = try authorizationCode(from: callbackURL, expectedState: state)
        let tokens = try await post(
            path: "v1/oauth/exchange",
            body: ["code": code],
            installationID: installationID,
            response: WhoopTokenResponse.self
        )
        try await keychain.save(try makeTokenSet(from: tokens), as: .tokenSet)
    }

    public func signOut() async throws {
        var revocationError: (any Error)?
        if let tokenSet = try await keychain.read(OAuthTokenSet.self, for: .tokenSet) {
            do {
                let accessToken = try await validAccessToken(from: tokenSet)
                var request = URLRequest(url: Self.revokeURL)
                request.httpMethod = "DELETE"
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                let (_, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AuthenticationError.invalidResponse
                }
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw AuthenticationError.server(statusCode: httpResponse.statusCode)
                }
            } catch {
                revocationError = error
            }
        }
        try await keychain.delete(.tokenSet)

        if let authenticationError = revocationError as? AuthenticationError {
            switch authenticationError {
            case .sessionExpired, .invalidCredentials, .server(statusCode: 401):
                return
            default:
                throw authenticationError
            }
        }
        if let revocationError {
            throw revocationError
        }
    }

    public func accessToken(forceRefresh: Bool = false) async throws -> String {
        guard let tokenSet = try await keychain.read(OAuthTokenSet.self, for: .tokenSet) else {
            throw AuthenticationError.authorizationDenied
        }
        return try await validAccessToken(from: tokenSet, forceRefresh: forceRefresh)
    }

    private func validAccessToken(
        from tokenSet: OAuthTokenSet,
        forceRefresh: Bool = false
    ) async throws -> String {
        guard forceRefresh || tokenSet.expiresAt <= Date.now.addingTimeInterval(60) else {
            return tokenSet.accessToken
        }
        let refreshed = try await refreshCoordinator.tokenSet { [self] in
            let latestTokenSet = try await keychain.read(
                OAuthTokenSet.self,
                for: .tokenSet
            ) ?? tokenSet
            let installationID = try await installationID()
            let response = try await post(
                path: "v1/oauth/refresh",
                body: ["refresh_token": latestTokenSet.refreshToken],
                installationID: installationID,
                response: WhoopTokenResponse.self
            )
            let refreshed = try makeTokenSet(from: response)
            try await keychain.save(refreshed, as: .tokenSet)
            return refreshed
        }
        return refreshed.accessToken
    }

    private func fetchPublicConfiguration(
        installationID: String
    ) async throws -> BrokerPublicConfiguration {
        var request = URLRequest(url: brokerBaseURL.appending(path: "v1/config"))
        request.setValue(installationID, forHTTPHeaderField: "X-WhoopScope-Install-ID")
        return try await execute(request, response: BrokerPublicConfiguration.self)
    }

    private func post<Response: Decodable & Sendable>(
        path: String,
        body: [String: String],
        installationID: String,
        response: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: brokerBaseURL.appending(path: path))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(installationID, forHTTPHeaderField: "X-WhoopScope-Install-ID")
        do {
            return try await execute(request, response: response)
        } catch AuthenticationError.invalidCredentials
            where path == "v1/oauth/refresh"
        {
            throw AuthenticationError.sessionExpired
        }
    }

    private func execute<Response: Decodable & Sendable>(
        _ request: URLRequest,
        response: Response.Type
    ) async throws -> Response {
        let data: Data
        let urlResponse: URLResponse
        do {
            (data, urlResponse) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw AuthenticationError.brokerUnavailable
        }

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw AuthenticationError.invalidResponse
        }
        if httpResponse.statusCode == 401 {
            throw AuthenticationError.invalidCredentials
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AuthenticationError.server(statusCode: httpResponse.statusCode)
        }
        do {
            return try JSONDecoder().decode(response, from: data)
        } catch {
            throw AuthenticationError.invalidResponse
        }
    }

    private func installationID() async throws -> String {
        if let existing = try await keychain.read(String.self, for: .installationID) {
            return existing
        }
        let identifier = UUID().uuidString
        try await keychain.save(identifier, as: .installationID)
        return identifier
    }

    private func authorizationCode(
        from callbackURL: URL,
        expectedState: String
    ) throws -> String {
        guard let components = URLComponents(
            url: callbackURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw AuthenticationError.invalidCallback
        }
        let values = Dictionary(
            uniqueKeysWithValues: components.queryItems?.compactMap { item in
                item.value.map { (item.name, $0) }
            } ?? []
        )
        if values["error"] != nil {
            throw AuthenticationError.authorizationDenied
        }
        guard values["state"] == expectedState else {
            throw AuthenticationError.stateMismatch
        }
        guard let code = values["code"], !code.isEmpty else {
            throw AuthenticationError.invalidCallback
        }
        return code
    }

    private func makeTokenSet(from response: WhoopTokenResponse) throws -> OAuthTokenSet {
        guard let refreshToken = response.refreshToken else {
            throw AuthenticationError.missingRefreshToken
        }
        return OAuthTokenSet(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expiresAt: Date.now.addingTimeInterval(response.expiresIn),
            scope: response.scope,
            tokenType: response.tokenType
        )
    }

    private func validateBrokerURL() throws {
        let isLocalhost = brokerBaseURL.host == "127.0.0.1"
            || brokerBaseURL.host == "localhost"
        guard brokerBaseURL.scheme == "https" || (brokerBaseURL.scheme == "http" && isLocalhost) else {
            throw AuthenticationError.insecureBrokerURL
        }
    }

    private static let revokeURL: URL = {
        guard let url = URL(string: "https://api.prod.whoop.com/developer/v2/user/access") else {
            fatalError("Invalid built-in WHOOP revocation URL")
        }
        return url
    }()
}
