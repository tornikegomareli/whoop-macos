import Foundation
import WhoopScopeDomain

public struct FixtureDashboardRepository: DashboardRepository {
    private let now: Date
    private let calendar: Calendar

    public init(now: Date = .now, calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
    }

    public func dashboard() async throws -> DashboardSnapshot {
        try await Task.sleep(for: .milliseconds(180))
        try Task.checkCancellation()
        return Self.makeSnapshot(now: now, calendar: calendar)
    }

    public static var snapshot: DashboardSnapshot {
        makeSnapshot(now: .now, calendar: .current)
    }

    private static func makeSnapshot(now: Date, calendar: Calendar) -> DashboardSnapshot {
        let archive = FixtureWhoopData.archive(now: now, calendar: calendar)
        let mainSleepByCycle = archive.sleeps
            .filter { !$0.isNap }
            .reduce(into: [Int64: WhoopSleep]()) { $0[$1.cycleID] = $1 }
        let recoveryByCycle = Dictionary(
            uniqueKeysWithValues: archive.recoveries.map { ($0.cycleID, $0) }
        )
        let latestCycle = archive.cycles.last
        let latestRecovery = latestCycle.flatMap { recoveryByCycle[$0.id] }
        let latestSleep = latestCycle.flatMap { mainSleepByCycle[$0.id] }
        let history = archive.cycles.suffix(14).compactMap { cycle -> DailyMetrics? in
            guard
                let recovery = recoveryByCycle[cycle.id]?.score,
                let sleep = mainSleepByCycle[cycle.id]?.score,
                let strain = cycle.score?.strain
            else { return nil }
            return DailyMetrics(
                date: calendar.startOfDay(for: cycle.start),
                recoveryScore: Int(recovery.recoveryPercentage),
                strainScore: strain,
                sleepPerformancePercentage: Int(sleep.performancePercentage ?? 0)
            )
        }
        let workouts: [WorkoutSummary] = archive.workouts
            .suffix(3)
            .reversed()
            .compactMap { workout -> WorkoutSummary? in
            guard let score = workout.score else { return nil }
            return WorkoutSummary(
                id: workout.id,
                activityName: workout.sportName,
                startedAt: workout.start,
                duration: .seconds(workout.end.timeIntervalSince(workout.start)),
                strainScore: score.strain,
                averageHeartRate: score.averageHeartRate,
                maximumHeartRate: score.maxHeartRate,
                kilocalories: Int(score.kilojoules / 4.184)
            )
        }
        let sleepScore = latestSleep?.score
        let recoveryScore = latestRecovery?.score

        return DashboardSnapshot(
            date: now,
            displayName: archive.account.profile.firstName,
            recovery: RecoverySummary(
                score: Int(recoveryScore?.recoveryPercentage ?? 0),
                heartRateVariabilityMilliseconds: recoveryScore?.hrvRMSSDMilliseconds ?? 0,
                restingHeartRate: Int(recoveryScore?.restingHeartRate ?? 0)
            ),
            strain: StrainSummary(
                score: latestCycle?.score?.strain ?? 0,
                kilocalories: Int((latestCycle?.score?.kilojoules ?? 0) / 4.184),
                averageHeartRate: latestCycle?.score?.averageHeartRate ?? 0
            ),
            sleep: SleepSummary(
                performancePercentage: Int(sleepScore?.performancePercentage ?? 0),
                sleepNeed: .milliseconds(
                    Int(sleepScore?.sleepNeeded.totalMilliseconds ?? 0)
                ),
                sleepAchieved: .milliseconds(
                    Int(sleepScore?.stageSummary.achievedSleepMilliseconds ?? 0)
                ),
                consistencyPercentage: Int(sleepScore?.consistencyPercentage ?? 0)
            ),
            history: Array(history),
            recentWorkouts: workouts,
            lastSynchronizedAt: archive.lastSynchronizedAt
        )
    }
}
