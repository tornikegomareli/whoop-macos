import AuthenticationServices
import Foundation
import WhoopScopeDomain

@MainActor
public final class OAuthWebAuthorizer: OAuthAuthorizing {
    private let contextProvider = OAuthPresentationContextProvider()
    private var session: ASWebAuthenticationSession?

    public init() {}

    public func authorize(using url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme,
                completionHandler: OAuthCallbackBridge.makeHandler(
                    continuation: continuation
                ) { [weak self] in
                    self?.session = nil
                }
            )

            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = false
            self.session = session

            guard session.start() else {
                self.session = nil
                continuation.resume(throwing: AuthenticationError.invalidCallback)
                return
            }
        }
    }
}
