import SwiftUI

struct MenuBarMetric: View {
    let title: String
    let value: String
    let symbol: String
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                Circle()
                    .stroke(tint.opacity(0.14), lineWidth: 7)

                Circle()
                    .trim(from: 0, to: normalizedProgress)
                    .stroke(
                        tint.gradient,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Image(systemName: symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)

                    Text(value)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                }
            }
            .frame(width: 76, height: 76)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var normalizedProgress: Double {
        min(max(progress, 0), 1)
    }
}
