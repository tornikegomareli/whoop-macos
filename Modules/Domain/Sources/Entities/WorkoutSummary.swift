import Foundation

public struct WorkoutSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let activityName: String
    public let startedAt: Date
    public let duration: Duration
    public let strainScore: Double
    public let averageHeartRate: Int
    public let maximumHeartRate: Int
    public let kilocalories: Int

    public init(
        id: UUID,
        activityName: String,
        startedAt: Date,
        duration: Duration,
        strainScore: Double,
        averageHeartRate: Int,
        maximumHeartRate: Int,
        kilocalories: Int
    ) {
        self.id = id
        self.activityName = activityName
        self.startedAt = startedAt
        self.duration = duration
        self.strainScore = strainScore
        self.averageHeartRate = averageHeartRate
        self.maximumHeartRate = maximumHeartRate
        self.kilocalories = kilocalories
    }
}

