import Foundation
import WhoopScopeDomain
import WhoopScopePersistence

public struct LiveWhoopAccountRepository: WhoopAccountRepository, Sendable {
    private let apiClient: WhoopAPIClient
    private let database: WhoopScopeDatabase
    private let now: @Sendable () -> Date

    public init(
        apiClient: WhoopAPIClient,
        database: WhoopScopeDatabase,
        now: @escaping @Sendable () -> Date = { Date.now }
    ) {
        self.apiClient = apiClient
        self.database = database
        self.now = now
    }

    public func storedAccount() async throws -> WhoopAccount? {
        try await database.readAccount()
    }

    public func refreshAccount() async throws -> WhoopAccount {
        async let profile = apiClient.profile()
        async let bodyMeasurements = apiClient.bodyMeasurements()

        let account = try await WhoopAccount(
            profile: profile.domainValue,
            bodyMeasurements: bodyMeasurements.domainValue,
            syncedAt: now()
        )
        try await database.save(account)
        return account
    }
}
