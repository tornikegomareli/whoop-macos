import Foundation
import Testing
import WhoopScopeDomain
import WhoopScopePersistence

@testable import WhoopScopeChat

@Test
func comparisonQuestionSelectsTwoWeeksOfEvidence() {
    let calendar = fixedCalendar()
    let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 16))!

    let window = EvidenceWindow.resolve(
        question: "How did I sleep last week compared with the week before?",
        now: now,
        earliestDate: nil,
        calendar: calendar
    )

    #expect(window.dayCount == 14)
    #expect(window.label == "two-week comparison")
}

@Test
func monthComparisonIncludesBothPeriods() {
    let calendar = fixedCalendar()
    let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 16))!

    let window = EvidenceWindow.resolve(
        question: "Compare this month versus the previous month",
        now: now,
        earliestDate: nil,
        calendar: calendar
    )

    #expect(window.dayCount == 62)
    #expect(window.label == "two-month comparison")
}

@Test
func providerInstructionsRequireGroundedAnswers() {
    #expect(ChatInstructions.text.contains("Answer only from the EVIDENCE"))
    #expect(ChatInstructions.text.contains("WHOOP is the sole source for sleep and recovery"))
}

@Test
func openAIResponseIgnoresNonMessageOutputAndJoinsText() throws {
    let data = Data(
        #"""
        {
          "output": [
            { "type": "reasoning" },
            {
              "type": "message",
              "content": [
                { "type": "output_text", "text": "Recovery rose over the selected period." },
                { "type": "output_text", "text": "The evidence covers seven days." }
              ]
            }
          ]
        }
        """#.utf8
    )

    let text = try OpenAIProvider.responseText(from: data)

    #expect(text == "Recovery rose over the selected period.\nThe evidence covers seven days.")
}

@Test
func groundingUsesStoredWHOOPAndAppleHealthEvidence() async throws {
    let calendar = fixedCalendar()
    let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 16))!
    let recordedAt = calendar.date(from: DateComponents(year: 2026, month: 7, day: 15))!
    let database = try WhoopScopeDatabase.inMemory()
    let account = WhoopAccount(
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
        syncedAt: recordedAt
    )
    let cycle = WhoopCycle(
        id: 10,
        userID: 42,
        createdAt: recordedAt,
        updatedAt: recordedAt,
        start: recordedAt,
        end: recordedAt.addingTimeInterval(86_400),
        timezoneOffset: "+04:00",
        scoreState: .scored,
        score: .init(
            strain: 12.5,
            kilojoules: 8_368,
            averageHeartRate: 72,
            maxHeartRate: 170
        )
    )
    let recovery = WhoopRecovery(
        cycleID: cycle.id,
        sleepID: UUID(),
        userID: 42,
        createdAt: recordedAt,
        updatedAt: recordedAt,
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

    try await database.save(account)
    try await database.saveActivities(
        cycles: [cycle],
        recoveries: [recovery],
        sleeps: [],
        workouts: [],
        synchronizedAt: recordedAt
    )
    try await database.saveHealthEnrichment(
        HealthEnrichmentPayload(
            generatedAt: recordedAt,
            deviceName: "Test iPhone",
            samples: [
                HealthMetricSample(
                    kind: .steps,
                    date: recordedAt,
                    value: 9_842,
                    unit: "count",
                    source: "Apple Health"
                )
            ]
        )
    )

    let evidence = try await GroundingContextBuilder(database: database, calendar: calendar)
        .build(question: "How was my recovery this week?", now: now)

    #expect(evidence.label == "WHOOP • last week • Apple Health included")
    #expect(evidence.content.contains("rec 88%"))
    #expect(evidence.content.contains("SpO2 97.8%"))
    #expect(evidence.content.contains("energy 2000kcal"))
    #expect(evidence.content.contains("AH Steps 9842count"))
}

private func fixedCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
}
