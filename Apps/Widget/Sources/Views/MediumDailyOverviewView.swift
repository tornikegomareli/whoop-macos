import SwiftUI
import WhoopScopeWidgetSupport

struct MediumDailyOverviewView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 9) {
            WidgetBrandHeader(synchronizedAt: snapshot.synchronizedAt)

            HStack(spacing: 14) {
                MetricRing(
                    title: "Recovery",
                    value: "\(snapshot.recoveryScore)%",
                    progress: Double(snapshot.recoveryScore) / 100,
                    color: WidgetPalette.recovery(for: snapshot.recoveryScore),
                    lineWidth: 7
                )
                .frame(width: 76)

                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        CompactMetric(
                            title: "Day strain",
                            value: snapshot.strainScore.formatted(
                                .number.precision(.fractionLength(1))
                            ),
                            symbol: "bolt.fill",
                            color: WidgetPalette.strain
                        )
                        CompactMetric(
                            title: "Sleep",
                            value: "\(snapshot.sleepPerformancePercentage)%",
                            symbol: "moon.stars.fill",
                            color: WidgetPalette.sleep
                        )
                    }

                    HStack(spacing: 12) {
                        MiniStat(
                            title: "HRV",
                            value: "\(formattedHRV) ms"
                        )
                        MiniStat(
                            title: "RHR",
                            value: "\(snapshot.restingHeartRate) bpm"
                        )
                        MiniStat(
                            title: "Asleep",
                            value: formattedSleepDuration
                        )
                    }
                }
            }
        }
    }

    private var formattedHRV: String {
        snapshot.heartRateVariabilityMilliseconds.formatted(
            .number.precision(.fractionLength(1))
        )
    }

    private var formattedSleepDuration: String {
        let totalMinutes = snapshot.sleepAchievedSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}
