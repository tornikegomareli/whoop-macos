import Foundation
import WhoopScopeDomain

enum TrendsSnapshotBuilder {
    static func build(
        from archive: WhoopDataArchive,
        range: TrendRange,
        now: Date,
        calendar: Calendar = .current
    ) throws -> TrendsSnapshot {
        let today = calendar.startOfDay(for: now)
        guard
            let startDate = calendar.date(
                byAdding: .day,
                value: 1 - range.dayCount,
                to: today
            ),
            let endExclusive = calendar.date(byAdding: .day, value: 1, to: today),
            let previousStart = calendar.date(
                byAdding: .day,
                value: -range.dayCount,
                to: startDate
            )
        else {
            throw WhoopAPIError.invalidResponse
        }

        let allDays = makeDays(
            from: archive,
            startingAt: previousStart,
            endingBefore: endExclusive,
            calendar: calendar
        )
        let currentDays = allDays.filter { $0.date >= startDate }
        let previousDays = allDays.filter { $0.date < startDate }

        return TrendsSnapshot(
            range: range,
            startDate: startDate,
            endDate: today,
            days: currentDays,
            recovery: summary(
                current: currentDays,
                previous: previousDays,
                value: \TrendDay.recoveryScore
            ),
            strain: summary(
                current: currentDays,
                previous: previousDays,
                value: \TrendDay.strainScore
            ),
            sleepPerformance: summary(
                current: currentDays,
                previous: previousDays,
                value: \TrendDay.sleepPerformancePercentage
            ),
            heartRateVariability: summary(
                current: currentDays,
                previous: previousDays,
                value: \TrendDay.heartRateVariabilityMilliseconds
            ),
            restingHeartRate: summary(
                current: currentDays,
                previous: previousDays,
                value: \TrendDay.restingHeartRate
            ),
            lastSynchronizedAt: archive.lastSynchronizedAt
        )
    }

    private static func makeDays(
        from archive: WhoopDataArchive,
        startingAt start: Date,
        endingBefore end: Date,
        calendar: Calendar
    ) -> [TrendDay] {
        let recoveriesByCycle = archive.recoveries.reduce(
            into: [Int64: WhoopRecovery]()
        ) { result, recovery in
            if result[recovery.cycleID]?.updatedAt ?? .distantPast < recovery.updatedAt {
                result[recovery.cycleID] = recovery
            }
        }
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

        let cyclesByDay = archive.cycles.reduce(into: [Date: WhoopCycle]()) {
            result,
            cycle in
            let date = calendar.startOfDay(for: cycle.start)
            guard date >= start, date < end else { return }
            if result[date]?.updatedAt ?? .distantPast < cycle.updatedAt {
                result[date] = cycle
            }
        }

        return cyclesByDay
            .map { date, cycle in
                let recovery = recoveriesByCycle[cycle.id]
                let sleep = recovery.flatMap { sleepsByID[$0.sleepID] }
                    ?? mainSleepsByCycle[cycle.id]
                return TrendDay(
                    date: date,
                    recoveryScore: recovery?.score?.recoveryPercentage,
                    strainScore: cycle.score?.strain,
                    sleepPerformancePercentage: sleep?.score?.performancePercentage,
                    heartRateVariabilityMilliseconds: recovery?.score?.hrvRMSSDMilliseconds,
                    restingHeartRate: recovery?.score?.restingHeartRate
                )
            }
            .sorted { $0.date < $1.date }
    }

    private static func summary(
        current: [TrendDay],
        previous: [TrendDay],
        value: KeyPath<TrendDay, Double?>
    ) -> TrendMetricSummary {
        let currentValues = current.compactMap { $0[keyPath: value] }
        let previousValues = previous.compactMap { $0[keyPath: value] }
        return TrendMetricSummary(
            currentAverage: average(currentValues),
            previousAverage: average(previousValues),
            currentSampleCount: currentValues.count,
            previousSampleCount: previousValues.count
        )
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
