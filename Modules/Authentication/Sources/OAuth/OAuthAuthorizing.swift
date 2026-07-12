import Foundation

public protocol OAuthAuthorizing: Sendable {
    @MainActor
    func authorize(using url: URL, callbackScheme: String) async throws -> URL
}

