import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

public struct MenuBarSummaryView: View {
    private let model: DashboardModel
    private let openDashboard: () -> Void

    public init(model: DashboardModel, openDashboard: @escaping () -> Void) {
        self.model = model
        self.openDashboard = openDashboard
    }

    public var body: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                MenuBarLoadingView()
            case let .loaded(snapshot):
                MenuBarLoadedView(
                    snapshot: snapshot,
                    isRefreshing: model.isRefreshing,
                    openDashboard: openDashboard,
                    refresh: refresh
                )
            case let .failed(message):
                MenuBarFailureView(message: message, retry: refresh)
            }
        }
        .task {
            await model.loadIfNeeded()
            await model.refreshIfStale()
        }
    }

    private func refresh() {
        Task { await model.refresh() }
    }
}

private struct MenuBarLoadedView: View {
    let snapshot: DashboardSnapshot
    let isRefreshing: Bool
    let openDashboard: () -> Void
    let refresh: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            header
            primaryMetrics
            detailStrip
            actions
        }
        .padding(20)
        .frame(width: 380)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image("MenuBarIcon", bundle: .main)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("Today")
                    .font(.headline)
                Text("Updated \(snapshot.lastSynchronizedAt, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Refreshing WHOOP data")
            } else {
                Button("Refresh", systemImage: "arrow.clockwise", action: refresh)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Refresh WHOOP data")
            }
        }
    }

    private var primaryMetrics: some View {
        HStack(alignment: .top, spacing: 14) {
            MenuBarMetric(
                title: "Recovery",
                value: "\(snapshot.recovery.score)%",
                symbol: "heart.fill",
                progress: Double(snapshot.recovery.score) / 100,
                tint: WhoopScopeTheme.recoveryColor(for: snapshot.recovery.score)
            )
            MenuBarMetric(
                title: "Day Strain",
                value: snapshot.strain.score.formatted(
                    .number.precision(.fractionLength(1))
                ),
                symbol: "bolt.fill",
                progress: snapshot.strain.score / 21,
                tint: WhoopScopeTheme.strainBlue
            )
            MenuBarMetric(
                title: "Sleep",
                value: "\(snapshot.sleep.performancePercentage)%",
                symbol: "moon.stars.fill",
                progress: Double(snapshot.sleep.performancePercentage) / 100,
                tint: WhoopScopeTheme.sleepPurple
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today's WHOOP scores")
    }

    private var detailStrip: some View {
        HStack(spacing: 0) {
            MenuBarDetail(
                title: "HRV",
                value: snapshot.recovery.heartRateVariabilityMilliseconds.formatted(
                    .number.precision(.fractionLength(1))
                ),
                unit: "ms"
            )
            Divider()
                .frame(height: 30)
            MenuBarDetail(
                title: "RHR",
                value: snapshot.recovery.restingHeartRate.formatted(),
                unit: "bpm"
            )
            Divider()
                .frame(height: 30)
            MenuBarDetail(
                title: "Slept",
                value: snapshot.sleep.sleepAchieved.shortDescription,
                unit: nil
            )
        }
        .padding(.vertical, 11)
        .background(.secondary.opacity(0.08), in: .rect(cornerRadius: 12))
    }

    private var actions: some View {
        Button("Open WhoopScope", systemImage: "arrow.up.forward.app", action: openDashboard)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .keyboardShortcut(.defaultAction)
    }
}

private struct MenuBarDetail: View {
    let title: String
    let value: String
    let unit: String?

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.callout.weight(.semibold))
                if let unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct MenuBarLoadingView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("MenuBarIcon", bundle: .main)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            ProgressView("Syncing your WHOOP data…")
                .controlSize(.small)
        }
        .padding(24)
        .frame(width: 320)
        .frame(minHeight: 150)
    }
}

private struct MenuBarFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("WHOOP data unavailable", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", systemImage: "arrow.clockwise", action: retry)
        }
        .padding()
        .frame(width: 340)
        .frame(minHeight: 210)
    }
}
