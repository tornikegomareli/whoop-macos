import Foundation
import WhoopScopeDomain
import WhoopScopePersistence

public struct LiveTrendsRepository: TrendsRepository, Sendable {
    private let synchronizer: WhoopDataSynchronizer
    private let database: WhoopScopeDatabase
    private let now: @Sendable () -> Date

    public init(
        synchronizer: WhoopDataSynchronizer,
        database: WhoopScopeDatabase,
        now: @escaping @Sendable () -> Date = { Date.now }
    ) {
        self.synchronizer = synchronizer
        self.database = database
        self.now = now
    }

    public func trends(range: TrendRange, refresh: Bool) async throws -> TrendsSnapshot {
        var archive = try await database.readArchive()
        let isStale = archive.map {
            now().timeIntervalSince($0.lastSynchronizedAt) > 15 * 60
        } ?? true

        if refresh || isStale {
            do {
                try await synchronizer.synchronize()
                archive = try await database.readArchive()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard archive != nil else { throw error }
            }
        }

        guard let archive else {
            throw WhoopAPIError.invalidResponse
        }
        return try TrendsSnapshotBuilder.build(
            from: archive,
            range: range,
            now: now()
        )
    }
}
