import SwiftUI
import WhoopScopeDomain

struct CycleDetailView: View {
    let cycle: WhoopCycle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("WHOOP cycle", systemImage: "bolt.circle.fill")
                        .font(.title2.bold())
                    Text(explorerDateAndTime(cycle.start))
                        .foregroundStyle(.secondary)
                    Text(duration)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let score = cycle.score {
                    DetailSection(title: "Load") {
                        DetailValue("Strain", score.strain.explorerNumber)
                        DetailValue(
                            "Energy",
                            "\(Int(explorerKilocalories(score.kilojoules).rounded())) kcal"
                        )
                    }
                    DetailSection(title: "Heart rate") {
                        DetailValue("Average", "\(score.averageHeartRate) bpm")
                        DetailValue("Maximum", "\(score.maxHeartRate) bpm")
                    }
                } else {
                    ContentUnavailableView(
                        "Not scored",
                        systemImage: "hourglass",
                        description: Text("WHOOP has not produced a score for this cycle.")
                    )
                }

                DetailSection(title: "Timing") {
                    DetailValue("Started", explorerDateAndTime(cycle.start))
                    DetailValue("Ended", cycle.end.map(explorerDateAndTime))
                    DetailValue("Duration", duration)
                    DetailValue("Timezone", cycle.timezoneOffset)
                }
                DetailSection(title: "Record") {
                    DetailValue("Cycle ID", "\(cycle.id)")
                    DetailValue("Score state", cycle.scoreState.explorerTitle)
                    DetailValue("Updated", explorerDateAndTime(cycle.updatedAt))
                }
            }
            .padding(20)
        }
    }

    private var duration: String {
        guard let end = cycle.end else { return "In progress" }
        return end.timeIntervalSince(cycle.start).explorerDuration
    }
}
