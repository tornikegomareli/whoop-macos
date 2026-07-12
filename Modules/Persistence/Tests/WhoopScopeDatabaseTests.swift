import Foundation
import Testing
@testable import WhoopScopePersistence
import WhoopScopeDomain

@Test
func databaseRoundTripsWHOOPAccount() async throws {
    let database = try WhoopScopeDatabase.inMemory()
    let expected = WhoopAccount(
        profile: WhoopUserProfile(
            userID: 42,
            email: "taylor@example.com",
            firstName: "Taylor",
            lastName: "Example"
        ),
        bodyMeasurements: WhoopBodyMeasurements(
            heightMeters: 1.8,
            weightKilograms: 75.5,
            maxHeartRate: 195
        ),
        syncedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    try await database.save(expected)

    #expect(try await database.readAccount() == expected)
}

@Test
func databaseRoundTripsCompleteWHOOPActivityPayloads() async throws {
    let database = try WhoopScopeDatabase.inMemory()
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let updatedAt = start.addingTimeInterval(60)
    let sleepID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    let workoutID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    let account = WhoopAccount(
        profile: WhoopUserProfile(
            userID: 42,
            email: "member@example.com",
            firstName: "Member",
            lastName: "Example"
        ),
        bodyMeasurements: WhoopBodyMeasurements(
            heightMeters: 1.8,
            weightKilograms: 75.5,
            maxHeartRate: 195
        ),
        syncedAt: start
    )
    let cycle = WhoopCycle(
        id: 10,
        userID: 42,
        createdAt: start,
        updatedAt: updatedAt,
        start: start,
        end: start.addingTimeInterval(86_400),
        timezoneOffset: "+04:00",
        scoreState: .scored,
        score: .init(
            strain: 12.3,
            kilojoules: 8_000,
            averageHeartRate: 72,
            maxHeartRate: 170
        )
    )
    let recovery = WhoopRecovery(
        cycleID: cycle.id,
        sleepID: sleepID,
        userID: 42,
        createdAt: start,
        updatedAt: updatedAt,
        scoreState: .scored,
        score: .init(
            isUserCalibrating: false,
            recoveryPercentage: 88,
            restingHeartRate: 50,
            hrvRMSSDMilliseconds: 72.5,
            spo2Percentage: 97.8,
            skinTemperatureCelsius: 33.2
        )
    )
    let sleep = WhoopSleep(
        id: sleepID,
        cycleID: cycle.id,
        legacyV1ID: 100,
        userID: 42,
        createdAt: start,
        updatedAt: updatedAt,
        start: start,
        end: start.addingTimeInterval(28_800),
        timezoneOffset: "+04:00",
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
                disturbanceCount: 7
            ),
            sleepNeeded: .init(
                baselineMilliseconds: 28_000_000,
                fromSleepDebtMilliseconds: 1_000_000,
                fromRecentStrainMilliseconds: 500_000,
                fromRecentNapMilliseconds: -250_000
            ),
            respiratoryRate: 14.2,
            performancePercentage: 91,
            consistencyPercentage: 86,
            efficiencyPercentage: 93
        )
    )
    let workout = WhoopWorkout(
        id: workoutID,
        legacyV1ID: 200,
        userID: 42,
        createdAt: start,
        updatedAt: updatedAt,
        start: start,
        end: start.addingTimeInterval(3_600),
        timezoneOffset: "+04:00",
        sportName: "running",
        sportID: 0,
        scoreState: .scored,
        score: .init(
            strain: 10.5,
            averageHeartRate: 140,
            maxHeartRate: 180,
            kilojoules: 2_100,
            percentRecorded: 100,
            distanceMeters: 10_000,
            altitudeGainMeters: 120,
            altitudeChangeMeters: 5,
            zoneDurations: .init(
                zoneZeroMilliseconds: 100,
                zoneOneMilliseconds: 200,
                zoneTwoMilliseconds: 300,
                zoneThreeMilliseconds: 400,
                zoneFourMilliseconds: 500,
                zoneFiveMilliseconds: 600
            )
        )
    )
    let synchronizedAt = updatedAt.addingTimeInterval(60)

    try await database.save(account)
    try await database.saveActivities(
        cycles: [cycle],
        recoveries: [recovery],
        sleeps: [sleep],
        workouts: [workout],
        synchronizedAt: synchronizedAt
    )

    let archive = try #require(try await database.readArchive())
    #expect(archive.account == account)
    #expect(archive.cycles == [cycle])
    #expect(archive.recoveries == [recovery])
    #expect(archive.sleeps == [sleep])
    #expect(archive.workouts == [workout])
    #expect(archive.lastSynchronizedAt == synchronizedAt)
    #expect(
        try await database.activityWatermarks()
            == WhoopActivityWatermarks(
                cycleStart: start,
                recoveryStart: start,
                sleepStart: start,
                workoutStart: start
            )
    )
}
