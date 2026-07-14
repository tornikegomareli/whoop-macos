import Foundation
import WhoopScopeDomain
import WhoopScopePersistence

public actor WhoopDataSynchronizer {
    private let apiClient: WhoopAPIClient
    private let database: WhoopScopeDatabase
    private let now: @Sendable () -> Date
    private var inFlight: Task<Void, any Error>?

    public init(
        apiClient: WhoopAPIClient,
        database: WhoopScopeDatabase,
        now: @escaping @Sendable () -> Date = { Date.now }
    ) {
        self.apiClient = apiClient
        self.database = database
        self.now = now
    }

    public func synchronize() async throws {
        if let inFlight {
            return try await inFlight.value
        }

        let apiClient = apiClient
        let database = database
        let synchronizedAt = now()
        let task = Task {
            try await Self.performSynchronization(
                apiClient: apiClient,
                database: database,
                synchronizedAt: synchronizedAt
            )
        }
        inFlight = task

        do {
            try await task.value
            inFlight = nil
        } catch {
            inFlight = nil
            throw error
        }
    }

    private static func performSynchronization(
        apiClient: WhoopAPIClient,
        database: WhoopScopeDatabase,
        synchronizedAt: Date
    ) async throws {
        let profileDTO = try await apiClient.profile()
        let bodyMeasurementsDTO = try await apiClient.bodyMeasurements()
        try await database.save(
            WhoopAccount(
                profile: profileDTO.domainValue,
                bodyMeasurements: bodyMeasurementsDTO.domainValue,
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

    private static func incrementalStart(_ latestStart: Date?) -> Date? {
        latestStart?.addingTimeInterval(-7 * 24 * 60 * 60)
    }
}
