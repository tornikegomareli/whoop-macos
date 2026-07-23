import Foundation
import WhoopScopeDomain

extension Double {
    var explorerNumber: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }

    var explorerPercent: String {
        "\(formatted(.number.precision(.fractionLength(0...1))))%"
    }

    var explorerRecordedPercent: String {
        let percentage = self <= 1 ? self * 100 : self
        return percentage.explorerPercent
    }
}

extension TimeInterval {
    var explorerDuration: String {
        let totalMinutes = max(0, Int((self / 60).rounded()))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 {
            return "\(minutes)m"
        }
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
}

extension Int64 {
    var explorerHours: Double {
        Double(self) / 3_600_000
    }
}

extension WhoopScoreState {
    var explorerTitle: String {
        switch self {
        case .scored: "Scored"
        case .pending: "Pending"
        case .unscorable: "Unscorable"
        }
    }
}

func explorerKilocalories(_ kilojoules: Double) -> Double {
    kilojoules / 4.184
}

func explorerDate(_ date: Date) -> String {
    date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
}

func explorerDateAndTime(_ date: Date) -> String {
    date.formatted(
        .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()
    )
}
