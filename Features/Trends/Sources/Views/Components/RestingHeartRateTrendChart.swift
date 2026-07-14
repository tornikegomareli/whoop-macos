import Charts
import SwiftUI
import WhoopScopeDomain

struct RestingHeartRateTrendChart: View {
    let snapshot: TrendsSnapshot

    @State private var selectedDate: Date?

    var body: some View {
        TrendChartSurface(
            title: "Resting heart rate",
            symbol: "heart.text.square.fill",
            subtitle: subtitle
        ) {
            Chart {
                ForEach(snapshot.days) { day in
                    if let value = day.restingHeartRate {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("Resting heart rate in beats per minute", value)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.pink)

                        PointMark(
                            x: .value("Date", day.date),
                            y: .value("Resting heart rate in beats per minute", value)
                        )
                        .foregroundStyle(.pink)
                        .symbolSize(18)
                    }
                }

                if let selectedDay {
                    RuleMark(x: .value("Selected date", selectedDay.date))
                        .foregroundStyle(.secondary)
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .trendDateAxis(snapshot)
            .chartXSelection(value: $selectedDate)
            .frame(minHeight: 220)
            .accessibilityLabel("Resting heart rate trend in beats per minute")
        }
    }

    private var selectedDay: TrendDay? {
        snapshot.closestDay(to: selectedDate)
    }

    private var subtitle: String {
        guard
            let selectedDay,
            let date = selectedDatePrefix(selectedDay),
            let value = selectedDay.restingHeartRate
        else {
            return "Your heart rate while your body is at rest"
        }
        return "\(date) · \(Int(value.rounded())) bpm"
    }
}
