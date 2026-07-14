import Foundation
import Testing
@testable import WhoopScopeTrends
import WhoopScopeDomain

@MainActor
@Test
func trendsModelLoadsAndChangesRange() async throws {
    let useCase = StubLoadTrends()
    let model = TrendsModel(loadTrends: useCase)

    await model.loadIfNeeded()
    #expect(model.snapshot?.range == .thirtyDays)

    await model.selectRange(.ninetyDays)
    #expect(model.selectedRange == .ninetyDays)
    #expect(model.snapshot?.range == .ninetyDays)
    #expect(await useCase.requests == [.thirtyDays, .ninetyDays])
}

private actor StubLoadTrends: LoadTrendsUseCase {
    private(set) var requests: [TrendRange] = []

    func execute(range: TrendRange, refresh _: Bool) async throws -> TrendsSnapshot {
        requests.append(range)
        return TrendsSnapshot(
            range: range,
            startDate: .now,
            endDate: .now,
            days: [],
            recovery: emptySummary,
            strain: emptySummary,
            sleepPerformance: emptySummary,
            heartRateVariability: emptySummary,
            restingHeartRate: emptySummary,
            lastSynchronizedAt: .now
        )
    }

    private var emptySummary: TrendMetricSummary {
        TrendMetricSummary(
            currentAverage: nil,
            previousAverage: nil,
            currentSampleCount: 0,
            previousSampleCount: 0
        )
    }
}
