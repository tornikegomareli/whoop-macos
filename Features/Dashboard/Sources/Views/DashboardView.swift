import SwiftUI

public struct DashboardView: View {
    private let model: DashboardModel

    public init(model: DashboardModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                ProgressView("Preparing your dashboard…")
                    .controlSize(.large)
            case let .loaded(snapshot):
                DashboardContentView(
                    snapshot: snapshot,
                    isRefreshing: model.isRefreshing,
                    refresh: refresh
                )
            case let .failed(message):
                ContentUnavailableView {
                    Label("Dashboard unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again", systemImage: "arrow.clockwise", action: retry)
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

    private func retry() {
        Task { await model.refresh() }
    }
}

