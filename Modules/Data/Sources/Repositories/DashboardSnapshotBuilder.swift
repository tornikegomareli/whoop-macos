import Foundation
import WhoopScopeDomain

enum DashboardSnapshotBuilder {
    static func build(
        from archive: WhoopDataArchive,
        now: Date
    ) throws -> DashboardSnapshot {
        let recoveriesByCycle = Dictionary(
            uniqueKeysWithValues: archive.recoveries.map { ($0.cycleID, $0) }
        )
        let sleepsByID = Dictionary(
            uniqueKeysWithValues: archive.sleeps.map { ($0.id, $0) }
        )
        let mainSleepsByCycle = archive.sleeps
            .filter { !$0.isNap }
            .reduce(into: [Int64: WhoopSleep]()) { result, sleep in
                if result[sleep.cycleID]?.updatedAt ?? .distantPast < sleep.updatedAt {
                    result[sleep.cycleID] = sleep
                }
            }

        let completeCycles = archive.cycles
            .sorted { $0.start > $1.start }
            .compactMap { cycle -> CompleteDay? in
                guard
                    let cycleScore = cycle.score,
                    let recovery = recoveriesByCycle[cycle.id],
                    let recoveryScore = recovery.score,
                    let sleep = sleepsByID[recovery.sleepID] ?? mainSleepsByCycle[cycle.id],
                    let sleepScore = sleep.score
                else { return nil }
                return CompleteDay(
                    cycle: cycle,
                    cycleScore: cycleScore,
                    recoveryScore: recoveryScore,
                    sleepScore: sleepScore
                )
            }

        guard let latest = completeCycles.first else {
            throw WhoopAPIError.invalidResponse
        }

        let history = completeCycles.prefix(14).reversed().map { day in
            DailyMetrics(
                date: day.cycle.start,
                recoveryScore: Int(day.recoveryScore.recoveryPercentage.rounded()),
                strainScore: day.cycleScore.strain,
                sleepPerformancePercentage: Int(
                    (day.sleepScore.performancePercentage ?? 0).rounded()
                )
            )
        }
        let sleepNeedMilliseconds = max(0, latest.sleepScore.sleepNeeded.totalMilliseconds)
        let achievedMilliseconds = max(
            0,
            latest.sleepScore.stageSummary.achievedSleepMilliseconds
        )
        let recentWorkoutThreshold = now.addingTimeInterval(-7 * 24 * 60 * 60)
        let recentWorkouts = Array(archive.workouts
            .filter { $0.start >= recentWorkoutThreshold && $0.score != nil }
            .sorted { $0.start > $1.start }
            .prefix(3)
            .compactMap { workout -> WorkoutSummary? in
                guard let score = workout.score else { return nil }
                return WorkoutSummary(
                    id: workout.id,
                    activityName: workout.sportName.localizedCapitalized,
                    startedAt: workout.start,
                    duration: .seconds(max(0, workout.end.timeIntervalSince(workout.start))),
                    strainScore: score.strain,
                    averageHeartRate: score.averageHeartRate,
                    maximumHeartRate: score.maxHeartRate,
                    kilocalories: Int((score.kilojoules / 4.184).rounded())
                )
            })

        return DashboardSnapshot(
            date: now,
            displayName: archive.account.profile.firstName,
            recovery: RecoverySummary(
                score: Int(latest.recoveryScore.recoveryPercentage.rounded()),
                heartRateVariabilityMilliseconds: latest.recoveryScore.hrvRMSSDMilliseconds,
                restingHeartRate: Int(latest.recoveryScore.restingHeartRate.rounded())
            ),
            strain: StrainSummary(
                score: latest.cycleScore.strain,
                kilocalories: Int((latest.cycleScore.kilojoules / 4.184).rounded()),
                averageHeartRate: latest.cycleScore.averageHeartRate
            ),
            sleep: SleepSummary(
                performancePercentage: Int(
                    (latest.sleepScore.performancePercentage ?? 0).rounded()
                ),
                sleepNeed: .milliseconds(sleepNeedMilliseconds),
                sleepAchieved: .milliseconds(achievedMilliseconds),
                consistencyPercentage: Int(
                    (latest.sleepScore.consistencyPercentage ?? 0).rounded()
                )
            ),
            history: Array(history),
            recentWorkouts: recentWorkouts,
            lastSynchronizedAt: archive.lastSynchronizedAt
        )
    }

    private struct CompleteDay {
        let cycle: WhoopCycle
        let cycleScore: WhoopCycle.Score
        let recoveryScore: WhoopRecovery.Score
        let sleepScore: WhoopSleep.Score
    }
}
