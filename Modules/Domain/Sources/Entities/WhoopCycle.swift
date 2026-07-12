import Foundation

public struct WhoopCycle: Codable, Identifiable, Equatable, Sendable {
    public let id: Int64
    public let userID: Int64
    public let createdAt: Date
    public let updatedAt: Date
    public let start: Date
    public let end: Date?
    public let timezoneOffset: String
    public let scoreState: WhoopScoreState
    public let score: Score?

    public struct Score: Codable, Equatable, Sendable {
        public let strain: Double
        public let kilojoules: Double
        public let averageHeartRate: Int
        public let maxHeartRate: Int

        public init(
            strain: Double,
            kilojoules: Double,
            averageHeartRate: Int,
            maxHeartRate: Int
        ) {
            self.strain = strain
            self.kilojoules = kilojoules
            self.averageHeartRate = averageHeartRate
            self.maxHeartRate = maxHeartRate
        }
    }

    public init(
        id: Int64,
        userID: Int64,
        createdAt: Date,
        updatedAt: Date,
        start: Date,
        end: Date?,
        timezoneOffset: String,
        scoreState: WhoopScoreState,
        score: Score?
    ) {
        self.id = id
        self.userID = userID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.start = start
        self.end = end
        self.timezoneOffset = timezoneOffset
        self.scoreState = scoreState
        self.score = score
    }
}
