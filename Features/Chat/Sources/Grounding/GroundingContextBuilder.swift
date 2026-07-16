import Foundation
import WhoopScopeDomain
import WhoopScopePersistence

struct GroundedEvidence: Sendable {
    let content: String
    let label: String
}

struct GroundingContextBuilder: Sendable {
    let database: WhoopScopeDatabase
    var calendar = Calendar.autoupdatingCurrent

    func build(question: String, now: Date = .now) async throws -> GroundedEvidence {
        guard let archive = try await database.readArchive() else {
            throw AIProviderError.noSynchronizedData
        }

        let requestedWindow = EvidenceWindow.resolve(
            question: question,
            now: now,
            earliestDate: archive.cycles.map(\.start).min(),
            calendar: calendar
        )
        let healthSamples = try await database.readHealthEnrichment(
            since: requestedWindow.start
        ).filter { $0.date < requestedWindow.end }
        let days = makeDays(
            archive: archive,
            healthSamples: healthSamples,
            window: requestedWindow
        )

        let evidence = makeEvidence(
            archive: archive,
            days: days,
            window: requestedWindow,
            includesAppleHealth: !healthSamples.isEmpty
        )
        let sourceSuffix = healthSamples.isEmpty ? "" : " • Apple Health included"
        return GroundedEvidence(
            content: evidence,
            label: "WHOOP • \(requestedWindow.label)\(sourceSuffix)"
        )
    }

    private func makeDays(
        archive: WhoopDataArchive,
        healthSamples: [HealthMetricSample],
        window: EvidenceWindow
    ) -> [DayEvidence] {
        let recoveriesByCycle = Dictionary(
            uniqueKeysWithValues: archive.recoveries.map { ($0.cycleID, $0) }
        )
        let sleepsByID = Dictionary(uniqueKeysWithValues: archive.sleeps.map { ($0.id, $0) })
        let mainSleepsByCycle = archive.sleeps
            .filter { !$0.isNap }
            .reduce(into: [Int64: WhoopSleep]()) { result, sleep in
                if result[sleep.cycleID]?.updatedAt ?? .distantPast < sleep.updatedAt {
                    result[sleep.cycleID] = sleep
                }
            }
        var days: [Date: DayEvidence] = [:]

        for cycle in archive.cycles where window.contains(cycle.start) {
            let date = calendar.startOfDay(for: cycle.start)
            var day = days[date] ?? DayEvidence(date: date)
            if let score = cycle.score {
                day.strain = score.strain
                day.kilocalories = score.kilojoules / 4.184
                day.averageHeartRate = Double(score.averageHeartRate)
            }
            if let recovery = recoveriesByCycle[cycle.id], let score = recovery.score {
                day.recovery = score.recoveryPercentage
                day.hrv = score.hrvRMSSDMilliseconds
                day.restingHeartRate = score.restingHeartRate
                day.spo2 = score.spo2Percentage
                day.skinTemperature = score.skinTemperatureCelsius

                let sleep = sleepsByID[recovery.sleepID] ?? mainSleepsByCycle[cycle.id]
                if let sleepScore = sleep?.score {
                    day.sleepPerformance = sleepScore.performancePercentage
                    day.sleepConsistency = sleepScore.consistencyPercentage
                    day.sleepEfficiency = sleepScore.efficiencyPercentage
                    day.sleepHours =
                        Double(
                            sleepScore.stageSummary.achievedSleepMilliseconds
                        ) / 3_600_000
                    day.sleepNeedHours =
                        Double(sleepScore.sleepNeeded.totalMilliseconds)
                        / 3_600_000
                    day.respiratoryRate = sleepScore.respiratoryRate
                }
            }
            days[date] = day
        }

        for workout in archive.workouts where window.contains(workout.start) {
            let date = calendar.startOfDay(for: workout.start)
            var day = days[date] ?? DayEvidence(date: date)
            day.workouts.append(
                WorkoutEvidence(
                    name: workout.sportName.localizedCapitalized,
                    minutes: max(0, workout.end.timeIntervalSince(workout.start) / 60),
                    strain: workout.score?.strain,
                    averageHeartRate: workout.score.map { Double($0.averageHeartRate) },
                    distanceMeters: workout.score?.distanceMeters
                )
            )
            days[date] = day
        }

        for sample in healthSamples where window.contains(sample.date) {
            let date = calendar.startOfDay(for: sample.date)
            var day = days[date] ?? DayEvidence(date: date)
            day.health[sample.kind] = sample
            days[date] = day
        }

        return days.values.sorted { $0.date < $1.date }
    }

