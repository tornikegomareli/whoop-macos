import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct SleepDetailView: View {
    let sleep: WhoopSleep

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(
                        sleep.isNap ? "Nap" : "Main sleep",
                        systemImage: sleep.isNap ? "sun.haze.fill" : "moon.stars.fill"
                    )
                    .font(.title2.bold())
                    Text(explorerDateAndTime(sleep.start))
                        .foregroundStyle(.secondary)
                    Text("\(sleep.start.formatted(date: .omitted, time: .shortened))–\(sleep.end.formatted(date: .omitted, time: .shortened))")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let score = sleep.score {
                    DetailSection(title: "Quality") {
                        DetailValue("Performance", score.performancePercentage?.explorerPercent)
                        DetailValue("Efficiency", score.efficiencyPercentage?.explorerPercent)
                        DetailValue("Consistency", score.consistencyPercentage?.explorerPercent)
                        DetailValue(
                            "Respiratory rate",
                            score.respiratoryRate.map { "\($0.explorerNumber) rpm" }
                        )
                    }
                    DetailSection(title: "Sleep stages") {
                        DetailValue(
                            "Time in bed",
                            score.stageSummary.totalInBedMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Time asleep",
                            score.stageSummary.achievedSleepMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Awake",
                            score.stageSummary.totalAwakeMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Light sleep",
                            score.stageSummary.totalLightSleepMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Slow wave",
                            score.stageSummary.totalSlowWaveSleepMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "REM",
                            score.stageSummary.totalREMSleepMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "No data",
                            score.stageSummary.totalNoDataMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue("Sleep cycles", "\(score.stageSummary.sleepCycleCount)")
                        DetailValue("Disturbances", "\(score.stageSummary.disturbanceCount)")
                    }
                    DetailSection(title: "Sleep need") {
                        DetailValue(
                            "Baseline",
                            score.sleepNeeded.baselineMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Sleep debt",
                            score.sleepNeeded.fromSleepDebtMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Recent strain",
                            score.sleepNeeded.fromRecentStrainMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Recent naps",
                            score.sleepNeeded.fromRecentNapMilliseconds.explorerHours.explorerNumber + "h"
                        )
                        DetailValue(
                            "Total need",
                            score.sleepNeeded.totalMilliseconds.explorerHours.explorerNumber + "h"
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "Not scored",
                        systemImage: "hourglass",
                        description: Text("WHOOP has not produced a score for this sleep record.")
                    )
                }

                DetailSection(title: "Record") {
                    DetailValue("Sleep ID", sleep.id.uuidString)
                    DetailValue("Score state", sleep.scoreState.explorerTitle)
                    DetailValue("Cycle ID", "\(sleep.cycleID)")
                    DetailValue("Timezone", sleep.timezoneOffset)
                    DetailValue("Updated", explorerDateAndTime(sleep.updatedAt))
                }
            }
            .padding(20)
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

struct DetailValue: View {
    let title: String
    let value: String

    init(_ title: String, _ value: String?) {
        self.title = title
        self.value = value ?? "—"
    }

    var body: some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
