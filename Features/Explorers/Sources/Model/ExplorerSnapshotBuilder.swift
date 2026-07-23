import Foundation
import WhoopScopeDomain

enum ExplorerSnapshotBuilder {
    static func build(
        from archive: WhoopDataArchive,
        range: TrendRange,
        now: Date,
        calendar: Calendar = .current
    ) throws -> ExplorerSnapshot {
        let today = calendar.startOfDay(for: now)
        guard
            let startDate = calendar.date(
                byAdding: .day,
                value: 1 - range.dayCount,
                to: today
            ),
            let endExclusive = calendar.date(byAdding: .day, value: 1, to: today)
        else {
            throw ExplorerSnapshotError.invalidDateRange
        }

        let sleeps = archive.sleeps
            .filter { $0.start >= startDate && $0.start < endExclusive }
            .sorted { $0.start < $1.start }
        let cycles = latestCyclesByDay(
            archive.cycles,
            startDate: startDate,
            endExclusive: endExclusive,
            calendar: calendar
        )
        let recoveryByCycle = archive.recoveries.reduce(
            into: [Int64: WhoopRecovery]()
        ) { result, recovery in
            if result[recovery.cycleID]?.updatedAt ?? .distantPast < recovery.updatedAt {
                result[recovery.cycleID] = recovery
            }
        }
        let recoveries = cycles.compactMap { cycle -> RecoveryRecord? in
            guard let recovery = recoveryByCycle[cycle.id] else { return nil }
            return RecoveryRecord(
                date: calendar.startOfDay(for: cycle.start),
                cycle: cycle,
                recovery: recovery
            )
        }
        let workouts = archive.workouts
            .filter { $0.start >= startDate && $0.start < endExclusive }
            .sorted { $0.start < $1.start }

        return ExplorerSnapshot(
            range: range,
            startDate: startDate,
            endDate: today,
            sleeps: sleeps,
            recoveries: recoveries,
            cycles: cycles,
            workouts: workouts,
            sleepSummary: sleepSummary(sleeps),
            recoverySummary: recoverySummary(recoveries),
            cycleSummary: cycleSummary(cycles),
            workoutSummary: workoutSummary(workouts),
            lastSynchronizedAt: archive.lastSynchronizedAt
        )
    }

    private static func latestCyclesByDay(
        _ cycles: [WhoopCycle],
        startDate: Date,
        endExclusive: Date,
        calendar: Calendar
    ) -> [WhoopCycle] {
        cycles.reduce(into: [Date: WhoopCycle]()) { result, cycle in
            let date = calendar.startOfDay(for: cycle.start)
            guard date >= startDate, date < endExclusive else { return }
            if result[date]?.updatedAt ?? .distantPast < cycle.updatedAt {
                result[date] = cycle
            }
        }
        .values
        .sorted { $0.start < $1.start }
    }

    private static func sleepSummary(_ sleeps: [WhoopSleep]) -> SleepExplorerSummary {
        let mainSleeps = sleeps.filter { !$0.isNap }
        let scored = mainSleeps.compactMap(\.score)
        let stageCount = Double(scored.count)
        let stageAverages: SleepStageAverages
        if stageCount > 0 {
            stageAverages = SleepStageAverages(
                awakeHours: hours(
                    scored.reduce(0) { $0 + $1.stageSummary.totalAwakeMilliseconds }
                ) / stageCount,
                lightHours: hours(
                    scored.reduce(0) { $0 + $1.stageSummary.totalLightSleepMilliseconds }
                ) / stageCount,
                slowWaveHours: hours(
                    scored.reduce(0) { $0 + $1.stageSummary.totalSlowWaveSleepMilliseconds }
                ) / stageCount,
                remHours: hours(
                    scored.reduce(0) { $0 + $1.stageSummary.totalREMSleepMilliseconds }
                ) / stageCount
            )
        } else {
            stageAverages = SleepStageAverages(
                awakeHours: 0,
                lightHours: 0,
                slowWaveHours: 0,
                remHours: 0
            )
        }

        return SleepExplorerSummary(
            mainSleepCount: mainSleeps.count,
            napCount: sleeps.filter(\.isNap).count,
            averageAchievedHours: average(
                scored.map { hours($0.stageSummary.achievedSleepMilliseconds) }
            ),
            averageNeededHours: average(
                scored.map { hours($0.sleepNeeded.totalMilliseconds) }
            ),
            averagePerformance: average(scored.compactMap(\.performancePercentage)),
            averageEfficiency: average(scored.compactMap(\.efficiencyPercentage)),
            averageConsistency: average(scored.compactMap(\.consistencyPercentage)),
            averageRespiratoryRate: average(scored.compactMap(\.respiratoryRate)),
            stageAverages: stageAverages
        )
    }

    private static func recoverySummary(
        _ recoveries: [RecoveryRecord]
    ) -> RecoveryExplorerSummary {
        let scores = recoveries.compactMap(\.recovery.score)
        let recoveryValues = scores.map(\.recoveryPercentage)
        return RecoveryExplorerSummary(
            scoredCount: scores.count,
            averageRecovery: average(recoveryValues),
            averageHRV: average(scores.map(\.hrvRMSSDMilliseconds)),
            averageRestingHeartRate: average(scores.map(\.restingHeartRate)),
            averageSpO2: average(scores.compactMap(\.spo2Percentage)),
            averageSkinTemperature: average(scores.compactMap(\.skinTemperatureCelsius)),
            greenCount: recoveryValues.count { $0 >= 67 },
            yellowCount: recoveryValues.count { $0 >= 34 && $0 < 67 },
            redCount: recoveryValues.count { $0 < 34 }
        )
    }

    private static func cycleSummary(_ cycles: [WhoopCycle]) -> CycleExplorerSummary {
        let scores = cycles.compactMap(\.score)
        return CycleExplorerSummary(
            scoredCount: scores.count,
            averageStrain: average(scores.map(\.strain)),
            peakStrain: scores.map(\.strain).max(),
            totalKilocalories: scores.reduce(0) { $0 + kilocalories($1.kilojoules) },
            averageHeartRate: average(scores.map { Double($0.averageHeartRate) })
        )
    }

    private static func workoutSummary(
        _ workouts: [WhoopWorkout]
    ) -> WorkoutExplorerSummary {
        let scores = workouts.compactMap(\.score)
        let grouped = Dictionary(grouping: workouts) {
            $0.sportName.localizedCapitalized
        }
        let sports = grouped.map { name, workouts in
            SportSummary(
                name: name,
                workoutCount: workouts.count,
                totalDuration: workouts.reduce(0) {
                    $0 + max(0, $1.end.timeIntervalSince($1.start))
                },
                totalStrain: workouts.compactMap(\.score?.strain).reduce(0, +)
            )
        }
        .sorted {
            if $0.workoutCount == $1.workoutCount {
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return $0.workoutCount > $1.workoutCount
        }

        return WorkoutExplorerSummary(
            scoredCount: scores.count,
            totalDuration: workouts.reduce(0) {
                $0 + max(0, $1.end.timeIntervalSince($1.start))
            },
            averageStrain: average(scores.map(\.strain)),
            totalKilocalories: scores.reduce(0) { $0 + kilocalories($1.kilojoules) },
            topSport: sports.first?.name,
            sports: sports
        )
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func hours(_ milliseconds: Int64) -> Double {
        Double(milliseconds) / 3_600_000
    }

    private static func kilocalories(_ kilojoules: Double) -> Double {
        kilojoules / 4.184
    }
}

enum ExplorerSnapshotError: Error {
    case invalidDateRange
}
