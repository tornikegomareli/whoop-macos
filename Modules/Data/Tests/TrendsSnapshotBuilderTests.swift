import Foundation
import Testing
@testable import WhoopScopeData
import WhoopScopeDomain

@Test
func trendsBuilderComparesEquivalentPeriods() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let now = Date(timeIntervalSince1970: 1_768_435_200)
    let archive = makeArchive(now: now, calendar: calendar)

    let snapshot = try TrendsSnapshotBuilder.build(
        from: archive,
        range: .sevenDays,
        now: now,
        calendar: calendar
    )

    #expect(snapshot.days.count == 7)
    #expect(snapshot.recovery.currentAverage == 60)
    #expect(snapshot.recovery.previousAverage == 40)
    #expect(snapshot.recovery.change == 20)
    #expect(snapshot.strain.currentAverage == 12)
    #expect(snapshot.sleepPerformance.currentAverage == 80)
    #expect(snapshot.heartRateVariability.currentAverage == 70)
    #expect(snapshot.restingHeartRate.currentAverage == 55)
    #expect(snapshot.recovery.currentSampleCount == 7)
    #expect(snapshot.recovery.previousSampleCount == 7)

    let thirtyDaySnapshot = try TrendsSnapshotBuilder.build(
        from: archive,
        range: .thirtyDays,
        now: now,
        calendar: calendar
    )
    #expect(thirtyDaySnapshot.days.count == 14)
    #expect(thirtyDaySnapshot.recovery.previousAverage == nil)
}

private func makeArchive(now: Date, calendar: Calendar) -> WhoopDataArchive {
    let today = calendar.startOfDay(for: now)
    var cycles: [WhoopCycle] = []
    var recoveries: [WhoopRecovery] = []
    var sleeps: [WhoopSleep] = []

    for index in 0..<14 {
        let date = calendar.date(byAdding: .day, value: index - 13, to: today)!
        let isCurrentPeriod = index >= 7
        let cycleID = Int64(index + 1)
        let sleepID = UUID()
        cycles.append(
            WhoopCycle(
                id: cycleID,
                userID: 42,
                createdAt: date,
                updatedAt: date,
                start: date,
                end: calendar.date(byAdding: .day, value: 1, to: date),
                timezoneOffset: "+00:00",
                scoreState: .scored,
                score: .init(
                    strain: isCurrentPeriod ? 12 : 8,
                    kilojoules: 5_000,
                    averageHeartRate: 70,
                    maxHeartRate: 160
                )
            )
        )
        recoveries.append(
            WhoopRecovery(
                cycleID: cycleID,
                sleepID: sleepID,
                userID: 42,
                createdAt: date,
                updatedAt: date,
                scoreState: .scored,
                score: .init(
                    isUserCalibrating: false,
                    recoveryPercentage: isCurrentPeriod ? 60 : 40,
                    restingHeartRate: isCurrentPeriod ? 55 : 60,
                    hrvRMSSDMilliseconds: isCurrentPeriod ? 70 : 50,
                    spo2Percentage: nil,
                    skinTemperatureCelsius: nil
                )
            )
        )
        sleeps.append(makeSleep(id: sleepID, cycleID: cycleID, date: date, isCurrent: isCurrentPeriod))
    }

    return WhoopDataArchive(
        account: WhoopAccount(
            profile: WhoopUserProfile(
                userID: 42,
                email: "member@example.com",
                firstName: "Member",
                lastName: "Example"
            ),
            bodyMeasurements: WhoopBodyMeasurements(
                heightMeters: 1.8,
                weightKilograms: 75,
                maxHeartRate: 190
            ),
            syncedAt: now
        ),
        cycles: cycles,
        recoveries: recoveries,
        sleeps: sleeps,
        workouts: [],
        lastSynchronizedAt: now
    )
}

private func makeSleep(
    id: UUID,
    cycleID: Int64,
    date: Date,
    isCurrent: Bool
) -> WhoopSleep {
    WhoopSleep(
        id: id,
        cycleID: cycleID,
        legacyV1ID: nil,
        userID: 42,
        createdAt: date,
        updatedAt: date,
        start: date,
        end: date.addingTimeInterval(8 * 60 * 60),
        timezoneOffset: "+00:00",
        isNap: false,
        scoreState: .scored,
        score: .init(
            stageSummary: .init(
                totalInBedMilliseconds: 28_800_000,
                totalAwakeMilliseconds: 1_800_000,
                totalNoDataMilliseconds: 0,
                totalLightSleepMilliseconds: 14_000_000,
                totalSlowWaveSleepMilliseconds: 6_000_000,
                totalREMSleepMilliseconds: 7_000_000,
                sleepCycleCount: 5,
                disturbanceCount: 4
            ),
            sleepNeeded: .init(
                baselineMilliseconds: 28_800_000,
                fromSleepDebtMilliseconds: 0,
                fromRecentStrainMilliseconds: 0,
                fromRecentNapMilliseconds: 0
            ),
            respiratoryRate: 14,
            performancePercentage: isCurrent ? 80 : 70,
            consistencyPercentage: 85,
            efficiencyPercentage: 92
        )
    )
}
