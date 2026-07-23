import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct StrainExplorerContentView: View {
    let snapshot: ExplorerSnapshot
    let selectedRange: TrendRange
    let isRefreshing: Bool
    let selectRange: (TrendRange) -> Void
    let refresh: () -> Void

    @State private var selectedCycle: WhoopCycle?
    @State private var isInspectorPresented = false

    private let history: [WhoopCycle]
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
        history = snapshot.cycles.sorted { $0.start > $1.start }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: WhoopScopeTheme.sectionSpacing) {
                ExplorerHeaderView(
                    title: "Strain & Cycles",
                    description: "Daily cardiovascular load, energy, heart rate, and cycle timing",
                    snapshot: snapshot,
                    selectedRange: selectedRange,
                    isRefreshing: isRefreshing,
                    selectRange: selectRange,
                    refresh: refresh
                )

                CycleSummaryGrid(summary: snapshot.cycleSummary)

                if snapshot.cycles.isEmpty {
                    ContentUnavailableView(
                        "No cycles in this range",
                        systemImage: "bolt",
                        description: Text(
                            "Choose a longer range or refresh after WHOOP records your next cycle."
                        )
                    )
                    .cardSurface()
                } else {
                    StrainTrendChart(cycles: snapshot.cycles)
                    LazyVGrid(columns: chartColumns, spacing: WhoopScopeTheme.cardSpacing) {
                        CycleEnergyChart(cycles: snapshot.cycles)
                        CycleHeartRateChart(cycles: snapshot.cycles)
                    }
                }

                CycleHistoryView(
                    cycles: history,
                    selectCycle: inspect
                )
            }
            .padding(WhoopScopeTheme.pagePadding)
        }
        .explorerPageBackground(tint: WhoopScopeTheme.strainBlue)
        .inspector(isPresented: $isInspectorPresented) {
            if let selectedCycle {
                CycleDetailView(cycle: selectedCycle)
                    .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
            }
        }
        .onChange(of: isInspectorPresented) { _, isPresented in
            if !isPresented {
                selectedCycle = nil
            }
        }
    }

    private func inspect(_ cycle: WhoopCycle) {
        selectedCycle = cycle
        Task { @MainActor in
            await Task.yield()
            isInspectorPresented = true
        }
    }
}

private struct CycleSummaryGrid: View {
    let summary: CycleExplorerSummary

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: WhoopScopeTheme.cardSpacing),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: WhoopScopeTheme.cardSpacing) {
            ExplorerMetricCard(
                title: "Average strain",
                value: summary.averageStrain?.explorerNumber ?? "—",
                unit: "/ 21",
                explanation: "Typical daily cardiovascular load",
                symbol: "bolt.fill",
                tint: WhoopScopeTheme.strainBlue
            )
            ExplorerMetricCard(
                title: "Peak strain",
                value: summary.peakStrain?.explorerNumber ?? "—",
                unit: "/ 21",
                explanation: "Highest daily load in this range",
                symbol: "arrow.up.forward.circle.fill",
                tint: .indigo
            )
            ExplorerMetricCard(
                title: "Daily energy",
                value: averageDailyEnergy,
                unit: "kcal",
                explanation: "Average WHOOP-estimated energy per scored cycle",
                symbol: "flame.fill",
                tint: .orange
            )
            ExplorerMetricCard(
                title: "Average heart rate",
                value: summary.averageHeartRate?.explorerNumber ?? "—",
                unit: "bpm",
                explanation: "Average heart rate across scored cycles",
                symbol: "heart.fill",
                tint: .pink
            )
        }
    }

    private var averageDailyEnergy: String {
        guard summary.scoredCount > 0 else { return "—" }
        return Int(
            (summary.totalKilocalories / Double(summary.scoredCount)).rounded()
        ).formatted()
    }
}

private struct StrainTrendChart: View {
    let cycles: [WhoopCycle]

    @State private var selectedDate: Date?

    var body: some View {
        ExplorerChartSurface(
            title: "Daily strain",
            symbol: "bolt.fill",
            subtitle: selectedSubtitle
        ) {
            Chart {
                ForEach(cycles) { cycle in
                    if let strain = cycle.score?.strain {
                        BarMark(
                            x: .value("Date", cycle.start),
                            y: .value("Daily strain", strain)
                        )
                        .foregroundStyle(WhoopScopeTheme.strainBlue.gradient)
                    }
                }
                RuleMark(y: .value("Maximum strain", 21))
                    .foregroundStyle(.secondary.opacity(0.4))
                if let selectedDate {
                    RuleMark(x: .value("Selected date", selectedDate))
                        .foregroundStyle(.secondary)
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartYScale(domain: 0...21)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 7, 14, 21]) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXSelection(value: $selectedDate)
            .frame(minHeight: 270)
            .accessibilityLabel("Daily strain on WHOOP's zero to twenty-one scale")
        }
    }

    private var selectedCycle: WhoopCycle? {
        guard let selectedDate else { return nil }
        return cycles.min {
            abs($0.start.timeIntervalSince(selectedDate))
                < abs($1.start.timeIntervalSince(selectedDate))
        }
    }

    private var selectedSubtitle: String {
        guard let cycle = selectedCycle else {
            return "Cardiovascular load on WHOOP’s logarithmic 0–21 scale"
        }
        return "\(explorerDate(cycle.start)) · \(cycle.score?.strain.explorerNumber ?? "—") strain"
    }
}

private struct CycleEnergyChart: View {
    let cycles: [WhoopCycle]

    var body: some View {
        ExplorerChartSurface(
            title: "Daily energy",
            symbol: "flame.fill",
            subtitle: "WHOOP-estimated energy expenditure by cycle"
        ) {
            Chart(cycles) { cycle in
                if let score = cycle.score {
                    AreaMark(
                        x: .value("Date", cycle.start),
                        y: .value("Kilocalories", explorerKilocalories(score.kilojoules))
                    )
                    .foregroundStyle(.orange.opacity(0.25))
                    LineMark(
                        x: .value("Date", cycle.start),
                        y: .value("Kilocalories", explorerKilocalories(score.kilojoules))
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.monotone)
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
            .frame(minHeight: 235)
            .accessibilityLabel("Daily energy expenditure in kilocalories")
        }
    }
}

private struct CycleHeartRateChart: View {
    let cycles: [WhoopCycle]

    var body: some View {
        ExplorerChartSurface(
            title: "Cycle heart rate",
            symbol: "heart.text.square.fill",
            subtitle: "Average and maximum heart rate across each daily cycle"
        ) {
            Chart {
                ForEach(cycles) { cycle in
                    if let score = cycle.score {
                        LineMark(
                            x: .value("Date", cycle.start),
                            y: .value("Heart rate", score.averageHeartRate),
                            series: .value("Metric", "Average")
                        )
                        .foregroundStyle(by: .value("Metric", "Average"))
                        LineMark(
                            x: .value("Date", cycle.start),
                            y: .value("Heart rate", score.maxHeartRate),
                            series: .value("Metric", "Maximum")
                        )
                        .foregroundStyle(by: .value("Metric", "Maximum"))
                    }
                }
            }
            .chartForegroundStyleScale([
                "Average": .pink,
                "Maximum": .red,
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
            .accessibilityLabel("Average and maximum heart rate by daily cycle")
        }
    }
}
