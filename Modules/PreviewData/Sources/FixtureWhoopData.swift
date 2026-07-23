import Foundation
import WhoopScopeDomain

public enum FixtureWhoopData {
    public static func archive(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> WhoopDataArchive {
        let today = calendar.startOfDay(for: now)
        let account = WhoopAccount(
            profile: WhoopUserProfile(
                userID: 42,
                email: "alex@example.com",
                firstName: "Alex",
                lastName: "Morgan"
            ),
            bodyMeasurements: WhoopBodyMeasurements(
                heightMeters: 1.76,
                weightKilograms: 72.4,
                maxHeartRate: 191
            ),
            syncedAt: now.addingTimeInterval(-180)
        )

        var cycles: [WhoopCycle] = []
        var recoveries: [WhoopRecovery] = []
        var sleeps: [WhoopSleep] = []
        var workouts: [WhoopWorkout] = []

        for offset in stride(from: 189, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                continue
            }

            let sequence = 189 - offset
            let cycleID = Int64(10_000 + sequence)
            let sleepID = uuid(sequence: sequence, variant: 1)
            let cycleStart = calendar.date(byAdding: .hour, value: 4, to: day) ?? day
            let cycleEnd = calendar.date(byAdding: .day, value: 1, to: cycleStart)
            let updatedAt = cycleStart.addingTimeInterval(12 * 60 * 60)
            let recoveryScore = Double([61, 68, 74, 79, 66, 83, 88, 72, 77, 84][sequence % 10])
            let strainScore = [7.8, 9.4, 12.1, 14.8, 8.7, 11.3, 15.6, 10.2][sequence % 8]
            let sleepPerformance = Double([76, 81, 87, 90, 79, 85, 92, 88][sequence % 8])
            let achievedHours = [6.8, 7.2, 7.7, 8.0, 7.1, 7.6, 8.2, 7.9][sequence % 8]
            let achievedMilliseconds = Int64(achievedHours * 3_600_000)
            let awakeMilliseconds = Int64(0.55 * 3_600_000)
            let remMilliseconds = Int64(Double(achievedMilliseconds) * 0.23)
            let slowWaveMilliseconds = Int64(Double(achievedMilliseconds) * 0.19)
            let lightMilliseconds = achievedMilliseconds - remMilliseconds - slowWaveMilliseconds

            cycles.append(
                WhoopCycle(
                    id: cycleID,
                    userID: account.profile.userID,
                    createdAt: cycleStart,
                    updatedAt: updatedAt,
                    start: cycleStart,
                    end: cycleEnd,
                    timezoneOffset: "+04:00",
                    scoreState: .scored,
                    score: WhoopCycle.Score(
                        strain: strainScore,
                        kilojoules: 6_100 + Double(sequence % 7) * 360,
                        averageHeartRate: 66 + sequence % 10,
                        maxHeartRate: 151 + sequence % 24
                    )
                )
            )

            let sleepEnd = calendar.date(byAdding: .hour, value: 7, to: day) ?? day
            let sleepStart = sleepEnd.addingTimeInterval(
                -Double(achievedMilliseconds + awakeMilliseconds) / 1_000
            )
            sleeps.append(
                WhoopSleep(
                    id: sleepID,
                    cycleID: cycleID,
                    legacyV1ID: nil,
                    userID: account.profile.userID,
                    createdAt: sleepEnd,
                    updatedAt: updatedAt,
                    start: sleepStart,
                    end: sleepEnd,
                    timezoneOffset: "+04:00",
                    isNap: false,
                    scoreState: .scored,
                    score: WhoopSleep.Score(
                        stageSummary: WhoopSleep.StageSummary(
                            totalInBedMilliseconds: achievedMilliseconds + awakeMilliseconds,
                            totalAwakeMilliseconds: awakeMilliseconds,
                            totalNoDataMilliseconds: 0,
                            totalLightSleepMilliseconds: lightMilliseconds,
                            totalSlowWaveSleepMilliseconds: slowWaveMilliseconds,
                            totalREMSleepMilliseconds: remMilliseconds,
                            sleepCycleCount: 4 + sequence % 2,
                            disturbanceCount: 8 + sequence % 7
                        ),
                        sleepNeeded: WhoopSleep.SleepNeeded(
                            baselineMilliseconds: 28_800_000,
                            fromSleepDebtMilliseconds: Int64((sequence % 4) * 420_000),
                            fromRecentStrainMilliseconds: Int64((sequence % 3) * 300_000),
                            fromRecentNapMilliseconds: 0
                        ),
                        respiratoryRate: 14.2 + Double(sequence % 6) * 0.18,
                        performancePercentage: sleepPerformance,
                        consistencyPercentage: Double(82 + sequence % 13),
                        efficiencyPercentage: Double(91 + sequence % 6)
                    )
                )
            )

            recoveries.append(
                WhoopRecovery(
                    cycleID: cycleID,
                    sleepID: sleepID,
                    userID: account.profile.userID,
                    createdAt: sleepEnd,
                    updatedAt: updatedAt,
                    scoreState: .scored,
                    score: WhoopRecovery.Score(
                        isUserCalibrating: false,
                        recoveryPercentage: recoveryScore,
                        restingHeartRate: 48 + Double(sequence % 7),
                        hrvRMSSDMilliseconds: 57 + Double((sequence * 7) % 31),
                        spo2Percentage: 96.1 + Double(sequence % 8) * 0.25,
                        skinTemperatureCelsius: 33.1 + Double(sequence % 5) * 0.12
                    )
                )
            )

            if sequence % 9 == 4 {
                let napStart = calendar.date(byAdding: .hour, value: 14, to: day) ?? day
                sleeps.append(
                    nap(
                        id: uuid(sequence: sequence, variant: 2),
                        cycleID: cycleID,
                        userID: account.profile.userID,
                        start: napStart
                    )
                )
            }

            if sequence % 3 != 1 {
                workouts.append(
                    workout(
                        sequence: sequence,
                        userID: account.profile.userID,
                        day: day,
                        calendar: calendar
                    )
                )
            }
        }

        return WhoopDataArchive(
            account: account,
            cycles: cycles,
            recoveries: recoveries,
            sleeps: sleeps,
            workouts: workouts,
            lastSynchronizedAt: now.addingTimeInterval(-180)
        )
    }

