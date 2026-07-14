import SwiftUI
import WhoopScopeDomain

public struct TrendsView: View {
    private let model: TrendsModel

    public init(model: TrendsModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                ProgressView("Preparing your trends…")
                    .controlSize(.large)
            case let .loaded(snapshot):
                TrendsContentView(
                    snapshot: snapshot,
                    selectedRange: model.selectedRange,
                    isRefreshing: model.isRefreshing,
                    selectRange: selectRange,
                    refresh: refresh
                )
            case let .failed(message):
                ContentUnavailableView {
                    Label("Trends unavailable", systemImage: "chart.xyaxis.line")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again", systemImage: "arrow.clockwise", action: refresh)
                }
            }
        }
        .task {
            await model.loadIfNeeded()
        }
    }

    private func selectRange(_ range: TrendRange) {
        Task { await model.selectRange(range) }
    }

    private func refresh() {
        Task { await model.refresh() }
    }
}
