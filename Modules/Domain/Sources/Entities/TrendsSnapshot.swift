import Foundation

public struct TrendsSnapshot: Equatable, Sendable {
    public let range: TrendRange
    public let startDate: Date
    public let endDate: Date
    public let days: [TrendDay]
    public let recovery: TrendMetricSummary
    public let strain: TrendMetricSummary
    public let sleepPerformance: TrendMetricSummary
    public let heartRateVariability: TrendMetricSummary
    public let restingHeartRate: TrendMetricSummary
    public let lastSynchronizedAt: Date

    public init(
        range: TrendRange,
        startDate: Date,
        endDate: Date,
        days: [TrendDay],
        recovery: TrendMetricSummary,
        strain: TrendMetricSummary,
        sleepPerformance: TrendMetricSummary,
        heartRateVariability: TrendMetricSummary,
        restingHeartRate: TrendMetricSummary,
        lastSynchronizedAt: Date
    ) {
        self.range = range
        self.startDate = startDate
        self.endDate = endDate
        self.days = days
        self.recovery = recovery
        self.strain = strain
        self.sleepPerformance = sleepPerformance
        self.heartRateVariability = heartRateVariability
        self.restingHeartRate = restingHeartRate
        self.lastSynchronizedAt = lastSynchronizedAt
    }
}
