import Foundation

public struct WhoopSleep: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let cycleID: Int64
    public let legacyV1ID: Int64?
    public let userID: Int64
    public let createdAt: Date
    public let updatedAt: Date
    public let start: Date
    public let end: Date
    public let timezoneOffset: String
    public let isNap: Bool
    public let scoreState: WhoopScoreState
    public let score: Score?

    public struct Score: Codable, Equatable, Sendable {
        public let stageSummary: StageSummary
        public let sleepNeeded: SleepNeeded
        public let respiratoryRate: Double?
        public let performancePercentage: Double?
        public let consistencyPercentage: Double?
        public let efficiencyPercentage: Double?

        public init(
            stageSummary: StageSummary,
            sleepNeeded: SleepNeeded,
            respiratoryRate: Double?,
            performancePercentage: Double?,
            consistencyPercentage: Double?,
            efficiencyPercentage: Double?
        ) {
            self.stageSummary = stageSummary
            self.sleepNeeded = sleepNeeded
            self.respiratoryRate = respiratoryRate
            self.performancePercentage = performancePercentage
            self.consistencyPercentage = consistencyPercentage
            self.efficiencyPercentage = efficiencyPercentage
        }
    }

    public struct StageSummary: Codable, Equatable, Sendable {
        public let totalInBedMilliseconds: Int64
        public let totalAwakeMilliseconds: Int64
        public let totalNoDataMilliseconds: Int64
        public let totalLightSleepMilliseconds: Int64
        public let totalSlowWaveSleepMilliseconds: Int64
        public let totalREMSleepMilliseconds: Int64
        public let sleepCycleCount: Int
        public let disturbanceCount: Int

        public init(
            totalInBedMilliseconds: Int64,
            totalAwakeMilliseconds: Int64,
            totalNoDataMilliseconds: Int64,
            totalLightSleepMilliseconds: Int64,
            totalSlowWaveSleepMilliseconds: Int64,
            totalREMSleepMilliseconds: Int64,
            sleepCycleCount: Int,
            disturbanceCount: Int
        ) {
            self.totalInBedMilliseconds = totalInBedMilliseconds
            self.totalAwakeMilliseconds = totalAwakeMilliseconds
            self.totalNoDataMilliseconds = totalNoDataMilliseconds
            self.totalLightSleepMilliseconds = totalLightSleepMilliseconds
            self.totalSlowWaveSleepMilliseconds = totalSlowWaveSleepMilliseconds
            self.totalREMSleepMilliseconds = totalREMSleepMilliseconds
            self.sleepCycleCount = sleepCycleCount
            self.disturbanceCount = disturbanceCount
        }

        public var achievedSleepMilliseconds: Int64 {
            totalLightSleepMilliseconds
                + totalSlowWaveSleepMilliseconds
                + totalREMSleepMilliseconds
        }
    }

    public struct SleepNeeded: Codable, Equatable, Sendable {
        public let baselineMilliseconds: Int64
        public let fromSleepDebtMilliseconds: Int64
        public let fromRecentStrainMilliseconds: Int64
        public let fromRecentNapMilliseconds: Int64

        public init(
            baselineMilliseconds: Int64,
            fromSleepDebtMilliseconds: Int64,
            fromRecentStrainMilliseconds: Int64,
            fromRecentNapMilliseconds: Int64
        ) {
            self.baselineMilliseconds = baselineMilliseconds
            self.fromSleepDebtMilliseconds = fromSleepDebtMilliseconds
            self.fromRecentStrainMilliseconds = fromRecentStrainMilliseconds
            self.fromRecentNapMilliseconds = fromRecentNapMilliseconds
        }

        public var totalMilliseconds: Int64 {
            baselineMilliseconds
                + fromSleepDebtMilliseconds
                + fromRecentStrainMilliseconds
                + fromRecentNapMilliseconds
        }
    }

    public init(
        id: UUID,
        cycleID: Int64,
        legacyV1ID: Int64?,
        userID: Int64,
        createdAt: Date,
        updatedAt: Date,
        start: Date,
        end: Date,
        timezoneOffset: String,
        isNap: Bool,
        scoreState: WhoopScoreState,
        score: Score?
    ) {
        self.id = id
        self.cycleID = cycleID
        self.legacyV1ID = legacyV1ID
        self.userID = userID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.start = start
        self.end = end
        self.timezoneOffset = timezoneOffset
        self.isNap = isNap
        self.scoreState = scoreState
        self.score = score
    }
}
