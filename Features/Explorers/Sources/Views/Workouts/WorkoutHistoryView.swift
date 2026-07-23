import SwiftUI
import WhoopScopeDomain

struct WorkoutHistoryView: View {
    let workouts: [WhoopWorkout]
    let selectWorkout: (WhoopWorkout) -> Void

    var body: some View {
        ExplorerHistorySurface(
            title: "Workout history",
            description: "Select an activity to inspect heart rate zones and every recorded field"
        ) {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "No matching workouts",
                    systemImage: "magnifyingglass",
                    description: Text("Try another activity or search term.")
                )
                    .padding(.vertical, 18)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(workouts) { workout in
                        Button {
                            selectWorkout(workout)
                        } label: {
                            WorkoutHistoryRow(workout: workout)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
    }
}

private struct WorkoutHistoryRow: View {
    let workout: WhoopWorkout

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.run.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(workout.sportName.localizedCapitalized)
                    .font(.headline)
                Text(
                    "\(explorerDateAndTime(workout.start)) · \(workout.end.timeIntervalSince(workout.start).explorerDuration)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            WorkoutRowValue(
                title: "Strain",
                value: workout.score?.strain.explorerNumber ?? "—"
            )
            WorkoutRowValue(
                title: "Avg HR",
                value: workout.score.map { "\($0.averageHeartRate) bpm" } ?? "—"
            )
            WorkoutRowValue(
                title: "Energy",
                value: workout.score.map {
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
        .accessibilityHint("Opens complete workout details")
    }
}

private struct WorkoutRowValue: View {
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
