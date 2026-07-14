import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct StrainTrendChart: View {
    let snapshot: TrendsSnapshot

    @State private var selectedDate: Date?

    var body: some View {
        TrendChartSurface(
            title: "Daily strain",
            symbol: "bolt.fill",
            subtitle: subtitle
        ) {
            Chart {
                ForEach(snapshot.days) { day in
                    if let strain = day.strainScore {
                        BarMark(
                            x: .value("Date", day.date),
                            y: .value("Day strain", strain)
                        )
                        .foregroundStyle(WhoopScopeTheme.strainBlue.gradient)
                        .clipShape(.rect(cornerRadius: 4))
                    }
                }

                if let selectedDay {
                    RuleMark(x: .value("Selected date", selectedDay.date))
                        .foregroundStyle(.secondary)
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartYScale(domain: 0...21)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 7, 14, 21]) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .trendDateAxis(snapshot)
            .chartXSelection(value: $selectedDate)
            .frame(minHeight: 230)
            .accessibilityLabel("Daily cardiovascular strain trend")
        }
    }

    private var selectedDay: TrendDay? {
        snapshot.closestDay(to: selectedDate)
    }

    private var subtitle: String {
        guard
            let selectedDay,
            let date = selectedDatePrefix(selectedDay),
            let strain = selectedDay.strainScore
        else {
            return "Your cardiovascular load for each day on WHOOP’s 0–21 scale"
        }
        return "\(date) · \(strain.formatted(.number.precision(.fractionLength(1)))) strain"
    }
}
