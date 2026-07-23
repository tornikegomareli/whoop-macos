import Charts
import SwiftUI
import WhoopScopeDomain

struct WorkoutDetailView: View {
    let workout: WhoopWorkout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(
                        workout.sportName.localizedCapitalized,
                        systemImage: "figure.run.circle.fill"
                    )
                    .font(.title2.bold())
                    Text(explorerDateAndTime(workout.start))
                        .foregroundStyle(.secondary)
                    Text(workout.end.timeIntervalSince(workout.start).explorerDuration)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let score = workout.score {
                    DetailSection(title: "Load") {
                        DetailValue("Strain", score.strain.explorerNumber)
                        DetailValue(
                            "Energy",
                            "\(Int(explorerKilocalories(score.kilojoules).rounded())) kcal"
                        )
                        DetailValue(
                            "Recorded",
                            score.percentRecorded.explorerRecordedPercent
                        )
                    }
                    DetailSection(title: "Heart rate") {
                        DetailValue("Average", "\(score.averageHeartRate) bpm")
                        DetailValue("Maximum", "\(score.maxHeartRate) bpm")
                    }
                    HeartRateZoneChart(zones: score.zoneDurations)

                    DetailSection(title: "Distance and elevation") {
                        DetailValue(
                            "Distance",
                            score.distanceMeters.map {
                                Measurement(value: $0, unit: UnitLength.meters)
                                    .formatted(.measurement(width: .abbreviated))
                            }
                        )
                        DetailValue(
                            "Altitude gain",
                            score.altitudeGainMeters.map {
                                Measurement(value: $0, unit: UnitLength.meters)
                                    .formatted(.measurement(width: .abbreviated))
                            }
                        )
                        DetailValue(
                            "Altitude change",
                            score.altitudeChangeMeters.map {
                                Measurement(value: $0, unit: UnitLength.meters)
                                    .formatted(.measurement(width: .abbreviated))
                            }
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "Not scored",
                        systemImage: "hourglass",
                        description: Text("WHOOP has not produced a score for this workout.")
                    )
                }

                DetailSection(title: "Record") {
                    DetailValue("Workout ID", workout.id.uuidString)
                    DetailValue("Score state", workout.scoreState.explorerTitle)
                    DetailValue("Sport ID", workout.sportID.map { String($0) })
                    DetailValue("Timezone", workout.timezoneOffset)
                    DetailValue("Updated", explorerDateAndTime(workout.updatedAt))
                }
            }
            .padding(20)
        }
    }
}

private struct HeartRateZoneChart: View {
    let zones: WhoopWorkout.ZoneDurations

    private var data: [HeartRateZone] {
        [
            .init(name: "Zone 0", milliseconds: zones.zoneZeroMilliseconds),
            .init(name: "Zone 1", milliseconds: zones.zoneOneMilliseconds),
            .init(name: "Zone 2", milliseconds: zones.zoneTwoMilliseconds),
            .init(name: "Zone 3", milliseconds: zones.zoneThreeMilliseconds),
            .init(name: "Zone 4", milliseconds: zones.zoneFourMilliseconds),
            .init(name: "Zone 5", milliseconds: zones.zoneFiveMilliseconds),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Heart rate zones")
                .font(.headline)
            Chart(data) { zone in
                BarMark(
                    x: .value("Zone", zone.name),
                    y: .value("Minutes", Double(zone.milliseconds) / 60_000)
                )
                .foregroundStyle(by: .value("Zone", zone.name))
            }
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(minHeight: 180)
            .accessibilityLabel("Minutes spent in heart rate zones zero through five")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

private struct HeartRateZone: Identifiable {
    var id: String { name }
    let name: String
    let milliseconds: Int64
}
