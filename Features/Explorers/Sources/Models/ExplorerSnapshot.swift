import Foundation
import WhoopScopeDomain

public struct ExplorerSnapshot: Equatable, Sendable {
    public let range: TrendRange
    public let startDate: Date
    public let endDate: Date
    public let sleeps: [WhoopSleep]
    public let recoveries: [RecoveryRecord]
    public let cycles: [WhoopCycle]
    public let workouts: [WhoopWorkout]
    public let sleepSummary: SleepExplorerSummary
    public let recoverySummary: RecoveryExplorerSummary
    public let cycleSummary: CycleExplorerSummary
    public let workoutSummary: WorkoutExplorerSummary
    public let lastSynchronizedAt: Date
}

public struct RecoveryRecord: Identifiable, Equatable, Sendable {
    public var id: Int64 { recovery.cycleID }

    public let date: Date
    public let cycle: WhoopCycle
    public let recovery: WhoopRecovery
}

public struct SleepExplorerSummary: Equatable, Sendable {
    public let mainSleepCount: Int
    public let napCount: Int
    public let averageAchievedHours: Double?
    public let averageNeededHours: Double?
    public let averagePerformance: Double?
    public let averageEfficiency: Double?
    public let averageConsistency: Double?
    public let averageRespiratoryRate: Double?
    public let stageAverages: SleepStageAverages
}

public struct SleepStageAverages: Equatable, Sendable {
    public let awakeHours: Double
    public let lightHours: Double
    public let slowWaveHours: Double
    public let remHours: Double
}

public struct RecoveryExplorerSummary: Equatable, Sendable {
    public let scoredCount: Int
    public let averageRecovery: Double?
    public let averageHRV: Double?
    public let averageRestingHeartRate: Double?
    public let averageSpO2: Double?
    public let averageSkinTemperature: Double?
    public let greenCount: Int
    public let yellowCount: Int
    public let redCount: Int
}

public struct CycleExplorerSummary: Equatable, Sendable {
    public let scoredCount: Int
    public let averageStrain: Double?
    public let peakStrain: Double?
    public let totalKilocalories: Double
    public let averageHeartRate: Double?
}

public struct WorkoutExplorerSummary: Equatable, Sendable {
    public let scoredCount: Int
    public let totalDuration: TimeInterval
    public let averageStrain: Double?
    public let totalKilocalories: Double
    public let topSport: String?
    public let sports: [SportSummary]
}

public struct SportSummary: Identifiable, Equatable, Sendable {
    public var id: String { name }

    public let name: String
    public let workoutCount: Int
    public let totalDuration: TimeInterval
    public let totalStrain: Double
}
