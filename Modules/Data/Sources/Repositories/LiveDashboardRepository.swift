import Foundation
import WhoopScopeDomain
import WhoopScopePersistence

public struct LiveDashboardRepository: DashboardRepository, Sendable {
    private let synchronizer: WhoopDataSynchronizer
    private let database: WhoopScopeDatabase
    private let now: @Sendable () -> Date

    public init(
        apiClient: WhoopAPIClient,
        database: WhoopScopeDatabase,
        now: @escaping @Sendable () -> Date = { Date.now }
    ) {
        self.synchronizer = WhoopDataSynchronizer(
            apiClient: apiClient,
            database: database,
            now: now
        )
        self.database = database
        self.now = now
    }

    public init(
        synchronizer: WhoopDataSynchronizer,
        database: WhoopScopeDatabase,
        now: @escaping @Sendable () -> Date = { Date.now }
    ) {
        self.synchronizer = synchronizer
        self.database = database
        self.now = now
    }

    public func dashboard() async throws -> DashboardSnapshot {
        let storedArchive = try await database.readArchive()
        do {
            try await synchronizer.synchronize()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let storedArchive {
                return try DashboardSnapshotBuilder.build(
                    from: storedArchive,
                    now: now()
                )
            }
            throw error
        }

        guard let archive = try await database.readArchive() else {
            throw WhoopAPIError.invalidResponse
        }
        return try DashboardSnapshotBuilder.build(from: archive, now: now())
    }

}
