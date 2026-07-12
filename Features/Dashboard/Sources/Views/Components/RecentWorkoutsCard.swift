import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct RecentWorkoutsCard: View {
    let workouts: [WorkoutSummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Recent workouts", systemImage: "figure.run")
                    .font(.headline)

                Spacer()

                Text("Last 7 days")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if workouts.isEmpty {
                ContentUnavailableView(
                    "No workouts yet",
                    systemImage: "figure.run",
                    description: Text("Your WHOOP workouts will appear here after synchronization.")
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(workouts) { workout in
                        WorkoutRow(workout: workout)

                        if workout.id != workouts.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
