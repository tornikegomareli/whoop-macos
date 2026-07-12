import Foundation
import WhoopScopeDomain

struct WhoopPage<Record: Decodable & Sendable>: Decodable, Sendable {
    let records: [Record]
    let nextToken: String?

    enum CodingKeys: String, CodingKey {
        case records
        case nextToken
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        records = try container.decodeIfPresent([Record].self, forKey: .records) ?? []
        nextToken = try container.decodeIfPresent(String.self, forKey: .nextToken)
    }
}

struct WhoopCycleDTO: Decodable, Sendable {
    let id: Int64
    let userId: Int64
    let createdAt: Date
    let updatedAt: Date
    let start: Date
    let end: Date?
    let timezoneOffset: String
    let scoreState: String
    let score: Score?

    struct Score: Decodable, Sendable {
        let strain: Double
        let kilojoule: Double
        let averageHeartRate: Int
        let maxHeartRate: Int
    }

    var domainValue: WhoopCycle {
        get throws {
            WhoopCycle(
                id: id,
                userID: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                start: start,
                end: end,
                timezoneOffset: timezoneOffset,
                scoreState: try whoopScoreState(scoreState),
                score: score.map {
                    WhoopCycle.Score(
                        strain: $0.strain,
                        kilojoules: $0.kilojoule,
                        averageHeartRate: $0.averageHeartRate,
                        maxHeartRate: $0.maxHeartRate
                    )
                }
            )
        }
    }
}

struct WhoopRecoveryDTO: Decodable, Sendable {
    let cycleId: Int64
    let sleepId: UUID
    let userId: Int64
    let createdAt: Date
    let updatedAt: Date
    let scoreState: String
    let score: Score?

    struct Score: Decodable, Sendable {
        let userCalibrating: Bool
        let recoveryScore: Double
        let restingHeartRate: Double
        let hrvRmssdMilli: Double
        let spo2Percentage: Double?
        let skinTempCelsius: Double?
    }

    var domainValue: WhoopRecovery {
        get throws {
            WhoopRecovery(
                cycleID: cycleId,
                sleepID: sleepId,
                userID: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                scoreState: try whoopScoreState(scoreState),
                score: score.map {
                    WhoopRecovery.Score(
                        isUserCalibrating: $0.userCalibrating,
                        recoveryPercentage: $0.recoveryScore,
                        restingHeartRate: $0.restingHeartRate,
                        hrvRMSSDMilliseconds: $0.hrvRmssdMilli,
                        spo2Percentage: $0.spo2Percentage,
                        skinTemperatureCelsius: $0.skinTempCelsius
                    )
                }
            )
        }
    }
}

struct WhoopSleepDTO: Decodable, Sendable {
    let id: UUID
    let cycleId: Int64
    let v1Id: Int64?
    let userId: Int64
    let createdAt: Date
    let updatedAt: Date
    let start: Date
    let end: Date
    let timezoneOffset: String
    let nap: Bool
    let scoreState: String
    let score: Score?

    struct Score: Decodable, Sendable {
        let stageSummary: StageSummary
        let sleepNeeded: SleepNeeded
        let respiratoryRate: Double?
        let sleepPerformancePercentage: Double?
        let sleepConsistencyPercentage: Double?
        let sleepEfficiencyPercentage: Double?
    }

    struct StageSummary: Decodable, Sendable {
        let totalInBedTimeMilli: Int64
        let totalAwakeTimeMilli: Int64
        let totalNoDataTimeMilli: Int64
        let totalLightSleepTimeMilli: Int64
        let totalSlowWaveSleepTimeMilli: Int64
        let totalRemSleepTimeMilli: Int64
        let sleepCycleCount: Int
        let disturbanceCount: Int
    }

    struct SleepNeeded: Decodable, Sendable {
        let baselineMilli: Int64
        let needFromSleepDebtMilli: Int64
        let needFromRecentStrainMilli: Int64
        let needFromRecentNapMilli: Int64
    }

