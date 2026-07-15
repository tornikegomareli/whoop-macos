import Testing
@testable import WhoopScopeDashboard
import WhoopScopeDomain
import WhoopScopePreviewData

@MainActor
@Test
func dashboardModelLoadsSnapshot() async {
    let repository = FixtureDashboardRepository()
    let recorder = DashboardSnapshotRecorder()
    let model = DashboardModel(
        loadDashboard: LoadDashboard(repository: repository),
        snapshotDidLoad: recorder.record
    )

    await model.loadIfNeeded()

    #expect(model.snapshot?.recovery.score == 84)
    #expect(model.snapshot?.history.count == 14)
    #expect(model.snapshot?.recentWorkouts.count == 3)
    #expect(recorder.snapshots.count == 1)
}

@MainActor
private final class DashboardSnapshotRecorder {
    private(set) var snapshots: [DashboardSnapshot] = []

    func record(_ snapshot: DashboardSnapshot) {
        snapshots.append(snapshot)
    }
}

@MainActor
@Test
func dashboardModelRefreshesStaleMenuBarData() async throws {
    let snapshot = try await FixtureDashboardRepository().dashboard()
    let repository = CountingDashboardRepository(snapshot: snapshot)
    let model = DashboardModel(
        loadDashboard: LoadDashboard(repository: repository)
    )

    await model.loadIfNeeded()
    await model.refreshIfStale(maximumAge: 0)

    #expect(await repository.requestCount == 2)
}

private actor CountingDashboardRepository: DashboardRepository {
    let snapshot: DashboardSnapshot
    private(set) var requestCount = 0

    init(snapshot: DashboardSnapshot) {
        self.snapshot = snapshot
    }

    func dashboard() async throws -> DashboardSnapshot {
        requestCount += 1
        return snapshot
    }
}

@Test
func workoutDurationsUseReadableUnits() {
    #expect(Duration.seconds(42 * 60).workoutDescription == "42 min")
    #expect(Duration.seconds(60 * 60).workoutDescription == "1 hr")
    #expect(Duration.seconds(72 * 60).workoutDescription == "1 hr 12 min")
}
