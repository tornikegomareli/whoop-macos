import Foundation
import Testing
@testable import WhoopScopeExplorers
import WhoopScopeDomain

@Test
func recordedPercentageSupportsFractionalAndWholeRepresentations() {
    #expect(1.0.explorerRecordedPercent == "100%")
    #expect(100.0.explorerRecordedPercent == "100%")
}

@Test
func explorerBuilderFiltersRangeAndPreservesDetailedRecords() throws {
    let fixture = ExplorerFixture()

    let snapshot = try ExplorerSnapshotBuilder.build(
        from: fixture.archive,
        range: .sevenDays,
        now: fixture.now,
        calendar: fixture.calendar
    )

    #expect(snapshot.cycles.count == 1)
    #expect(snapshot.recoveries.count == 1)
    #expect(snapshot.sleeps.count == 2)
    #expect(snapshot.workouts.count == 1)
    #expect(snapshot.sleeps.contains { $0.isNap })
    #expect(snapshot.workouts.first?.score?.zoneDurations.zoneFiveMilliseconds == 600_000)
    #expect(snapshot.recoveries.first?.recovery.score?.spo2Percentage == 98)
    #expect(snapshot.sleepSummary.mainSleepCount == 1)
    #expect(snapshot.sleepSummary.napCount == 1)
    #expect(snapshot.sleepSummary.averagePerformance == 90)
    #expect(snapshot.recoverySummary.averageRecovery == 82)
    #expect(snapshot.recoverySummary.greenCount == 1)
    #expect(snapshot.cycleSummary.averageStrain == 12)
    #expect(snapshot.workoutSummary.topSport == "Running")
}

@Test
func explorerBuilderIncludesOlderRecordsForLongerRange() throws {
    let fixture = ExplorerFixture()

    let sevenDays = try ExplorerSnapshotBuilder.build(
        from: fixture.archive,
        range: .sevenDays,
        now: fixture.now,
        calendar: fixture.calendar
    )
    let ninetyDays = try ExplorerSnapshotBuilder.build(
        from: fixture.archive,
        range: .ninetyDays,
        now: fixture.now,
        calendar: fixture.calendar
    )

    #expect(sevenDays.cycles.count == 1)
    #expect(ninetyDays.cycles.count == 2)
}

@MainActor
@Test
func explorerModelChangesRangeLocallyAndRefreshesOnDemand() async {
    let fixture = ExplorerFixture()
    let useCase = StubLoadExplorer(archive: fixture.archive)
    let model = ExplorerModel(
        loadExplorer: useCase,
        now: { fixture.now }
    )

    await model.loadIfNeeded()
    #expect(model.snapshot?.range == .thirtyDays)
    #expect(await useCase.refreshValues == [false])

    model.selectRange(.ninetyDays)
    #expect(model.snapshot?.range == .ninetyDays)
    #expect(model.snapshot?.cycles.count == 2)
    #expect(await useCase.refreshValues == [false])

    await model.refresh()
    #expect(await useCase.refreshValues == [false, true])
}

private actor StubLoadExplorer: LoadExplorerUseCase {
    let archive: WhoopDataArchive
    private(set) var refreshValues: [Bool] = []

    init(archive: WhoopDataArchive) {
        self.archive = archive
    }

    func execute(refresh: Bool) async throws -> WhoopDataArchive {
        refreshValues.append(refresh)
        return archive
    }
}

private struct ExplorerFixture {
    let calendar: Calendar
    let now: Date
    let archive: WhoopDataArchive

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
        now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 23))!

        let today = calendar.startOfDay(for: now)
        let recentDate = calendar.date(byAdding: .day, value: -1, to: today)!
        let oldDate = calendar.date(byAdding: .day, value: -40, to: today)!
        let sleepID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let napID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let workoutID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        let recentCycle = WhoopCycle(
            id: 1,
            userID: 42,
            createdAt: recentDate,
            updatedAt: recentDate,
            start: recentDate,
            end: recentDate.addingTimeInterval(86_400),
            timezoneOffset: "+00:00",
            scoreState: .scored,
            score: .init(
                strain: 12,
                kilojoules: 8_368,
                averageHeartRate: 72,
                maxHeartRate: 172
            )
        )
        let oldCycle = WhoopCycle(
            id: 2,
            userID: 42,
            createdAt: oldDate,
            updatedAt: oldDate,
            start: oldDate,
            end: oldDate.addingTimeInterval(86_400),
            timezoneOffset: "+00:00",
            scoreState: .scored,
            score: .init(
                strain: 8,
                kilojoules: 4_184,
                averageHeartRate: 68,
                maxHeartRate: 150
            )
        )
        let recovery = WhoopRecovery(
            cycleID: recentCycle.id,
            sleepID: sleepID,
            userID: 42,
            createdAt: recentDate,
            updatedAt: recentDate,
            scoreState: .scored,
            score: .init(
                isUserCalibrating: false,
                recoveryPercentage: 82,
                restingHeartRate: 51,
                hrvRMSSDMilliseconds: 74,
                spo2Percentage: 98,
                skinTemperatureCelsius: 33.4
            )
        )
        let sleep = WhoopSleep(
            id: sleepID,
            cycleID: recentCycle.id,
            legacyV1ID: 10,
            userID: 42,
            createdAt: recentDate,
            updatedAt: recentDate,
            start: recentDate.addingTimeInterval(22 * 3_600),
            end: recentDate.addingTimeInterval(30 * 3_600),
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
                    baselineMilliseconds: 28_000_000,
                    fromSleepDebtMilliseconds: 1_000_000,
                    fromRecentStrainMilliseconds: 500_000,
                    fromRecentNapMilliseconds: -250_000
                ),
                respiratoryRate: 14,
                performancePercentage: 90,
                consistencyPercentage: 86,
                efficiencyPercentage: 94
            )
        )
        let nap = WhoopSleep(
            id: napID,
            cycleID: recentCycle.id,
            legacyV1ID: 11,
            userID: 42,
            createdAt: recentDate,
            updatedAt: recentDate,
            start: recentDate.addingTimeInterval(12 * 3_600),
            end: recentDate.addingTimeInterval(13 * 3_600),
            timezoneOffset: "+00:00",
            isNap: true,
            scoreState: .scored,
            score: nil
        )
        let workout = WhoopWorkout(
            id: workoutID,
            legacyV1ID: 12,
            userID: 42,
            createdAt: recentDate,
            updatedAt: recentDate,
            start: recentDate.addingTimeInterval(10 * 3_600),
            end: recentDate.addingTimeInterval(11 * 3_600),
            timezoneOffset: "+00:00",
            sportName: "running",
            sportID: 0,
            scoreState: .scored,
            score: .init(
                strain: 10,
                averageHeartRate: 145,
                maxHeartRate: 180,
                kilojoules: 2_092,
                percentRecorded: 100,
                distanceMeters: 10_000,
                altitudeGainMeters: 120,
                altitudeChangeMeters: 5,
                zoneDurations: .init(
                    zoneZeroMilliseconds: 60_000,
                    zoneOneMilliseconds: 120_000,
                    zoneTwoMilliseconds: 180_000,
                    zoneThreeMilliseconds: 240_000,
                    zoneFourMilliseconds: 300_000,
                    zoneFiveMilliseconds: 600_000
                )
            )
        )

        archive = WhoopDataArchive(
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
            cycles: [recentCycle, oldCycle],
            recoveries: [recovery],
            sleeps: [sleep, nap],
            workouts: [workout],
            lastSynchronizedAt: now
        )
    }
}
