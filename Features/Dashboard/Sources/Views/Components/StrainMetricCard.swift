import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct StrainMetricCard: View {
    let strain: StrainSummary

    var body: some View {
        MetricCard(
            title: "Day Strain",
            symbol: "bolt.fill",
            value: strain.score.formatted(.number.precision(.fractionLength(1))),
            unit: "/ 21",
            detail: "\(strain.kilocalories.formatted()) calories burned · \(strain.averageHeartRate.formatted()) bpm average heart rate",
            tint: WhoopScopeTheme.strainBlue,
            accessibilityValue: "\(strain.score.formatted(.number.precision(.fractionLength(1)))) out of 21"
        )
    }
}
