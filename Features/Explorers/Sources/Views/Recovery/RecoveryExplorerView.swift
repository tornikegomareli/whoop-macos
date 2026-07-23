import SwiftUI
import WhoopScopeDomain

public struct RecoveryExplorerView: View {
    private let model: ExplorerModel

    public init(model: ExplorerModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                ProgressView("Preparing your recovery history…")
                    .controlSize(.large)
            case let .loaded(snapshot):
                RecoveryExplorerContentView(
                    snapshot: snapshot,
                    selectedRange: model.selectedRange,
                    isRefreshing: model.isRefreshing,
                    selectRange: model.selectRange,
                    refresh: refresh
                )
            case let .failed(message):
                ContentUnavailableView {
                    Label("Recovery history unavailable", systemImage: "heart.text.square")
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

    private func refresh() {
        Task { await model.refresh() }
    }
}
