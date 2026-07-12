import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct RecoveryTrendCard: View {
    let history: [DailyMetrics]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Recovery trend", systemImage: "chart.xyaxis.line")
                    .font(.headline)

                Text("How ready your body has been each day over the last 14 days")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Chart(history) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Recovery", point.recoveryScore)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            WhoopScopeTheme.recoveryGreen.opacity(0.28),
                            WhoopScopeTheme.recoveryGreen.opacity(0.02),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Recovery", point.recoveryScore)
                )
                .foregroundStyle(WhoopScopeTheme.recoveryGreen)
                .lineStyle(.init(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Recovery", point.recoveryScore)
                )
                .foregroundStyle(WhoopScopeTheme.recoveryColor(for: point.recoveryScore))
                .symbolSize(24)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 33, 66, 100])
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .frame(minHeight: 210)
            .accessibilityLabel("Fourteen-day recovery trend")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