    private static func nap(
        id: UUID,
        cycleID: Int64,
        userID: Int64,
        start: Date
    ) -> WhoopSleep {
        let duration: Int64 = 2_700_000
        return WhoopSleep(
            id: id,
            cycleID: cycleID,
            legacyV1ID: nil,
            userID: userID,
            createdAt: start,
            updatedAt: start,
            start: start,
            end: start.addingTimeInterval(Double(duration) / 1_000),
            timezoneOffset: "+04:00",
            isNap: true,
            scoreState: .scored,
            score: WhoopSleep.Score(
                stageSummary: WhoopSleep.StageSummary(
                    totalInBedMilliseconds: duration,
                    totalAwakeMilliseconds: 180_000,
                    totalNoDataMilliseconds: 0,
                    totalLightSleepMilliseconds: 1_500_000,
                    totalSlowWaveSleepMilliseconds: 720_000,
                    totalREMSleepMilliseconds: 300_000,
                    sleepCycleCount: 1,
                    disturbanceCount: 1
                ),
                sleepNeeded: WhoopSleep.SleepNeeded(
                    baselineMilliseconds: 0,
                    fromSleepDebtMilliseconds: 0,
                    fromRecentStrainMilliseconds: 0,
                    fromRecentNapMilliseconds: -2_520_000
                ),
                respiratoryRate: 14.6,
                performancePercentage: nil,
                consistencyPercentage: nil,
                efficiencyPercentage: 93
            )
        )
    }

    private static func workout(
        sequence: Int,
        userID: Int64,
        day: Date,
        calendar: Calendar
    ) -> WhoopWorkout {
        let sports = ["Running", "Strength Trainer", "Cycling", "Functional Fitness"]
        let durations = [2_640, 3_900, 4_500, 3_180]
        let index = sequence % sports.count
        let start = calendar.date(byAdding: .hour, value: 17, to: day) ?? day
        let duration = TimeInterval(durations[index])
        let strain = [12.8, 10.9, 14.2, 11.7][index] + Double(sequence % 3) * 0.3
        return WhoopWorkout(
            id: uuid(sequence: sequence, variant: 3),
            legacyV1ID: nil,
            userID: userID,
            createdAt: start,
            updatedAt: start.addingTimeInterval(duration),
            start: start,
            end: start.addingTimeInterval(duration),
            timezoneOffset: "+04:00",
            sportName: sports[index],
            sportID: 100 + index,
            scoreState: .scored,
            score: WhoopWorkout.Score(
                strain: strain,
                averageHeartRate: 132 + index * 6,
                maxHeartRate: 169 + index * 4,
                kilojoules: 1_650 + Double(index * 280),
                percentRecorded: 100,
                distanceMeters: index == 0 ? 7_420 : (index == 2 ? 21_800 : nil),
                altitudeGainMeters: index == 0 || index == 2 ? Double(95 + index * 60) : nil,
                altitudeChangeMeters: nil,
                zoneDurations: WhoopWorkout.ZoneDurations(
                    zoneZeroMilliseconds: 180_000,
                    zoneOneMilliseconds: 420_000,
                    zoneTwoMilliseconds: 780_000,
                    zoneThreeMilliseconds: 720_000,
                    zoneFourMilliseconds: 420_000,
                    zoneFiveMilliseconds: 120_000
                )
            )
        )
    }

