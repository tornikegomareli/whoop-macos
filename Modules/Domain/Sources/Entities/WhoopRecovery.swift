import Foundation

public struct WhoopRecovery: Codable, Identifiable, Equatable, Sendable {
    public var id: Int64 { cycleID }

    public let cycleID: Int64
    public let sleepID: UUID
    public let userID: Int64
    public let createdAt: Date
    public let updatedAt: Date
    public let scoreState: WhoopScoreState
    public let score: Score?

    public struct Score: Codable, Equatable, Sendable {
        public let isUserCalibrating: Bool
        public let recoveryPercentage: Double
        public let restingHeartRate: Double
        public let hrvRMSSDMilliseconds: Double
        public let spo2Percentage: Double?
        public let skinTemperatureCelsius: Double?

        public init(
            isUserCalibrating: Bool,
            recoveryPercentage: Double,
            restingHeartRate: Double,
            hrvRMSSDMilliseconds: Double,
            spo2Percentage: Double?,
            skinTemperatureCelsius: Double?
        ) {
            self.isUserCalibrating = isUserCalibrating
            self.recoveryPercentage = recoveryPercentage
            self.restingHeartRate = restingHeartRate
            self.hrvRMSSDMilliseconds = hrvRMSSDMilliseconds
            self.spo2Percentage = spo2Percentage
            self.skinTemperatureCelsius = skinTemperatureCelsius
        }
    }

    public init(
        cycleID: Int64,
        sleepID: UUID,
        userID: Int64,
        createdAt: Date,
        updatedAt: Date,
        scoreState: WhoopScoreState,
        score: Score?
    ) {
        self.cycleID = cycleID
        self.sleepID = sleepID
        self.userID = userID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.scoreState = scoreState
        self.score = score
    }
}