    var domainValue: WhoopSleep {
        get throws {
            WhoopSleep(
                id: id,
                cycleID: cycleId,
                legacyV1ID: v1Id,
                userID: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                start: start,
                end: end,
                timezoneOffset: timezoneOffset,
                isNap: nap,
                scoreState: try whoopScoreState(scoreState),
                score: score.map {
                    WhoopSleep.Score(
                        stageSummary: WhoopSleep.StageSummary(
                            totalInBedMilliseconds: $0.stageSummary.totalInBedTimeMilli,
                            totalAwakeMilliseconds: $0.stageSummary.totalAwakeTimeMilli,
                            totalNoDataMilliseconds: $0.stageSummary.totalNoDataTimeMilli,
                            totalLightSleepMilliseconds: $0.stageSummary.totalLightSleepTimeMilli,
                            totalSlowWaveSleepMilliseconds: $0.stageSummary.totalSlowWaveSleepTimeMilli,
                            totalREMSleepMilliseconds: $0.stageSummary.totalRemSleepTimeMilli,
                            sleepCycleCount: $0.stageSummary.sleepCycleCount,
                            disturbanceCount: $0.stageSummary.disturbanceCount
                        ),
                        sleepNeeded: WhoopSleep.SleepNeeded(
                            baselineMilliseconds: $0.sleepNeeded.baselineMilli,
                            fromSleepDebtMilliseconds: $0.sleepNeeded.needFromSleepDebtMilli,
                            fromRecentStrainMilliseconds: $0.sleepNeeded.needFromRecentStrainMilli,
                            fromRecentNapMilliseconds: $0.sleepNeeded.needFromRecentNapMilli
                        ),
                        respiratoryRate: $0.respiratoryRate,
                        performancePercentage: $0.sleepPerformancePercentage,
                        consistencyPercentage: $0.sleepConsistencyPercentage,
                        efficiencyPercentage: $0.sleepEfficiencyPercentage
                    )
                }
            )
        }
    }
}

struct WhoopWorkoutDTO: Decodable, Sendable {
    let id: UUID
    let v1Id: Int64?
    let userId: Int64
    let createdAt: Date
    let updatedAt: Date
    let start: Date
    let end: Date
    let timezoneOffset: String
    let sportName: String
    let scoreState: String
    let score: Score?
    let sportId: Int?

    struct Score: Decodable, Sendable {
        let strain: Double
        let averageHeartRate: Int
        let maxHeartRate: Int
        let kilojoule: Double
        let percentRecorded: Double
        let distanceMeter: Double?
        let altitudeGainMeter: Double?
        let altitudeChangeMeter: Double?
        let zoneDurations: ZoneDurations
    }

    struct ZoneDurations: Decodable, Sendable {
        let zoneZeroMilli: Int64
        let zoneOneMilli: Int64
        let zoneTwoMilli: Int64
        let zoneThreeMilli: Int64
        let zoneFourMilli: Int64
        let zoneFiveMilli: Int64
    }

    var domainValue: WhoopWorkout {
        get throws {
            WhoopWorkout(
                id: id,
                legacyV1ID: v1Id,
                userID: userId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                start: start,
                end: end,
                timezoneOffset: timezoneOffset,
                sportName: sportName,
                sportID: sportId,
                scoreState: try whoopScoreState(scoreState),
                score: score.map {
                    WhoopWorkout.Score(
                        strain: $0.strain,
                        averageHeartRate: $0.averageHeartRate,
                        maxHeartRate: $0.maxHeartRate,
                        kilojoules: $0.kilojoule,
                        percentRecorded: $0.percentRecorded,
                        distanceMeters: $0.distanceMeter,
                        altitudeGainMeters: $0.altitudeGainMeter,
                        altitudeChangeMeters: $0.altitudeChangeMeter,
                        zoneDurations: WhoopWorkout.ZoneDurations(
                            zoneZeroMilliseconds: $0.zoneDurations.zoneZeroMilli,
                            zoneOneMilliseconds: $0.zoneDurations.zoneOneMilli,
                            zoneTwoMilliseconds: $0.zoneDurations.zoneTwoMilli,
                            zoneThreeMilliseconds: $0.zoneDurations.zoneThreeMilli,
                            zoneFourMilliseconds: $0.zoneDurations.zoneFourMilli,
                            zoneFiveMilliseconds: $0.zoneDurations.zoneFiveMilli
                        )
                    )
                }
            )
        }
    }
}

private func whoopScoreState(_ rawValue: String) throws -> WhoopScoreState {
    guard let state = WhoopScoreState(rawValue: rawValue) else {
        throw WhoopAPIError.invalidResponse
    }
    return state
}