    private func makeEvidence(
        archive: WhoopDataArchive,
        days: [DayEvidence],
        window: EvidenceWindow,
        includesAppleHealth: Bool
    ) -> String {
        let dateRange =
            "\(formatDate(window.start)) through \(formatDate(window.end.addingTimeInterval(-1)))"
        var sections = [
            "REQUESTED RANGE: \(dateRange)",
            "WHOOP LAST SYNC: \(formatDateTime(archive.lastSynchronizedAt))",
            "SOURCE RULE: Recovery and sleep below are exclusively from WHOOP."
                + (includesAppleHealth
                    ? " Complementary Apple Health fields are explicitly prefixed with AH."
                    : " No Apple Health summaries are available for this range."),
            "AVAILABLE DAYS: \(days.count)",
            "OVERALL SUMMARY:\n\(summary(for: days))",
        ]

        if days.count >= 4 {
            let midpoint = days.count / 2
            let earlier = Array(days.prefix(midpoint))
            let recent = Array(days.suffix(days.count - midpoint))
            sections.append(
                "EQUAL-PERIOD COMPARISON:\n"
                    + "Earlier (\(rangeLabel(earlier))): \(summary(for: earlier))\n"
                    + "Recent (\(rangeLabel(recent))): \(summary(for: recent))"
            )
        }

        sections.append("TIMELINE:\n\(timeline(for: days, window: window))")
        let workouts = days.flatMap { day in day.workouts.map { (day.date, $0) } }
        if !workouts.isEmpty {
            sections.append(
                "WORKOUT DETAILS (newest first, maximum 30):\n"
                    + workouts.suffix(30).reversed().map(workoutLine).joined(separator: "\n")
            )
        }
        return sections.joined(separator: "\n\n")
    }

    private func timeline(for days: [DayEvidence], window: EvidenceWindow) -> String {
        if window.dayCount <= 45 {
            return days.map(dayLine).joined(separator: "\n")
        }

        let grouped = Dictionary(grouping: days) { day -> Date in
            if window.dayCount <= 180 {
                return calendar.dateInterval(of: .weekOfYear, for: day.date)?.start ?? day.date
            }
            return calendar.dateInterval(of: .month, for: day.date)?.start ?? day.date
        }
        return grouped.keys.sorted().map { key in
            let bucket = grouped[key] ?? []
            return "\(rangeLabel(bucket)): \(summary(for: bucket))"
        }.joined(separator: "\n")
    }

    private func summary(for days: [DayEvidence]) -> String {
        guard !days.isEmpty else {
            return "No records."
        }
        var parts: [String] = []
        appendAverage("recovery", values: days.compactMap(\.recovery), suffix: "%", to: &parts)
        appendAverage("HRV", values: days.compactMap(\.hrv), suffix: "ms", to: &parts)
        appendAverage("RHR", values: days.compactMap(\.restingHeartRate), suffix: "bpm", to: &parts)
        appendAverage("SpO2", values: days.compactMap(\.spo2), suffix: "%", to: &parts)
        appendAverage(
            "skin temperature", values: days.compactMap(\.skinTemperature), suffix: "°C", to: &parts
        )
        appendAverage("strain", values: days.compactMap(\.strain), suffix: "/21", to: &parts)
        appendAverage("energy", values: days.compactMap(\.kilocalories), suffix: "kcal", to: &parts)
        appendAverage(
            "average heart rate", values: days.compactMap(\.averageHeartRate), suffix: "bpm",
            to: &parts)
        appendAverage(
            "sleep performance", values: days.compactMap(\.sleepPerformance), suffix: "%",
            to: &parts)
        appendAverage(
            "sleep consistency", values: days.compactMap(\.sleepConsistency), suffix: "%",
            to: &parts)
        appendAverage(
            "sleep efficiency", values: days.compactMap(\.sleepEfficiency), suffix: "%", to: &parts)
        appendAverage(
            "sleep achieved", values: days.compactMap(\.sleepHours), suffix: "h", to: &parts)
        appendAverage(
            "sleep needed", values: days.compactMap(\.sleepNeedHours), suffix: "h", to: &parts)
        appendAverage(
            "respiratory rate", values: days.compactMap(\.respiratoryRate), suffix: "rpm",
            to: &parts)
        parts.append("workouts \(days.reduce(0) { $0 + $1.workouts.count })")

        let healthKinds = Set(days.flatMap { $0.health.keys }).sorted { $0.rawValue < $1.rawValue }
        for kind in healthKinds {
            let samples = days.compactMap { $0.health[kind] }
            guard let unit = samples.first?.unit else { continue }
            appendAverage(
                "AH \(kind.displayName) daily",
                values: samples.map(\.value),
                suffix: unit,
                to: &parts
            )
        }
        return parts.joined(separator: "; ")
    }

