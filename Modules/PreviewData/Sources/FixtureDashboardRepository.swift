import Foundation
import WhoopScopeDomain

public struct FixtureDashboardRepository: DashboardRepository {
    public init() {}

    public func dashboard() async throws -> DashboardSnapshot {
        try await Task.sleep(for: .milliseconds(180))
        try Task.checkCancellation()
        return Self.snapshot
    }

    public static let snapshot: DashboardSnapshot = {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date.now
        let scores = [58, 71, 77, 64, 81, 69, 74, 86, 79, 67, 72, 88, 83, 84]
        let strain = [8.2, 12.6, 10.1, 15.8, 7.4, 11.9, 14.3, 9.7, 13.2, 16.1, 10.8, 12.4, 8.9, 6.8]
        let sleep = [72, 79, 84, 76, 91, 82, 80, 88, 86, 75, 81, 93, 89, 87]

        let history = scores.indices.compactMap { index -> DailyMetrics? in
            guard let date = calendar.date(
                byAdding: .day,
                value: index - scores.count + 1,
                to: now
            ) else {
                return nil
            }

            return DailyMetrics(
                date: date,
                recoveryScore: scores[index],
                strainScore: strain[index],
                sleepPerformancePercentage: sleep[index]
            )
        }

        let workouts = [
            WorkoutSummary(
                id: UUID(uuidString: "2AA852BB-6DF1-4AF2-A8D7-A5E22494956A") ?? UUID(),
                activityName: "Functional Fitness",
                startedAt: calendar.date(byAdding: .hour, value: -22, to: now) ?? now,
                duration: .seconds(3_180),
                strainScore: 11.6,
                averageHeartRate: 142,
                maximumHeartRate: 179,
                kilocalories: 486
            ),
            WorkoutSummary(
                id: UUID(uuidString: "84330056-6817-40B2-BAF6-EE06973719E2") ?? UUID(),
                activityName: "Running",
                startedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                duration: .seconds(2_640),
                strainScore: 13.8,
                averageHeartRate: 151,
                maximumHeartRate: 185,
                kilocalories: 574
            ),
            WorkoutSummary(
                id: UUID(uuidString: "F931A7EB-FC50-43A2-9F7E-23F0E2C4051F") ?? UUID(),
                activityName: "Strength Trainer",
                startedAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                duration: .seconds(4_020),
                strainScore: 10.2,
                averageHeartRate: 128,
                maximumHeartRate: 168,
                kilocalories: 421
            ),
        ]

        return DashboardSnapshot(
            date: now,
            displayName: "Taylor",
            recovery: RecoverySummary(
                score: 84,
                heartRateVariabilityMilliseconds: 78.4,
                restingHeartRate: 49
            ),
            strain: StrainSummary(
                score: 6.8,
                kilocalories: 1_842,
                averageHeartRate: 72
            ),
            sleep: SleepSummary(
                performancePercentage: 87,
                sleepNeed: .seconds(29_700),
                sleepAchieved: .seconds(27_720),
                consistencyPercentage: 91
            ),
            history: history,
            recentWorkouts: workouts,
            lastSynchronizedAt: calendar.date(byAdding: .minute, value: -4, to: now) ?? now
        )
    }()
}

