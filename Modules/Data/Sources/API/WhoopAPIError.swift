import Foundation

public enum WhoopAPIError: LocalizedError, Equatable, Sendable {
    case invalidResponse
    case unauthorized
    case rateLimited
    case server(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "WHOOP returned data WhoopScope could not read."
        case .unauthorized:
            "WHOOP authorization expired. Please reconnect your account."
        case .rateLimited:
            "WHOOP is temporarily rate limiting requests. Please try again shortly."
        case let .server(statusCode):
            "WHOOP returned an API error (HTTP \(statusCode))."
        }
    }
}
