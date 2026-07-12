import Foundation
import Observation
import WhoopScopeDomain

@MainActor
@Observable
public final class DashboardModel {
    public private(set) var state: DashboardViewState = .idle
    public private(set) var isRefreshing = false

    private let loadDashboard: any LoadDashboardUseCase

    public init(loadDashboard: any LoadDashboardUseCase) {
        self.loadDashboard = loadDashboard
    }

    public var snapshot: DashboardSnapshot? {
        guard case let .loaded(snapshot) = state else { return nil }
        return snapshot
    }

    public func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        await load(preservingContent: true)
    }

    public func refreshIfStale(maximumAge: TimeInterval = 15 * 60) async {
        guard
            let snapshot,
            Date.now.timeIntervalSince(snapshot.lastSynchronizedAt) > maximumAge
        else { return }
        await refresh()
    }

    private func load(preservingContent: Bool = false) async {
        if !preservingContent {
            state = .loading
        }

        do {
            state = .loaded(try await loadDashboard.execute())
        } catch is CancellationError {
            if !preservingContent {
                state = .idle
            }
        } catch {
            if !preservingContent || snapshot == nil {
                state = .failed(
                    message: "WhoopScope couldn’t load your dashboard. Please try again."
                )
            }
        }
    }
}