    private func dayLine(_ day: DayEvidence) -> String {
        var fields = [formatDate(day.date)]
        append("rec", day.recovery, "%", to: &fields)
        append("HRV", day.hrv, "ms", to: &fields)
        append("RHR", day.restingHeartRate, "bpm", to: &fields)
        append("SpO2", day.spo2, "%", to: &fields)
        append("skin temp", day.skinTemperature, "°C", to: &fields)
        append("strain", day.strain, "/21", to: &fields)
        append("energy", day.kilocalories, "kcal", to: &fields)
        append("avg HR", day.averageHeartRate, "bpm", to: &fields)
        append("sleep", day.sleepPerformance, "%", to: &fields)
        if let sleepHours = day.sleepHours, let needHours = day.sleepNeedHours {
            fields.append("sleep hours \(number(sleepHours))/\(number(needHours)) needed")
        }
        append("sleep efficiency", day.sleepEfficiency, "%", to: &fields)
        append("sleep consistency", day.sleepConsistency, "%", to: &fields)
        append("respiratory rate", day.respiratoryRate, "rpm", to: &fields)
        if !day.workouts.isEmpty { fields.append("workouts \(day.workouts.count)") }
        for sample in day.health.values.sorted(by: { $0.kind.rawValue < $1.kind.rawValue }) {
            fields.append("AH \(sample.kind.displayName) \(number(sample.value))\(sample.unit)")
        }
        return fields.joined(separator: " | ")
    }

    private func workoutLine(_ item: (Date, WorkoutEvidence)) -> String {
        let (date, workout) = item
        var fields = [
            formatDate(date),
            workout.name,
            "\(number(workout.minutes))min",
        ]
        append("strain", workout.strain, "", to: &fields)
        append("avg HR", workout.averageHeartRate, "bpm", to: &fields)
        append("distance", workout.distanceMeters, "m", to: &fields)
        return fields.joined(separator: " | ")
    }

    private func rangeLabel(_ days: [DayEvidence]) -> String {
        guard let first = days.first?.date, let last = days.last?.date else { return "no dates" }
        return "\(formatDate(first))–\(formatDate(last))"
    }

    private func appendAverage(
        _ name: String,
        values: [Double],
        suffix: String,
        to parts: inout [String]
    ) {
        guard !values.isEmpty else { return }
        parts.append("\(name) avg \(number(values.reduce(0, +) / Double(values.count)))\(suffix)")
    }

    private func append(
        _ name: String,
        _ value: Double?,
        _ suffix: String,
        to parts: inout [String]
    ) {
        guard let value else { return }
        parts.append("\(name) \(number(value))\(suffix)")
    }

    private func number(_ value: Double) -> String {
        value.formatted(
            .number
                .locale(Locale(identifier: "en_US_POSIX"))
                .grouping(.never)
                .precision(.fractionLength(0...1))
        )
    }

    private func formatDate(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private func formatDateTime(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

struct EvidenceWindow: Equatable, Sendable {
    let start: Date
    let end: Date
    let label: String
    let dayCount: Int

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    static func resolve(
        question: String,
        now: Date,
        earliestDate: Date?,
        calendar: Calendar
    ) -> EvidenceWindow {
        let normalized = question.lowercased()
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let days: Int
        let label: String

        if normalized.contains("all time") || normalized.contains("entire history") {
            let start = calendar.startOfDay(for: earliestDate ?? now)
            let count = max(1, calendar.dateComponents([.day], from: start, to: end).day ?? 1)
            return EvidenceWindow(start: start, end: end, label: "all history", dayCount: count)
        } else if normalized.contains("year") || normalized.contains("12 month") {
            days = 365
            label = "last year"
        } else if normalized.contains("90 day") || normalized.contains("3 month")
            || normalized.contains("three month")
        {
            days = 90
            label = "last 90 days"
        } else if normalized.contains("month") {
            let isComparison =
                normalized.contains("previous") || normalized.contains("before")
                || normalized.contains("versus") || normalized.contains(" vs ")
            days = isComparison ? 62 : 31
            label = isComparison ? "two-month comparison" : "last month"
        } else if normalized.contains("week before") || normalized.contains("previous week")
            || normalized.contains("two week") || normalized.contains("2 week")
        {
            days = 14
            label = "two-week comparison"
        } else if normalized.contains("week") {
            days = 7
            label = "last week"
        } else {
            days = 30
            label = "last 30 days"
        }

        let start = calendar.date(byAdding: .day, value: -days, to: end)!
        return EvidenceWindow(start: start, end: end, label: label, dayCount: days)
    }
}

private struct DayEvidence {
    let date: Date
    var recovery: Double?
    var hrv: Double?
    var restingHeartRate: Double?
    var spo2: Double?
    var skinTemperature: Double?
    var strain: Double?
    var kilocalories: Double?
    var averageHeartRate: Double?
    var sleepPerformance: Double?
    var sleepConsistency: Double?
    var sleepEfficiency: Double?
    var sleepHours: Double?
    var sleepNeedHours: Double?
    var respiratoryRate: Double?
    var workouts: [WorkoutEvidence] = []
    var health: [HealthMetricKind: HealthMetricSample] = [:]
}

private struct WorkoutEvidence {
    let name: String
    let minutes: Double
    let strain: Double?
    let averageHeartRate: Double?
    let distanceMeters: Double?
}
