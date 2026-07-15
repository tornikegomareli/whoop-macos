import SwiftUI
import WidgetKit
import WhoopScopeWidgetSupport

@main
struct WhoopScopeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: WidgetConstants.dailyOverviewKind,
            provider: DailyOverviewProvider()
        ) { entry in
            DailyOverviewWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("WHOOP Daily Overview")
        .description("See recovery, strain, sleep, and key overnight signals at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
