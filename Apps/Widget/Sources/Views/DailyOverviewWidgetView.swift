import SwiftUI
import WidgetKit

struct DailyOverviewWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: DailyOverviewEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                MediumDailyOverviewView(snapshot: snapshot)
            default:
                SmallDailyOverviewView(snapshot: snapshot)
            }
        } else {
            WidgetEmptyView()
        }
    }
}
