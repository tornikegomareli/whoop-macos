import SwiftUI

struct RecoveryDetailView: View {
    let record: RecoveryRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Recovery", systemImage: "heart.fill")
                        .font(.title2.bold())
                    Text(explorerDate(record.date))
                        .foregroundStyle(.secondary)
                }

                if let score = record.recovery.score {
                    DetailSection(title: "Readiness") {
                        DetailValue("Recovery", score.recoveryPercentage.explorerPercent)
                        DetailValue(
                            "Calibration",
                            score.isUserCalibrating ? "Calibrating" : "Calibrated"
                        )
                    }
                    DetailSection(title: "Cardiovascular") {
                        DetailValue(
                            "HRV",
                            score.hrvRMSSDMilliseconds.explorerNumber + " ms"
                        )
                        DetailValue(
                            "Resting heart rate",
                            score.restingHeartRate.explorerNumber + " bpm"
                        )
                        DetailValue(
                            "Blood oxygen",
                            score.spo2Percentage.map { $0.explorerPercent }
                        )
                        DetailValue(
                            "Skin temperature",
                            score.skinTemperatureCelsius.map {
                                $0.explorerNumber + " °C"
                            }
                        )
                    }
                } else {
                    ContentUnavailableView(
                        "Not scored",
                        systemImage: "hourglass",
                        description: Text("WHOOP has not produced a recovery score for this cycle.")
                    )
                }

                DetailSection(title: "Linked records") {
                    DetailValue("Cycle ID", "\(record.cycle.id)")
                    DetailValue("Sleep ID", record.recovery.sleepID.uuidString)
                    DetailValue("Cycle started", explorerDateAndTime(record.cycle.start))
                }
                DetailSection(title: "Record") {
                    DetailValue("Score state", record.recovery.scoreState.explorerTitle)
                    DetailValue("Updated", explorerDateAndTime(record.recovery.updatedAt))
                    DetailValue("Timezone", record.cycle.timezoneOffset)
                }
            }
            .padding(20)
        }
    }
}
