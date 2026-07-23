import SwiftUI
import WhoopScopeDesignSystem

struct RecoveryHistoryView: View {
    let recoveries: [RecoveryRecord]
    let selectRecovery: (RecoveryRecord) -> Void

    var body: some View {
        ExplorerHistorySurface(
            title: "Recovery history",
            description: "Select a day to inspect every readiness input WHOOP supplied"
        ) {
            if recoveries.isEmpty {
                Text("No recovery records in this range.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 18)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(recoveries) { record in
                        Button {
                            selectRecovery(record)
                        } label: {
                            RecoveryHistoryRow(record: record)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }
}

private struct RecoveryHistoryRow: View {
    let record: RecoveryRecord

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(recoveryColor)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(explorerDate(record.date))
                    .font(.headline)
                Text(record.recovery.scoreState.explorerTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RecoveryRowValue(
                title: "Recovery",
                value: record.recovery.score.map { $0.recoveryPercentage.explorerPercent } ?? "—"
            )
            RecoveryRowValue(
                title: "HRV",
                value: record.recovery.score.map {
                    $0.hrvRMSSDMilliseconds.explorerNumber + " ms"
                } ?? "—"
            )
            RecoveryRowValue(
                title: "RHR",
                value: record.recovery.score.map {
                    $0.restingHeartRate.explorerNumber + " bpm"
                } ?? "—"
            )

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens complete recovery details")
    }

    private var recoveryColor: Color {
        guard let score = record.recovery.score?.recoveryPercentage else {
            return .secondary
        }
        return WhoopScopeTheme.recoveryColor(for: Int(score.rounded()))
    }
}

private struct RecoveryRowValue: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 96, alignment: .trailing)
    }
}
