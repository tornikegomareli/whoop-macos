import Foundation

public struct SleepSummary: Equatable, Sendable {
    public let performancePercentage: Int
    public let sleepNeed: Duration
    public let sleepAchieved: Duration
    public let consistencyPercentage: Int

    public init(
        performancePercentage: Int,
        sleepNeed: Duration,
        sleepAchieved: Duration,
        consistencyPercentage: Int
    ) {
        self.performancePercentage = performancePercentage
        self.sleepNeed = sleepNeed
        self.sleepAchieved = sleepAchieved
        self.consistencyPercentage = consistencyPercentage
    }
}

