import Foundation
import Observation
import WhoopScopeDomain

@MainActor
@Observable
public final class ExplorerModel {
    public private(set) var state: ExplorerViewState = .idle
    public private(set) var selectedRange: TrendRange
    public private(set) var isRefreshing = false

    private let loadExplorer: any LoadExplorerUseCase
    private let now: @Sendable () -> Date
    private var archive: WhoopDataArchive?
    private var requestID = 0

    public init(
        loadExplorer: any LoadExplorerUseCase,
        selectedRange: TrendRange = .thirtyDays,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.loadExplorer = loadExplorer
        self.selectedRange = selectedRange
        self.now = now
    }

    public var snapshot: ExplorerSnapshot? {
        guard case let .loaded(snapshot) = state else { return nil }
        return snapshot
    }

    public func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load(refresh: false, preservingContent: false)
    }

    public func selectRange(_ range: TrendRange) {
        guard range != selectedRange else { return }
        selectedRange = range
        rebuildSnapshot()
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        await load(refresh: true, preservingContent: snapshot != nil)
    }

    private func load(refresh: Bool, preservingContent: Bool) async {
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
            let archive = try await loadExplorer.execute(refresh: refresh)
            guard currentRequestID == requestID else { return }
            self.archive = archive
            rebuildSnapshot()
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
            if !preservingContent {
                state = .idle
            }
        } catch {
            guard currentRequestID == requestID else { return }
            if !preservingContent || snapshot == nil {
                state = .failed(
                    message: "WhoopScope couldn’t load your WHOOP history. Please try again."
                )
            }
        }
    }

    private func rebuildSnapshot() {
        guard let archive else { return }
        do {
            state = .loaded(
                try ExplorerSnapshotBuilder.build(
                    from: archive,
                    range: selectedRange,
                    now: now()
                )
            )
        } catch {
            state = .failed(
                message: "WhoopScope couldn’t prepare this date range. Please try again."
            )
        }
    }
}