    private static func uuid(sequence: Int, variant: Int) -> UUID {
        let suffix = String(format: "%012X", sequence * 10 + variant)
        return UUID(uuidString: "00000000-0000-4000-8000-\(suffix)")
            ?? UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    }
}

public struct FixtureAuthenticationService: AuthenticationService {
    public init() {}

    public func status() async -> AuthenticationStatus { .signedIn }
    public func signIn() async throws {}
    public func signOut() async throws {}
}

public struct FixtureWhoopAccountRepository: WhoopAccountRepository {
    private let account: WhoopAccount

    public init(account: WhoopAccount) {
        self.account = account
    }

    public func storedAccount() async throws -> WhoopAccount? { account }
    public func refreshAccount() async throws -> WhoopAccount { account }
}

public struct FixtureExplorerRepository: ExplorerRepository {
    private let value: WhoopDataArchive

    public init(archive: WhoopDataArchive) {
        value = archive
    }

    public func archive(refresh: Bool) async throws -> WhoopDataArchive { value }
}

public struct FixtureTrendsRepository: TrendsRepository {
    private let archive: WhoopDataArchive
    private let now: Date
    private let calendar: Calendar

    public init(
        archive: WhoopDataArchive,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        self.archive = archive
        self.now = now
        self.calendar = calendar
    }

    public func trends(range: TrendRange, refresh: Bool) async throws -> TrendsSnapshot {
        let today = calendar.startOfDay(for: now)
        let startDate = calendar.date(
            byAdding: .day,
            value: 1 - range.dayCount,
            to: today
        ) ?? today
        let previousStart = calendar.date(
            byAdding: .day,
            value: -range.dayCount,
            to: startDate
        ) ?? startDate
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let recoveryByCycle = Dictionary(
            uniqueKeysWithValues: archive.recoveries.map { ($0.cycleID, $0) }
        )
        let sleepByCycle = archive.sleeps
            .filter { !$0.isNap }
            .reduce(into: [Int64: WhoopSleep]()) { $0[$1.cycleID] = $1 }
        let allDays = archive.cycles.compactMap { cycle -> TrendDay? in
            let date = calendar.startOfDay(for: cycle.start)
            guard date >= previousStart, date < endExclusive else { return nil }
            let recovery = recoveryByCycle[cycle.id]
            let sleep = sleepByCycle[cycle.id]
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

        let current = allDays.filter { $0.date >= startDate }
        let previous = allDays.filter { $0.date < startDate }
        return TrendsSnapshot(
            range: range,
            startDate: startDate,
            endDate: today,
            days: current,
            recovery: summary(current, previous, keyPath: \.recoveryScore),
            strain: summary(current, previous, keyPath: \.strainScore),
            sleepPerformance: summary(
                current,
                previous,
                keyPath: \.sleepPerformancePercentage
            ),
            heartRateVariability: summary(
                current,
                previous,
                keyPath: \.heartRateVariabilityMilliseconds
            ),
            restingHeartRate: summary(current, previous, keyPath: \.restingHeartRate),
            lastSynchronizedAt: archive.lastSynchronizedAt
        )
    }

    private func summary(
        _ current: [TrendDay],
        _ previous: [TrendDay],
        keyPath: KeyPath<TrendDay, Double?>
    ) -> TrendMetricSummary {
        let currentValues = current.compactMap { $0[keyPath: keyPath] }
        let previousValues = previous.compactMap { $0[keyPath: keyPath] }
        return TrendMetricSummary(
            currentAverage: average(currentValues),
            previousAverage: average(previousValues),
            currentSampleCount: currentValues.count,
            previousSampleCount: previousValues.count
        )
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
