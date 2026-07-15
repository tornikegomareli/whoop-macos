import SwiftUI

struct WidgetBrandHeader: View {
    let synchronizedAt: Date
    var showsUpdatedText = true

    var body: some View {
        HStack(spacing: 6) {
            Image("WidgetMark")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 17, height: 17)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            Text("WhoopScope")
                .font(.caption.weight(.semibold))

            Spacer(minLength: 4)

            if showsUpdatedText {
                Text(synchronizedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}
