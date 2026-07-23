import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct SleepExplorerContentView: View {
    let snapshot: ExplorerSnapshot
    let selectedRange: TrendRange
    let isRefreshing: Bool
    let selectRange: (TrendRange) -> Void
    let refresh: () -> Void

    @State private var selectedSleep: WhoopSleep?
    @State private var isInspectorPresented = false

    private let mainSleeps: [WhoopSleep]
    private let history: [WhoopSleep]
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
        mainSleeps = snapshot.sleeps.filter { !$0.isNap }
        history = snapshot.sleeps.sorted { $0.start > $1.start }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: WhoopScopeTheme.sectionSpacing) {
                ExplorerHeaderView(
                    title: "Sleep",
                    description: "Duration, need, stages, and nightly quality from WHOOP",
                    snapshot: snapshot,
                    selectedRange: selectedRange,
                    isRefreshing: isRefreshing,
                    selectRange: selectRange,
                    refresh: refresh
                )

                SleepSummaryGrid(summary: snapshot.sleepSummary)

                if mainSleeps.isEmpty {
                    ContentUnavailableView(
                        "No scored sleep in this range",
                        systemImage: "bed.double",
                        description: Text(
                            "Choose a longer range or refresh after WHOOP scores your next sleep."
                        )
                    )
                    .cardSurface()
                } else {
                    LazyVGrid(columns: chartColumns, spacing: WhoopScopeTheme.cardSpacing) {
                        SleepDurationChart(sleeps: mainSleeps)
                        SleepStageChart(summary: snapshot.sleepSummary)
                    }
                    SleepPerformanceChart(sleeps: mainSleeps)
                }

                SleepHistoryView(
                    sleeps: history,
                    selectSleep: inspect
                )
            }
            .padding(WhoopScopeTheme.pagePadding)
        }
        .explorerPageBackground(tint: WhoopScopeTheme.sleepPurple)
        .inspector(isPresented: $isInspectorPresented) {
            if let selectedSleep {
                SleepDetailView(sleep: selectedSleep)
                    .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
            }
        }
        .onChange(of: isInspectorPresented) { _, isPresented in
            if !isPresented {
                selectedSleep = nil
            }
        }
    }

    private func inspect(_ sleep: WhoopSleep) {
        selectedSleep = sleep
        Task { @MainActor in
            await Task.yield()
            isInspectorPresented = true
        }
    }
}

private struct SleepSummaryGrid: View {
    let summary: SleepExplorerSummary

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: WhoopScopeTheme.cardSpacing),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: WhoopScopeTheme.cardSpacing) {
            ExplorerMetricCard(
                title: "Average sleep",
                value: summary.averageAchievedHours?.explorerNumber ?? "—",
                unit: "hours",
                explanation: "Time actually asleep each main sleep",
                symbol: "bed.double.fill",
                tint: WhoopScopeTheme.sleepPurple
            )
            ExplorerMetricCard(
                title: "Sleep performance",
                value: summary.averagePerformance?.explorerNumber ?? "—",
                unit: "%",
                explanation: "How much of your calculated sleep need you met",
                symbol: "moon.stars.fill",
                tint: WhoopScopeTheme.sleepPurple
            )
            ExplorerMetricCard(
                title: "Efficiency",
                value: summary.averageEfficiency?.explorerNumber ?? "—",
                unit: "%",
                explanation: "Share of in-bed time spent asleep",
                symbol: "gauge.with.dots.needle.67percent",
                tint: .indigo
            )
            ExplorerMetricCard(
                title: "Consistency",
                value: summary.averageConsistency?.explorerNumber ?? "—",
                unit: "%",
                explanation: "How steady your sleep and wake timing was",
                symbol: "calendar.badge.clock",
                tint: .teal
            )
            ExplorerMetricCard(
                title: "Records",
                value: "\(summary.mainSleepCount)",
                unit: summary.mainSleepCount == 1 ? "night" : "nights",
                explanation: "\(summary.napCount) \(summary.napCount == 1 ? "nap" : "naps") also recorded",
                symbol: "list.bullet.rectangle",
                tint: .secondary
            )
        }
    }
}

private struct SleepDurationChart: View {
    let sleeps: [WhoopSleep]

