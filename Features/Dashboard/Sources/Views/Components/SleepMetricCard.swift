import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct SleepMetricCard: View {
    let sleep: SleepSummary

    var body: some View {
        MetricCard(
            title: "Sleep Performance",
            symbol: "moon.stars.fill",
            value: sleep.performancePercentage.formatted(),
            unit: "%",
            detail: "\(sleep.sleepAchieved.shortDescription) asleep · \(sleep.sleepNeed.shortDescription) recommended",
            tint: WhoopScopeTheme.sleepPurple,
            accessibilityValue: "\(sleep.performancePercentage) percent"
        )
    }
}
