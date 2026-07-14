import Foundation
import Observation
import WhoopScopeDomain

@MainActor
@Observable
public final class TrendsModel {
    public private(set) var state: TrendsViewState = .idle
    public private(set) var selectedRange: TrendRange
    public private(set) var isRefreshing = false

    private let loadTrends: any LoadTrendsUseCase
    private var requestID = 0

    public init(
        loadTrends: any LoadTrendsUseCase,
        selectedRange: TrendRange = .thirtyDays
    ) {
        self.loadTrends = loadTrends
        self.selectedRange = selectedRange
    }

    public var snapshot: TrendsSnapshot? {
        guard case let .loaded(snapshot) = state else { return nil }
        return snapshot
    }

    public func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load(range: selectedRange, refresh: false, preservingContent: false)
    }

    public func selectRange(_ range: TrendRange) async {
        guard range != selectedRange else { return }
        selectedRange = range
        await load(range: range, refresh: false, preservingContent: snapshot != nil)
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        await load(
            range: selectedRange,
            refresh: true,
            preservingContent: snapshot != nil
        )
    }

    private func load(
        range: TrendRange,
        refresh: Bool,
        preservingContent: Bool
    ) async {
        requestID += 1
        let currentRequestID = requestID
        if preservingContent {
            isRefreshing = true
        } else {
            state = .loading
        }
        defer {
            if currentRequestID == requestID {
                isRefreshing = false
            }
        }

        do {
            let snapshot = try await loadTrends.execute(range: range, refresh: refresh)
            guard currentRequestID == requestID else { return }
            state = .loaded(snapshot)
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
            if !preservingContent {
                state = .idle
            }
        } catch {
            guard currentRequestID == requestID else { return }
            if !preservingContent || snapshot == nil {
                state = .failed(
                    message: "WhoopScope couldn’t load your trends. Please try again."
                )
            }
        }
    }
}
