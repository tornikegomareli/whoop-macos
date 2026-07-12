import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct RecoveryMetricCard: View {
    let recovery: RecoverySummary

    var body: some View {
        MetricCard(
            title: "Recovery",
            symbol: "heart.fill",
            value: recovery.score.formatted(),
            unit: "%",
            detail: "Heart rate variability \(recovery.heartRateVariabilityMilliseconds.formatted(.number.precision(.fractionLength(1)))) ms · Resting heart rate \(recovery.restingHeartRate.formatted()) bpm",
            tint: WhoopScopeTheme.recoveryColor(for: recovery.score),
            accessibilityValue: "\(recovery.score) percent"
        )
    }
}
