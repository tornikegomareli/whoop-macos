import Foundation
import WhoopScopeDomain

public struct WhoopAPIClient: Sendable {
    public typealias AccessTokenProvider = @Sendable (_ forceRefresh: Bool) async throws -> String
    public typealias RetrySleep = @Sendable (_ seconds: TimeInterval) async throws -> Void

    private let baseURL: URL
    private let accessToken: AccessTokenProvider
    private let session: URLSession
    private let retrySleep: RetrySleep

    public init(
        baseURL: URL = URL(string: "https://api.prod.whoop.com/developer/v2/")!,
        accessToken: @escaping AccessTokenProvider,
        session: URLSession = .shared,
        retrySleep: @escaping RetrySleep = {
            try await Task.sleep(for: .seconds($0))
        }
    ) {
        self.baseURL = baseURL
        self.accessToken = accessToken
        self.session = session
        self.retrySleep = retrySleep
    }

    func profile() async throws -> WhoopUserProfileDTO {
        try await get(path: "user/profile/basic")
    }

    func bodyMeasurements() async throws -> WhoopBodyMeasurementsDTO {
        try await get(path: "user/measurement/body")
    }

    func cycles(startingAt start: Date?) async throws -> [WhoopCycle] {
        try await allRecords(path: "cycle", startingAt: start, as: WhoopCycleDTO.self)
            .map { try $0.domainValue }
    }

    func recoveries(startingAt start: Date?) async throws -> [WhoopRecovery] {
        try await allRecords(path: "recovery", startingAt: start, as: WhoopRecoveryDTO.self)
            .map { try $0.domainValue }
    }

    func sleeps(startingAt start: Date?) async throws -> [WhoopSleep] {
        try await allRecords(path: "activity/sleep", startingAt: start, as: WhoopSleepDTO.self)
            .map { try $0.domainValue }
    }

    func workouts(startingAt start: Date?) async throws -> [WhoopWorkout] {
        try await allRecords(path: "activity/workout", startingAt: start, as: WhoopWorkoutDTO.self)
            .map { try $0.domainValue }
    }

    private func allRecords<Record: Decodable & Sendable>(
        path: String,
        startingAt start: Date?,
        as _: Record.Type
    ) async throws -> [Record] {
        var records: [Record] = []
        var nextToken: String?
        var seenTokens: Set<String> = []

        repeat {
            try Task.checkCancellation()
            var queryItems = [URLQueryItem(name: "limit", value: "25")]
            if let start {
                queryItems.append(
                    URLQueryItem(
                        name: "start",
                        value: Self.iso8601String(from: start)
                    )
                )
            }
            if let nextToken {
                queryItems.append(URLQueryItem(name: "nextToken", value: nextToken))
            }

            let page: WhoopPage<Record> = try await get(
                path: path,
                queryItems: queryItems
            )
            records.append(contentsOf: page.records)

            guard let token = page.nextToken, !token.isEmpty else {
                nextToken = nil
                continue
            }
            guard seenTokens.insert(token).inserted else {
                throw WhoopAPIError.invalidResponse
            }
            nextToken = token
            try await Task.sleep(for: .milliseconds(650))
        } while nextToken != nil

        return records
    }

    private func get<Response: Decodable & Sendable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        guard var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else {
            throw WhoopAPIError.invalidResponse
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw WhoopAPIError.invalidResponse
        }

        var token = try await accessToken(false)
        var refreshedAuthorization = false
        var rateLimitRetries = 0

        while true {
            try Task.checkCancellation()
            let (data, response) = try await request(url: url, token: token)

            if response.statusCode == 401, !refreshedAuthorization {
                token = try await accessToken(true)
                refreshedAuthorization = true
                continue
            }

            if response.statusCode == 429, rateLimitRetries < 2 {
                rateLimitRetries += 1
                try await retrySleep(Self.retryDelay(from: response))
                continue
            }

            return try decode(data, response: response)
        }
    }

    private func request(
        url: URL,
        token: String
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw WhoopAPIError.invalidResponse
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhoopAPIError.invalidResponse
        }
        return (data, httpResponse)
    }

    private func decode<Response: Decodable & Sendable>(
        _ data: Data,
        response: HTTPURLResponse
    ) throws -> Response {
        switch response.statusCode {
        case 200..<300:
            break
        case 401:
            throw WhoopAPIError.unauthorized
        case 429:
            throw WhoopAPIError.rateLimited
        default:
            throw WhoopAPIError.server(statusCode: response.statusCode)
        }

        do {
            return try Self.makeResponseDecoder().decode(Response.self, from: data)
        } catch {
            throw WhoopAPIError.invalidResponse
        }
    }

    static func makeResponseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let value = try container.decode(String.self)
                guard let date = Self.iso8601Date(from: value) else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid ISO 8601 date"
                    )
                }
                return date
        }
        return decoder
    }

    static func retryDelay(from response: HTTPURLResponse) -> TimeInterval {
        let headerValue = response.value(forHTTPHeaderField: "X-RateLimit-Reset")
            ?? response.value(forHTTPHeaderField: "Retry-After")
        let serverDelay = headerValue.flatMap(TimeInterval.init)
        return min(max(serverDelay ?? 2, 1), 60)
    }

    private static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private static func iso8601Date(from value: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
