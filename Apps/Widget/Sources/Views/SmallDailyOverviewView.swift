import SwiftUI
import WhoopScopeWidgetSupport

struct SmallDailyOverviewView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 12) {
            WidgetBrandHeader(
                synchronizedAt: snapshot.synchronizedAt,
                showsUpdatedText: false
            )

            HStack(alignment: .top, spacing: 8) {
                MetricRing(
                    title: "Recovery",
                    value: "\(snapshot.recoveryScore)%",
                    progress: Double(snapshot.recoveryScore) / 100,
                    color: WidgetPalette.recovery(for: snapshot.recoveryScore)
                )
                MetricRing(
                    title: "Strain",
                    value: snapshot.strainScore.formatted(
                        .number.precision(.fractionLength(1))
                    ),
                    progress: snapshot.strainScore / 21,
                    color: WidgetPalette.strain
                )
                MetricRing(
                    title: "Sleep",
                    value: "\(snapshot.sleepPerformancePercentage)%",
                    progress: Double(snapshot.sleepPerformancePercentage) / 100,
                    color: WidgetPalette.sleep
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Today's WHOOP scores")

            Text("Updated \(snapshot.synchronizedAt, style: .relative)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
