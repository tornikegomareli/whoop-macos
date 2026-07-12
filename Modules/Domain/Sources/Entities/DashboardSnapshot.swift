import Foundation

public struct DashboardSnapshot: Equatable, Sendable {
    public let date: Date
    public let displayName: String
    public let recovery: RecoverySummary
    public let strain: StrainSummary
    public let sleep: SleepSummary
    public let history: [DailyMetrics]
    public let recentWorkouts: [WorkoutSummary]
    public let lastSynchronizedAt: Date

    public init(
        date: Date,
        displayName: String,
        recovery: RecoverySummary,
        strain: StrainSummary,
        sleep: SleepSummary,
        history: [DailyMetrics],
        recentWorkouts: [WorkoutSummary],
        lastSynchronizedAt: Date
    ) {
        self.date = date
        self.displayName = displayName
        self.recovery = recovery
        self.strain = strain
        self.sleep = sleep
        self.history = history
        self.recentWorkouts = recentWorkouts
        self.lastSynchronizedAt = lastSynchronizedAt
    }
}

