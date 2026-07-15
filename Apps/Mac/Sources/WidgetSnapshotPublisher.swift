import WidgetKit
import WhoopScopeDomain
import WhoopScopeWidgetSupport

struct WidgetSnapshotPublisher: Sendable {
    private let store: WidgetSnapshotStore

    init(store: WidgetSnapshotStore = WidgetSnapshotStore()) {
        self.store = store
    }

    func publish(_ dashboard: DashboardSnapshot) {
        let sleepSeconds = dashboard.sleep.sleepAchieved.components.seconds
        let snapshot = WidgetSnapshot(
            recoveryScore: dashboard.recovery.score,
            strainScore: dashboard.strain.score,
            sleepPerformancePercentage: dashboard.sleep.performancePercentage,
            heartRateVariabilityMilliseconds: dashboard.recovery.heartRateVariabilityMilliseconds,
            restingHeartRate: dashboard.recovery.restingHeartRate,
            sleepAchievedSeconds: sleepSeconds,
            synchronizedAt: dashboard.lastSynchronizedAt
        )

        guard (try? store.save(snapshot)) != nil else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.dailyOverviewKind)
    }

    func clear() {
        store.clear()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetConstants.dailyOverviewKind)
    }
}
