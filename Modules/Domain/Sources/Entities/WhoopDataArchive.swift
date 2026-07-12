import Foundation

public struct WhoopDataArchive: Equatable, Sendable {
    public let account: WhoopAccount
    public let cycles: [WhoopCycle]
    public let recoveries: [WhoopRecovery]
    public let sleeps: [WhoopSleep]
    public let workouts: [WhoopWorkout]
    public let lastSynchronizedAt: Date

    public init(
        account: WhoopAccount,
        cycles: [WhoopCycle],
        recoveries: [WhoopRecovery],
        sleeps: [WhoopSleep],
        workouts: [WhoopWorkout],
        lastSynchronizedAt: Date
    ) {
        self.account = account
        self.cycles = cycles
        self.recoveries = recoveries
        self.sleeps = sleeps
        self.workouts = workouts
        self.lastSynchronizedAt = lastSynchronizedAt
    }
}
