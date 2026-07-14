import Charts
import SwiftUI
import WhoopScopeDomain

struct HRVTrendChart: View {
    let snapshot: TrendsSnapshot

    @State private var selectedDate: Date?

    var body: some View {
        TrendChartSurface(
            title: "Heart rate variability",
            symbol: "waveform.path.ecg",
            subtitle: subtitle
        ) {
            Chart {
                ForEach(snapshot.days) { day in
                    if let value = day.heartRateVariabilityMilliseconds {
                        LineMark(
                            x: .value("Date", day.date),
                            y: .value("HRV in milliseconds", value)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.mint)

                        PointMark(
                            x: .value("Date", day.date),
                            y: .value("HRV in milliseconds", value)
                        )
                        .foregroundStyle(.mint)
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
            .accessibilityLabel("Heart rate variability trend in milliseconds")
        }
    }

    private var selectedDay: TrendDay? {
        snapshot.closestDay(to: selectedDate)
    }

    private var subtitle: String {
        guard
            let selectedDay,
            let date = selectedDatePrefix(selectedDay),
            let value = selectedDay.heartRateVariabilityMilliseconds
        else {
            return "Nightly variation in the timing between heartbeats"
        }
        return "\(date) · \(value.formatted(.number.precision(.fractionLength(1)))) ms"
    }
}
