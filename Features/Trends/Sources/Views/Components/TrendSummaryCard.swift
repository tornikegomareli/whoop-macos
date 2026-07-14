import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct TrendSummaryCard: View {
    let title: String
    let symbol: String
    let value: String
    let unit: String
    let comparison: String
    let sampleCount: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(comparison)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text("Based on \(sampleCount) scored \(sampleCount == 1 ? "day" : "days")")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

extension TrendSummaryCard {
    static func recovery(_ snapshot: TrendsSnapshot) -> Self {
        make(
            title: "Average recovery",
            symbol: "heart.fill",
            summary: snapshot.recovery,
            unit: "%",
            changeUnit: "points",
            tint: WhoopScopeTheme.recoveryGreen
        )
    }

    static func strain(_ snapshot: TrendsSnapshot) -> Self {
        make(
            title: "Average strain",
            symbol: "bolt.fill",
            summary: snapshot.strain,
            unit: "/ 21",
            changeUnit: "strain",
            tint: WhoopScopeTheme.strainBlue
        )
    }

    static func sleep(_ snapshot: TrendsSnapshot) -> Self {
        make(
            title: "Average sleep",
            symbol: "moon.stars.fill",
            summary: snapshot.sleepPerformance,
            unit: "%",
            changeUnit: "points",
            tint: WhoopScopeTheme.sleepPurple
        )
    }

    static func hrv(_ snapshot: TrendsSnapshot) -> Self {
        make(
            title: "Average HRV",
            symbol: "waveform.path.ecg",
            summary: snapshot.heartRateVariability,
            unit: "ms",
            changeUnit: "ms",
            tint: .mint
        )
    }

    static func restingHeartRate(_ snapshot: TrendsSnapshot) -> Self {
        make(
            title: "Average resting heart rate",
            symbol: "heart.text.square.fill",
            summary: snapshot.restingHeartRate,
            unit: "bpm",
            changeUnit: "bpm",
            tint: .pink
        )
    }

    private static func make(
        title: String,
        symbol: String,
        summary: TrendMetricSummary,
        unit: String,
        changeUnit: String,
        tint: Color
    ) -> Self {
        Self(
            title: title,
            symbol: symbol,
            value: summary.currentAverage?.formatted(
                .number.precision(.fractionLength(1))
            ) ?? "—",
            unit: unit,
            comparison: comparisonDescription(summary, unit: changeUnit),
            sampleCount: summary.currentSampleCount,
            tint: tint
        )
    }

    private static func comparisonDescription(
        _ summary: TrendMetricSummary,
        unit: String
    ) -> String {
        guard let change = summary.change else {
            return "Previous period unavailable"
        }
        if abs(change) < 0.05 {
            return "About the same as the previous period"
        }
        let direction = change > 0 ? "higher" : "lower"
        let magnitude = abs(change).formatted(.number.precision(.fractionLength(1)))
        return "\(magnitude) \(unit) \(direction) than the previous period"
    }
}
