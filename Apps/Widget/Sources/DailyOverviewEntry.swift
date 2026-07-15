import Foundation
import WidgetKit
import WhoopScopeWidgetSupport

struct DailyOverviewEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}
