import Foundation

public struct StrainSummary: Equatable, Sendable {
    public let score: Double
    public let kilocalories: Int
    public let averageHeartRate: Int

    public init(score: Double, kilocalories: Int, averageHeartRate: Int) {
        self.score = score
        self.kilocalories = kilocalories
        self.averageHeartRate = averageHeartRate
    }
}

