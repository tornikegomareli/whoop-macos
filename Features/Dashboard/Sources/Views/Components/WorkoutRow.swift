import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct WorkoutRow: View {
    let workout: WorkoutSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundStyle(WhoopScopeTheme.strainBlue)
                .frame(width: 34, height: 34)
                .background(WhoopScopeTheme.strainBlue.opacity(0.12))
                .clipShape(.circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(workout.activityName)
                    .font(.body)
                    .bold()

                Label(workout.duration.workoutDescription, systemImage: "clock")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(workout.strainScore, format: .number.precision(.fractionLength(1)))
                    .font(.headline)

                Text("workout strain")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}
