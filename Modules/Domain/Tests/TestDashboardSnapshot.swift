import Foundation
import WhoopScopeDomain

enum TestDashboardSnapshot {
    static let value = DashboardSnapshot(
        date: .now,
        displayName: "Test Member",
        recovery: RecoverySummary(
            score: 82,
            heartRateVariabilityMilliseconds: 72,
            restingHeartRate: 51
        ),
        strain: StrainSummary(
            score: 8.4,
            kilocalories: 1_600,
            averageHeartRate: 75
        ),
        sleep: SleepSummary(
            performancePercentage: 88,
            sleepNeed: .seconds(28_800),
            sleepAchieved: .seconds(27_000),
            consistencyPercentage: 90
        ),
        history: [],
        recentWorkouts: [],
        lastSynchronizedAt: .now
    )
}

