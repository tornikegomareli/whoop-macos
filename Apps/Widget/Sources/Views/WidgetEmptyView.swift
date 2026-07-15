import SwiftUI

struct WidgetEmptyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image("WidgetMark")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)

                Text("WhoopScope")
                    .font(.headline)
            }

            Spacer(minLength: 0)

            Text("Open WhoopScope to sync your latest WHOOP data.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Label("Waiting for data", systemImage: "arrow.clockwise")
                .font(.caption.weight(.medium))
                .foregroundStyle(WidgetPalette.strain)
        }
        .accessibilityElement(children: .combine)
    }
}
