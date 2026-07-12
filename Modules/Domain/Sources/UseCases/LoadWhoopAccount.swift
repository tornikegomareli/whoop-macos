import Foundation

public struct LoadWhoopAccount: LoadWhoopAccountUseCase, Sendable {
    private let repository: any WhoopAccountRepository

    public init(repository: any WhoopAccountRepository) {
        self.repository = repository
    }

    public func execute(refresh: Bool) async throws -> WhoopAccount? {
        if refresh {
            return try await repository.refreshAccount()
        }
        return try await repository.storedAccount()
    }
}
