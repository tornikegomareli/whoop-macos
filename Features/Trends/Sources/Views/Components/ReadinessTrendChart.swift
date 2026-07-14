import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct ReadinessTrendChart: View {
    let snapshot: TrendsSnapshot

    @State private var selectedDate: Date?

    var body: some View {
        TrendChartSurface(
            title: "Recovery and sleep",
            symbol: "heart.fill",
            subtitle: subtitle
        ) {
            Chart {
                ForEach(snapshot.days) { day in
                    if let recovery = day.recoveryScore {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("Percentage", recovery),
                            series: .value("Metric", "Recovery")
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(by: .value("Metric", "Recovery"))

                        PointMark(
                            x: .value("Date", day.date),
                            y: .value("Percentage", recovery)
                        )
                        .foregroundStyle(by: .value("Metric", "Recovery"))
                        .symbolSize(20)
                    }

                    if let sleep = day.sleepPerformancePercentage {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("Percentage", sleep),
                            series: .value("Metric", "Sleep")
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(by: .value("Metric", "Sleep"))

                        PointMark(
                            x: .value("Date", day.date),
                            y: .value("Percentage", sleep)
                        )
                        .foregroundStyle(by: .value("Metric", "Sleep"))
                        .symbolSize(20)
                    }
                }

                if let selectedDay {
                    RuleMark(x: .value("Selected date", selectedDay.date))
                        .foregroundStyle(.secondary)
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartForegroundStyleScale([
                "Recovery": WhoopScopeTheme.recoveryGreen,
                "Sleep": WhoopScopeTheme.sleepPurple,
            ])
            .chartLegend(position: .top, alignment: .leading)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .trendDateAxis(snapshot)
            .chartXSelection(value: $selectedDate)
            .frame(minHeight: 250)
            .accessibilityLabel("Recovery and sleep performance trend")
        }
    }

    private var selectedDay: TrendDay? {
        snapshot.closestDay(to: selectedDate)
    }

    private var subtitle: String {
        guard let selectedDay, let date = selectedDatePrefix(selectedDay) else {
            return "Daily percentages reveal whether sleep and recovery are moving together"
        }
        let recovery = selectedDay.recoveryScore.map {
            "Recovery \(Int($0.rounded()))%"
        }
        let sleep = selectedDay.sleepPerformancePercentage.map {
            "Sleep \(Int($0.rounded()))%"
        }
        return ([date] + [recovery, sleep].compactMap { $0 }).joined(separator: " · ")
    }
}
