import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct ExplorerHeaderView: View {
    let title: String
    let description: String
    let snapshot: ExplorerSnapshot
    let selectedRange: TrendRange
    let isRefreshing: Bool
    let selectRange: (TrendRange) -> Void
    let refresh: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.bold())
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(
                    "\(snapshot.startDate.formatted(.dateTime.month(.abbreviated).day()))–\(snapshot.endDate.formatted(.dateTime.month(.abbreviated).day().year())) · Updated \(snapshot.lastSynchronizedAt, style: .relative)"
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Time range", selection: rangeBinding) {
                ForEach(TrendRange.allCases) { range in
                    Text(range.shortTitle).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .accessibilityHint("Changes the period shown across every explorer")

            Button("Refresh", systemImage: "arrow.clockwise", action: refresh)
                .disabled(isRefreshing)
        }
    }

    private var rangeBinding: Binding<TrendRange> {
        Binding(
            get: { selectedRange },
            set: selectRange
        )
    }
}

struct ExplorerMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let explanation: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

struct ExplorerSectionHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title2.bold())
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExplorerChartSurface<Content: View>: View {
    let title: String
    let symbol: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

struct ExplorerHistorySurface<Content: View>: View {
    let title: String
    let description: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)

            Divider()
            content
        }
        .cardSurface()
    }
}

extension View {
    func explorerPageBackground(tint: Color) -> some View {
        background {
            LinearGradient(
                colors: [tint.opacity(0.10), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}
