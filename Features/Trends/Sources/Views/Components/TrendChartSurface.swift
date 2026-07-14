import SwiftUI
import WhoopScopeDesignSystem

struct TrendChartSurface<Content: View>: View {
    let title: String
    let symbol: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(
        title: String,
        symbol: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: symbol)
                    .font(.headline)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
