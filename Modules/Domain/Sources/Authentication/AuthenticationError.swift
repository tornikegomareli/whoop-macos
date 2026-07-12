import Foundation

public enum AuthenticationError: LocalizedError, Equatable, Sendable {
    case invalidCredentials
    case sessionExpired
    case insecureBrokerURL
    case brokerUnavailable
    case invalidCallback
    case stateMismatch
    case authorizationDenied
    case missingRefreshToken
    case keychainFailure
    case server(statusCode: Int)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "WHOOP rejected the app credentials configured on the authentication broker."
        case .sessionExpired:
            "Your WHOOP session expired. Please connect your account again."
        case .insecureBrokerURL:
            "WhoopScope requires an HTTPS authentication broker."
        case .brokerUnavailable:
            "WhoopScope could not reach its authentication service. Please try again."
        case .invalidCallback:
            "WHOOP returned an invalid authorization response."
        case .stateMismatch:
            "The authorization response could not be verified. Please try again."
        case .authorizationDenied:
            "WHOOP authorization was cancelled or denied."
        case .missingRefreshToken:
            "WHOOP did not return an offline refresh token."
        case .keychainFailure:
            "WhoopScope could not securely save credentials in Keychain."
        case let .server(statusCode):
            "WHOOP returned an authentication error (HTTP \(statusCode))."
        case .invalidResponse:
            "WHOOP returned an authentication response WhoopScope could not read."
        }
    }
}
