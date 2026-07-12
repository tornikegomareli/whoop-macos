import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct StrainLoadCard: View {
    let history: [DailyMetrics]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Strain load", systemImage: "chart.bar.fill")
                    .font(.headline)

                Text("How much cardiovascular load you took on each day over the last 14 days")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Chart(history) { point in
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Strain", point.strainScore)
                )
                .foregroundStyle(WhoopScopeTheme.strainBlue.gradient)
                .clipShape(.rect(cornerRadius: 4))
            }
            .chartYScale(domain: 0...21)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 7, 14, 21])
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .frame(minHeight: 210)
            .accessibilityLabel("Fourteen-day strain chart")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
