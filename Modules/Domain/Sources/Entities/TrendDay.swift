import Foundation

public struct TrendDay: Identifiable, Equatable, Sendable {
    public var id: Date { date }

    public let date: Date
    public let recoveryScore: Double?
    public let strainScore: Double?
    public let sleepPerformancePercentage: Double?
    public let heartRateVariabilityMilliseconds: Double?
    public let restingHeartRate: Double?

    public init(
        date: Date,
        recoveryScore: Double?,
        strainScore: Double?,
        sleepPerformancePercentage: Double?,
        heartRateVariabilityMilliseconds: Double?,
        restingHeartRate: Double?
    ) {
        self.date = date
        self.recoveryScore = recoveryScore
        self.strainScore = strainScore
        self.sleepPerformancePercentage = sleepPerformancePercentage
        self.heartRateVariabilityMilliseconds = heartRateVariabilityMilliseconds
        self.restingHeartRate = restingHeartRate
    }
}
