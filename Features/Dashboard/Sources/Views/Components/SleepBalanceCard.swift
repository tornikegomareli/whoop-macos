import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct SleepBalanceCard: View {
    let sleep: SleepSummary

    private var progress: Double {
        guard sleep.sleepNeed > .zero else { return 0 }
        return min(
            Double(sleep.sleepAchieved.components.seconds)
                / Double(sleep.sleepNeed.components.seconds),
            1
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Sleep goal", systemImage: "bed.double.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(sleep.sleepAchieved.shortDescription)
                        .font(.title2)
                        .bold()

                    Spacer()

                    Text("Goal \(sleep.sleepNeed.shortDescription)")
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progress)
                    .tint(WhoopScopeTheme.sleepPurple)
                    .accessibilityLabel("Sleep need achieved")
                    .accessibilityValue("\(sleep.performancePercentage) percent")
            }

            Divider()

            LabeledContent("Sleep schedule consistency") {
                Text(sleep.consistencyPercentage, format: .percent.scale(1))
                    .bold()
            }

            Text("How regularly your sleep and wake times follow the same schedule.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
