import Foundation
import WhoopScopeDomain
import WhoopScopePersistence

public struct LiveDashboardRepository: DashboardRepository, Sendable {
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

    public func dashboard() async throws -> DashboardSnapshot {
        let storedArchive = try await database.readArchive()
        do {
            try await synchronize()
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

    private func synchronize() async throws {
        let synchronizedAt = now()
        let profile = try await apiClient.profile().domainValue
        let bodyMeasurements = try await apiClient.bodyMeasurements().domainValue
        try await database.save(
            WhoopAccount(
                profile: profile,
                bodyMeasurements: bodyMeasurements,
                syncedAt: synchronizedAt
            )
        )

        let watermarks = try await database.activityWatermarks()
        let cycles = try await apiClient.cycles(
            startingAt: incrementalStart(watermarks.cycleStart)
        )
        let recoveries = try await apiClient.recoveries(
            startingAt: incrementalStart(watermarks.recoveryStart)
        )
        let sleeps = try await apiClient.sleeps(
            startingAt: incrementalStart(watermarks.sleepStart)
        )
        let workouts = try await apiClient.workouts(
            startingAt: incrementalStart(watermarks.workoutStart)
        )
        try await database.saveActivities(
            cycles: cycles,
            recoveries: recoveries,
            sleeps: sleeps,
            workouts: workouts,
            synchronizedAt: synchronizedAt
        )
    }

    private func incrementalStart(_ latestStart: Date?) -> Date? {
        latestStart?.addingTimeInterval(-7 * 24 * 60 * 60)
    }
}
