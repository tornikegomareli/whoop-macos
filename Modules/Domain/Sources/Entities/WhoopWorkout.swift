import Foundation

public struct WhoopWorkout: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let legacyV1ID: Int64?
    public let userID: Int64
    public let createdAt: Date
    public let updatedAt: Date
    public let start: Date
    public let end: Date
    public let timezoneOffset: String
    public let sportName: String
    public let sportID: Int?
    public let scoreState: WhoopScoreState
    public let score: Score?

    public struct Score: Codable, Equatable, Sendable {
        public let strain: Double
        public let averageHeartRate: Int
        public let maxHeartRate: Int
        public let kilojoules: Double
        public let percentRecorded: Double
        public let distanceMeters: Double?
        public let altitudeGainMeters: Double?
        public let altitudeChangeMeters: Double?
        public let zoneDurations: ZoneDurations

        public init(
            strain: Double,
            averageHeartRate: Int,
            maxHeartRate: Int,
            kilojoules: Double,
            percentRecorded: Double,
            distanceMeters: Double?,
            altitudeGainMeters: Double?,
            altitudeChangeMeters: Double?,
            zoneDurations: ZoneDurations
        ) {
            self.strain = strain
            self.averageHeartRate = averageHeartRate
            self.maxHeartRate = maxHeartRate
            self.kilojoules = kilojoules
            self.percentRecorded = percentRecorded
            self.distanceMeters = distanceMeters
            self.altitudeGainMeters = altitudeGainMeters
            self.altitudeChangeMeters = altitudeChangeMeters
            self.zoneDurations = zoneDurations
        }
    }

    public struct ZoneDurations: Codable, Equatable, Sendable {
        public let zoneZeroMilliseconds: Int64
        public let zoneOneMilliseconds: Int64
        public let zoneTwoMilliseconds: Int64
        public let zoneThreeMilliseconds: Int64
        public let zoneFourMilliseconds: Int64
        public let zoneFiveMilliseconds: Int64

        public init(
            zoneZeroMilliseconds: Int64,
            zoneOneMilliseconds: Int64,
            zoneTwoMilliseconds: Int64,
            zoneThreeMilliseconds: Int64,
            zoneFourMilliseconds: Int64,
            zoneFiveMilliseconds: Int64
        ) {
            self.zoneZeroMilliseconds = zoneZeroMilliseconds
            self.zoneOneMilliseconds = zoneOneMilliseconds
            self.zoneTwoMilliseconds = zoneTwoMilliseconds
            self.zoneThreeMilliseconds = zoneThreeMilliseconds
            self.zoneFourMilliseconds = zoneFourMilliseconds
            self.zoneFiveMilliseconds = zoneFiveMilliseconds
        }
    }

    public init(
        id: UUID,
        legacyV1ID: Int64?,
        userID: Int64,
        createdAt: Date,
        updatedAt: Date,
        start: Date,
        end: Date,
        timezoneOffset: String,
        sportName: String,
        sportID: Int?,
        scoreState: WhoopScoreState,
        score: Score?
    ) {
        self.id = id
        self.legacyV1ID = legacyV1ID
        self.userID = userID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.start = start
        self.end = end
        self.timezoneOffset = timezoneOffset
        self.sportName = sportName
        self.sportID = sportID
        self.scoreState = scoreState
        self.score = score
    }
}
