import Foundation

@MainActor
final class OAuthTokenRefreshCoordinator {
    private var task: Task<OAuthTokenSet, any Error>?

    func tokenSet(
        operation: @escaping @MainActor @Sendable () async throws -> OAuthTokenSet
    ) async throws -> OAuthTokenSet {
        if let task {
            return try await task.value
        }

        let task = Task { try await operation() }
        self.task = task
        defer { self.task = nil }
        return try await task.value
    }
}
