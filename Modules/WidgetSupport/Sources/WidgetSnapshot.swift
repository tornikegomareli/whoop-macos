import Foundation

public struct WidgetSnapshot: Codable, Equatable, Sendable {
    public let recoveryScore: Int
    public let strainScore: Double
    public let sleepPerformancePercentage: Int
    public let heartRateVariabilityMilliseconds: Double
    public let restingHeartRate: Int
    public let sleepAchievedSeconds: Int64
    public let synchronizedAt: Date

    public init(
        recoveryScore: Int,
        strainScore: Double,
        sleepPerformancePercentage: Int,
        heartRateVariabilityMilliseconds: Double,
        restingHeartRate: Int,
        sleepAchievedSeconds: Int64,
        synchronizedAt: Date
    ) {
        self.recoveryScore = recoveryScore
        self.strainScore = strainScore
        self.sleepPerformancePercentage = sleepPerformancePercentage
        self.heartRateVariabilityMilliseconds = heartRateVariabilityMilliseconds
        self.restingHeartRate = restingHeartRate
        self.sleepAchievedSeconds = sleepAchievedSeconds
        self.synchronizedAt = synchronizedAt
    }
}

public extension WidgetSnapshot {
    static let preview = WidgetSnapshot(
        recoveryScore: 84,
        strainScore: 6.8,
        sleepPerformancePercentage: 87,
        heartRateVariabilityMilliseconds: 78.4,
        restingHeartRate: 49,
        sleepAchievedSeconds: 7 * 60 * 60 + 42 * 60,
        synchronizedAt: .now
    )
}
