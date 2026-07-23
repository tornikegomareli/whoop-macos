import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct RecoveryExplorerContentView: View {
    let snapshot: ExplorerSnapshot
    let selectedRange: TrendRange
    let isRefreshing: Bool
    let selectRange: (TrendRange) -> Void
    let refresh: () -> Void

    @State private var selectedRecovery: RecoveryRecord?
    @State private var isInspectorPresented = false

    private let history: [RecoveryRecord]
    private let chartColumns = [
        GridItem(.adaptive(minimum: 380), spacing: WhoopScopeTheme.cardSpacing),
    ]

    init(
        snapshot: ExplorerSnapshot,
        selectedRange: TrendRange,
        isRefreshing: Bool,
        selectRange: @escaping (TrendRange) -> Void,
        refresh: @escaping () -> Void
    ) {
        self.snapshot = snapshot
        self.selectedRange = selectedRange
        self.isRefreshing = isRefreshing
        self.selectRange = selectRange
        self.refresh = refresh
        history = snapshot.recoveries.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: WhoopScopeTheme.sectionSpacing) {
                ExplorerHeaderView(
                    title: "Recovery",
                    description: "Readiness, HRV, resting heart rate, and biometrics from WHOOP",
                    snapshot: snapshot,
                    selectedRange: selectedRange,
                    isRefreshing: isRefreshing,
                    selectRange: selectRange,
                    refresh: refresh
                )

                RecoverySummaryGrid(summary: snapshot.recoverySummary)

                if snapshot.recoveries.isEmpty {
                    ContentUnavailableView(
                        "No recovery records in this range",
                        systemImage: "heart.text.square",
                        description: Text(
                            "Choose a longer range or refresh after WHOOP scores your next recovery."
                        )
                    )
                    .cardSurface()
                } else {
                    RecoveryTrendChart(recoveries: snapshot.recoveries)
                    LazyVGrid(columns: chartColumns, spacing: WhoopScopeTheme.cardSpacing) {
                        RecoveryDistributionChart(summary: snapshot.recoverySummary)
                        RecoveryBiometricsChart(recoveries: snapshot.recoveries)
                    }
                }

                RecoveryHistoryView(
                    recoveries: history,
                    selectRecovery: inspect
                )
            }
            .padding(WhoopScopeTheme.pagePadding)
        }
        .explorerPageBackground(tint: WhoopScopeTheme.recoveryGreen)
        .inspector(isPresented: $isInspectorPresented) {
            if let selectedRecovery {
                RecoveryDetailView(record: selectedRecovery)
                    .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
            }
        }
        .onChange(of: isInspectorPresented) { _, isPresented in
            if !isPresented {
                selectedRecovery = nil
            }
        }
    }

    private func inspect(_ recovery: RecoveryRecord) {
        selectedRecovery = recovery
        Task { @MainActor in
            await Task.yield()
            isInspectorPresented = true
        }
    }
}

private struct RecoverySummaryGrid: View {
    let summary: RecoveryExplorerSummary

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: WhoopScopeTheme.cardSpacing),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: WhoopScopeTheme.cardSpacing) {
            ExplorerMetricCard(
                title: "Average recovery",
                value: summary.averageRecovery?.explorerNumber ?? "—",
                unit: "%",
                explanation: "Overall readiness across scored days",
                symbol: "heart.fill",
                tint: recoveryTint
            )
            ExplorerMetricCard(
                title: "Average HRV",
                value: summary.averageHRV?.explorerNumber ?? "—",
                unit: "ms",
                explanation: "Nightly variation between heartbeats",
                symbol: "waveform.path.ecg",
                tint: .mint
            )
            ExplorerMetricCard(
                title: "Resting heart rate",
                value: summary.averageRestingHeartRate?.explorerNumber ?? "—",
                unit: "bpm",
                explanation: "Average heart rate while your body was at rest",
                symbol: "heart.text.square.fill",
                tint: .pink
            )
            ExplorerMetricCard(
                title: "Blood oxygen",
                value: summary.averageSpO2?.explorerNumber ?? "—",
                unit: "%",
                explanation: "Average nightly SpO₂ when WHOOP supplied it",
                symbol: "lungs.fill",
                tint: .cyan
            )
            ExplorerMetricCard(
                title: "Skin temperature",
                value: summary.averageSkinTemperature?.explorerNumber ?? "—",
                unit: "°C",
                explanation: "Average nightly skin temperature",
                symbol: "thermometer.medium",
                tint: .orange
            )
        }
    }

    private var recoveryTint: Color {
        guard let score = summary.averageRecovery else { return .secondary }
        return WhoopScopeTheme.recoveryColor(for: Int(score.rounded()))
    }
}

private struct RecoveryTrendChart: View {
    let recoveries: [RecoveryRecord]

    @State private var selectedDate: Date?

