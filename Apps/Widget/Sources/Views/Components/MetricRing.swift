import SwiftUI

struct MetricRing: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    var lineWidth = 5.0

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.10), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(value)
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .aspectRatio(1, contentMode: .fit)

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
