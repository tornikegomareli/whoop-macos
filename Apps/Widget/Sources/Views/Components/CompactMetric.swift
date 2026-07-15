import SwiftUI

struct CompactMetric: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 15)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(value)
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
