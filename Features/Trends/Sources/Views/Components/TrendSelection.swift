import Foundation
import WhoopScopeDomain

extension TrendsSnapshot {
    func closestDay(to date: Date?) -> TrendDay? {
        guard let date else { return nil }
        return days.min {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }
    }
}

func selectedDatePrefix(_ day: TrendDay?) -> String? {
    day?.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
}
