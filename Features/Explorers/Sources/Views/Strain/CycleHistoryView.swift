import SwiftUI
import WhoopScopeDomain

struct CycleHistoryView: View {
    let cycles: [WhoopCycle]
    let selectCycle: (WhoopCycle) -> Void

    var body: some View {
        ExplorerHistorySurface(
            title: "Cycle history",
            description: "Select a cycle to inspect timing, heart rate, energy, and record state"
        ) {
            if cycles.isEmpty {
                Text("No cycles in this range.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 18)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(cycles) { cycle in
                        Button {
                            selectCycle(cycle)
                        } label: {
                            CycleHistoryRow(cycle: cycle)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }
}

private struct CycleHistoryRow: View {
    let cycle: WhoopCycle

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "bolt.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(explorerDate(cycle.start))
                    .font(.headline)
                Text(cycleDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            CycleRowValue(
                title: "Strain",
                value: cycle.score?.strain.explorerNumber ?? "—"
            )
            CycleRowValue(
                title: "Avg HR",
                value: cycle.score.map { "\($0.averageHeartRate) bpm" } ?? "—"
            )
            CycleRowValue(
                title: "Energy",
                value: cycle.score.map {
                    "\(Int(explorerKilocalories($0.kilojoules).rounded())) kcal"
                } ?? "—"
            )

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens complete cycle details")
    }

    private var cycleDuration: String {
        guard let end = cycle.end else {
            return "\(cycle.scoreState.explorerTitle) · In progress"
        }
        return "\(cycle.scoreState.explorerTitle) · \(end.timeIntervalSince(cycle.start).explorerDuration)"
    }
}

private struct CycleRowValue: View {
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
