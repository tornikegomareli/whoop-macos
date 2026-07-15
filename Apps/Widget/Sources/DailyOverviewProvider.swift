import Foundation
import WidgetKit
import WhoopScopeWidgetSupport

struct DailyOverviewProvider: TimelineProvider {
    private let store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> DailyOverviewEntry {
        DailyOverviewEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (DailyOverviewEntry) -> Void
    ) {
        completion(
            DailyOverviewEntry(
                date: .now,
                snapshot: context.isPreview ? .preview : store.load()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<DailyOverviewEntry>) -> Void
    ) {
        let now = Date.now
        let entry = DailyOverviewEntry(date: now, snapshot: store.load())
        let nextRefresh = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: now
        ) ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
