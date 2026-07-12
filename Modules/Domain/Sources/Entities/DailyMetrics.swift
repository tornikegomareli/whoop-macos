import Foundation

public struct DailyMetrics: Identifiable, Equatable, Sendable {
    public let date: Date
    public let recoveryScore: Int
    public let strainScore: Double
    public let sleepPerformancePercentage: Int

    public var id: Date { date }

    public init(
        date: Date,
        recoveryScore: Int,
        strainScore: Double,
        sleepPerformancePercentage: Int
    ) {
        self.date = date
        self.recoveryScore = recoveryScore
        self.strainScore = strainScore
        self.sleepPerformancePercentage = sleepPerformancePercentage
    }
}

