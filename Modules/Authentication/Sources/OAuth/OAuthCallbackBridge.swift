import AuthenticationServices
import Foundation
import WhoopScopeDomain

enum OAuthCallbackBridge {
    nonisolated static func makeHandler(
        continuation: CheckedContinuation<URL, any Error>,
        didFinish: @escaping @MainActor @Sendable () -> Void
    ) -> ASWebAuthenticationSession.CompletionHandler {
        { callbackURL, error in
            let result = result(callbackURL: callbackURL, error: error)

            Task { @MainActor in
                didFinish()
                switch result {
                case let .success(callbackURL):
                    continuation.resume(returning: callbackURL)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private nonisolated static func result(
        callbackURL: URL?,
        error: (any Error)?
    ) -> Result<URL, AuthenticationError> {
        if let authenticationError = error as? ASWebAuthenticationSessionError,
           authenticationError.code == .canceledLogin
        {
            return .failure(.authorizationDenied)
        }
        if error != nil {
            return .failure(.invalidCallback)
        }
        if let callbackURL {
            return .success(callbackURL)
        }
        return .failure(.invalidCallback)
    }
}
