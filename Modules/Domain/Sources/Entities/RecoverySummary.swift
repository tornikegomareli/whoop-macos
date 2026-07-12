import Foundation

public struct RecoverySummary: Equatable, Sendable {
    public let score: Int
    public let heartRateVariabilityMilliseconds: Double
    public let restingHeartRate: Int

    public init(
        score: Int,
        heartRateVariabilityMilliseconds: Double,
        restingHeartRate: Int
    ) {
        self.score = score
        self.heartRateVariabilityMilliseconds = heartRateVariabilityMilliseconds
        self.restingHeartRate = restingHeartRate
    }
}

