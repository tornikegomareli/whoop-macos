import SwiftUI
import WhoopScopeDomain

struct SleepHistoryView: View {
    let sleeps: [WhoopSleep]
    let selectSleep: (WhoopSleep) -> Void

    var body: some View {
        ExplorerHistorySurface(
            title: "Sleep history",
            description: "Select any record to inspect stages, need, and timing"
        ) {
            if sleeps.isEmpty {
                Text("No sleep records in this range.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 18)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(sleeps) { sleep in
                        Button {
                            selectSleep(sleep)
                        } label: {
                            SleepHistoryRow(sleep: sleep)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }
}

private struct SleepHistoryRow: View {
    let sleep: WhoopSleep

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: sleep.isNap ? "sun.haze.fill" : "moon.stars.fill")
                .font(.title3)
                .foregroundStyle(sleep.isNap ? .orange : .purple)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(sleep.isNap ? "Nap" : explorerDate(sleep.start))
                    .font(.headline)
                Text(
                    "\(sleep.start.formatted(date: .omitted, time: .shortened))–\(sleep.end.formatted(date: .omitted, time: .shortened)) · \(sleep.end.timeIntervalSince(sleep.start).explorerDuration) in bed"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SleepRowValue(
                title: "Asleep",
                value: sleep.score.map {
                    $0.stageSummary.achievedSleepMilliseconds.explorerHours.explorerNumber + "h"
                } ?? "—"
            )
            SleepRowValue(
                title: "Performance",
                value: sleep.score?.performancePercentage?.explorerPercent ?? "—"
            )
            SleepRowValue(
                title: "Efficiency",
                value: sleep.score?.efficiencyPercentage?.explorerPercent ?? "—"
            )

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens complete sleep details")
    }
}

private struct SleepRowValue: View {
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
        .frame(width: 92, alignment: .trailing)
    }
}