    var body: some View {
        ExplorerChartSurface(
            title: "Recovery trend",
            symbol: "heart.fill",
            subtitle: selectedSubtitle
        ) {
            Chart {
                RectangleMark(
                    yStart: .value("Red zone minimum", 0),
                    yEnd: .value("Red zone maximum", 33)
                )
                .foregroundStyle(WhoopScopeTheme.recoveryRed.opacity(0.07))
                RectangleMark(
                    yStart: .value("Yellow zone minimum", 34),
                    yEnd: .value("Yellow zone maximum", 66)
                )
                .foregroundStyle(WhoopScopeTheme.recoveryYellow.opacity(0.07))
                RectangleMark(
                    yStart: .value("Green zone minimum", 67),
                    yEnd: .value("Green zone maximum", 100)
                )
                .foregroundStyle(WhoopScopeTheme.recoveryGreen.opacity(0.07))

                ForEach(recoveries) { record in
                    if let score = record.recovery.score?.recoveryPercentage {
                        LineMark(
                            x: .value("Date", record.date),
                            y: .value("Recovery percentage", score)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(WhoopScopeTheme.recoveryGreen)

                        PointMark(
                            x: .value("Date", record.date),
                            y: .value("Recovery percentage", score)
                        )
                        .foregroundStyle(
                            WhoopScopeTheme.recoveryColor(for: Int(score.rounded()))
                        )
                        .symbolSize(32)
                    }
                }
                if let selectedDate {
                    RuleMark(x: .value("Selected date", selectedDate))
                        .foregroundStyle(.secondary)
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 34, 67, 100]) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(minHeight: 270)
            .accessibilityLabel("Daily recovery percentage with red, yellow, and green zones")
        }
    }

    private var selectedRecord: RecoveryRecord? {
        guard let selectedDate else { return nil }
        return recoveries.min {
            abs($0.date.timeIntervalSince(selectedDate))
                < abs($1.date.timeIntervalSince(selectedDate))
        }
    }

    private var selectedSubtitle: String {
        guard
            let record = selectedRecord,
            let score = record.recovery.score
        else {
            return "Daily readiness on WHOOP’s red, yellow, and green scale"
        }
        return "\(explorerDate(record.date)) · \(score.recoveryPercentage.explorerPercent) · \(score.hrvRMSSDMilliseconds.explorerNumber) ms HRV"
    }
}

private struct RecoveryDistributionChart: View {
    let summary: RecoveryExplorerSummary

    private var zones: [RecoveryZoneSlice] {
        [
            .init(name: "Green", count: summary.greenCount),
            .init(name: "Yellow", count: summary.yellowCount),
            .init(name: "Red", count: summary.redCount),
        ]
    }

    var body: some View {
        ExplorerChartSurface(
            title: "Readiness distribution",
            symbol: "chart.pie.fill",
            subtitle: "How often each recovery zone appeared"
        ) {
            Chart(zones) { zone in
                SectorMark(
                    angle: .value("Scored days", zone.count),
                    innerRadius: .ratio(0.58),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Recovery zone", zone.name))
            }
            .chartForegroundStyleScale([
                "Green": WhoopScopeTheme.recoveryGreen,
                "Yellow": WhoopScopeTheme.recoveryYellow,
                "Red": WhoopScopeTheme.recoveryRed,
            ])
            .chartLegend(position: .bottom, alignment: .center)
            .frame(minHeight: 235)
            .accessibilityLabel("Distribution of green, yellow, and red recovery days")
        }
    }
}

private struct RecoveryZoneSlice: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

private struct RecoveryBiometricsChart: View {
    let recoveries: [RecoveryRecord]

    var body: some View {
        ExplorerChartSurface(
            title: "HRV and resting heart rate",
            symbol: "waveform.path.ecg",
            subtitle: "Nightly cardiovascular signals shown together for context"
        ) {
            Chart {
                ForEach(recoveries) { record in
                    if let score = record.recovery.score {
                        LineMark(
                            x: .value("Date", record.date),
                            y: .value("Beats or milliseconds", score.hrvRMSSDMilliseconds),
                            series: .value("Metric", "HRV")
                        )
                        .foregroundStyle(by: .value("Metric", "HRV"))
                        .interpolationMethod(.monotone)

                        LineMark(
                            x: .value("Date", record.date),
                            y: .value("Beats or milliseconds", score.restingHeartRate),
                            series: .value("Metric", "RHR")
                        )
                        .foregroundStyle(by: .value("Metric", "RHR"))
                        .interpolationMethod(.monotone)
                    }
                }
            }
            .chartForegroundStyleScale([
                "HRV": .mint,
                "RHR": .pink,
            ])
            .chartLegend(position: .bottom, alignment: .center)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(minHeight: 235)
            .accessibilityLabel("Heart rate variability and resting heart rate trend")
        }
    }
}
