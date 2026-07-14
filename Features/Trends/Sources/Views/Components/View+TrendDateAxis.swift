import Charts
import SwiftUI
import WhoopScopeDomain

extension View {
    func trendDateAxis(_ snapshot: TrendsSnapshot) -> some View {
        let firstDate = snapshot.days.first?.date ?? snapshot.startDate
        let lastDate = snapshot.days.last?.date ?? snapshot.endDate
        let domainEnd = lastDate > firstDate
            ? lastDate
            : firstDate.addingTimeInterval(24 * 60 * 60)

        return chartXScale(domain: firstDate...domainEnd)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
    }
}