    var body: some View {
        ExplorerChartSurface(
            title: "Sleep versus need",
            symbol: "bed.double",
            subtitle: "Hours achieved compared with WHOOP’s calculated need"
        ) {
            Chart {
                ForEach(sleeps) { sleep in
                    if let score = sleep.score {
                        BarMark(
                            x: .value("Date", sleep.start),
                            y: .value(
                                "Hours asleep",
                                score.stageSummary.achievedSleepMilliseconds.explorerHours
                            )
                        )
                        .foregroundStyle(WhoopScopeTheme.sleepPurple.gradient)

                        LineMark(
                            x: .value("Date", sleep.start),
                            y: .value(
                                "Hours needed",
                                score.sleepNeeded.totalMilliseconds.explorerHours
                            )
                        )
                        .foregroundStyle(.white.opacity(0.75))
                        .lineStyle(.init(lineWidth: 2, dash: [5, 4]))
                    }
                }
            }
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
            .frame(minHeight: 240)
            .accessibilityLabel("Nightly hours asleep and hours needed")
        }
    }
}

private struct SleepStageChart: View {
    let summary: SleepExplorerSummary

    private var slices: [SleepStageSlice] {
        [
            .init(name: "Awake", hours: summary.stageAverages.awakeHours),
            .init(name: "Light", hours: summary.stageAverages.lightHours),
            .init(name: "Slow wave", hours: summary.stageAverages.slowWaveHours),
            .init(name: "REM", hours: summary.stageAverages.remHours),
        ]
    }

    var body: some View {
        ExplorerChartSurface(
            title: "Average sleep stages",
            symbol: "chart.pie.fill",
            subtitle: "Typical nightly composition across scored main sleeps"
        ) {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Average hours", slice.hours),
                    innerRadius: .ratio(0.58),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Stage", slice.name))
            }
            .chartForegroundStyleScale([
                "Awake": .gray,
                "Light": .blue,
                "Slow wave": .indigo,
                "REM": WhoopScopeTheme.sleepPurple,
            ])
            .chartLegend(position: .bottom, alignment: .center)
            .frame(minHeight: 240)
            .accessibilityLabel("Average time in awake, light, slow wave, and REM stages")
        }
    }
}

private struct SleepStageSlice: Identifiable {
    var id: String { name }
    let name: String
    let hours: Double
}

private struct SleepPerformanceChart: View {
    let sleeps: [WhoopSleep]

    @State private var selectedDate: Date?

    var body: some View {
        ExplorerChartSurface(
            title: "Sleep quality",
            symbol: "waveform.path.ecg.rectangle",
            subtitle: selectedSubtitle
        ) {
            Chart {
                ForEach(sleeps) { sleep in
                    if let performance = sleep.score?.performancePercentage {
                        LineMark(
                            x: .value("Date", sleep.start),
                            y: .value("Sleep performance percentage", performance),
                            series: .value("Metric", "Performance")
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(WhoopScopeTheme.sleepPurple)
                        PointMark(
                            x: .value("Date", sleep.start),
                            y: .value("Sleep performance percentage", performance)
                        )
                        .foregroundStyle(WhoopScopeTheme.sleepPurple)
                        .symbolSize(24)
                    }
                    if let efficiency = sleep.score?.efficiencyPercentage {
                        LineMark(
                            x: .value("Date", sleep.start),
                            y: .value("Sleep efficiency percentage", efficiency),
                            series: .value("Metric", "Efficiency")
                        )
                        .foregroundStyle(.teal)
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
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(minHeight: 250)
            .accessibilityLabel("Nightly sleep performance and sleep efficiency percentages")
        }
    }

    private var selectedSleep: WhoopSleep? {
        guard let selectedDate else { return nil }
        return sleeps.min {
            abs($0.start.timeIntervalSince(selectedDate))
                < abs($1.start.timeIntervalSince(selectedDate))
        }
    }

    private var selectedSubtitle: String {
        guard let sleep = selectedSleep else {
            return "Performance shows need met; efficiency shows time asleep while in bed"
        }
        let performance = sleep.score?.performancePercentage?.explorerPercent ?? "—"
        let efficiency = sleep.score?.efficiencyPercentage?.explorerPercent ?? "—"
        return "\(explorerDate(sleep.start)) · \(performance) performance · \(efficiency) efficiency"
    }
}
