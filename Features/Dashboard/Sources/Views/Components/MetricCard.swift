import SwiftUI
import WhoopScopeDesignSystem

struct MetricCard: View {
    let title: String
    let symbol: String
    let value: String
    let unit: String
    let detail: String
    let tint: Color
    let accessibilityValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
    }
}
