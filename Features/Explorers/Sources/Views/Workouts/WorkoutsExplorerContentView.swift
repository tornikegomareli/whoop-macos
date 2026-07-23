import Charts
import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct WorkoutsExplorerContentView: View {
    let snapshot: ExplorerSnapshot
    let selectedRange: TrendRange
    let isRefreshing: Bool
    let selectRange: (TrendRange) -> Void
    let refresh: () -> Void

    @State private var query = ""
    @State private var selectedSport = Self.allSports
    @State private var selectedWorkout: WhoopWorkout?
    @State private var isInspectorPresented = false

    private static let allSports = "All activities"

    private let sports: [String]
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
        sports = [Self.allSports] + Set(
            snapshot.workouts.map { $0.sportName.localizedCapitalized }
        )
        .sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: WhoopScopeTheme.sectionSpacing) {
                ExplorerHeaderView(
                    title: "Workouts",
                    description: "Activity load, heart rate zones, duration, and distance",
                    snapshot: snapshot,
                    selectedRange: selectedRange,
                    isRefreshing: isRefreshing,
                    selectRange: selectRange,
                    refresh: refresh
                )

                WorkoutSummaryGrid(summary: snapshot.workoutSummary)

                if snapshot.workouts.isEmpty {
                    ContentUnavailableView(
                        "No workouts in this range",
                        systemImage: "figure.run",
                        description: Text(
                            "Choose a longer range or refresh after WHOOP records your next activity."
                        )
                    )
                    .cardSurface()
                } else {
                    LazyVGrid(columns: chartColumns, spacing: WhoopScopeTheme.cardSpacing) {
                        WorkoutLoadChart(workouts: snapshot.workouts)
                        SportBreakdownChart(sports: snapshot.workoutSummary.sports)
                    }
                }

                WorkoutFilterBar(
                    query: $query,
                    selectedSport: $selectedSport,
                    sports: sports
                )

                WorkoutHistoryView(
                    workouts: filteredWorkouts,
                    selectWorkout: inspect
                )
            }
            .padding(WhoopScopeTheme.pagePadding)
        }
        .explorerPageBackground(tint: WhoopScopeTheme.strainBlue)
        .inspector(isPresented: $isInspectorPresented) {
            if let selectedWorkout {
                WorkoutDetailView(workout: selectedWorkout)
                    .inspectorColumnWidth(min: 320, ideal: 360, max: 440)
            }
        }
        .onChange(of: isInspectorPresented) { _, isPresented in
            if !isPresented {
                selectedWorkout = nil
            }
        }
    }

    private var filteredWorkouts: [WhoopWorkout] {
        snapshot.workouts
            .filter { workout in
                selectedSport == Self.allSports
                    || workout.sportName.localizedCapitalized == selectedSport
            }
            .filter { workout in
                query.isEmpty
                    || workout.sportName.localizedStandardContains(query)
            }
            .sorted { $0.start > $1.start }
    }

    private func inspect(_ workout: WhoopWorkout) {
        selectedWorkout = workout
        Task { @MainActor in
            await Task.yield()
            isInspectorPresented = true
        }
    }
}

private struct WorkoutSummaryGrid: View {
    let summary: WorkoutExplorerSummary

    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: WhoopScopeTheme.cardSpacing),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: WhoopScopeTheme.cardSpacing) {
            ExplorerMetricCard(
                title: "Workouts",
                value: "\(summary.scoredCount)",
                unit: "scored",
                explanation: summary.topSport.map { "Most frequent: \($0)" }
                    ?? "No scored workouts",
                symbol: "figure.run",
                tint: WhoopScopeTheme.strainBlue
            )
            ExplorerMetricCard(
                title: "Total duration",
                value: summary.totalDuration.explorerDuration,
                unit: "",
                explanation: "Time spent across every activity",
                symbol: "clock.fill",
                tint: .cyan
            )
            ExplorerMetricCard(
                title: "Average strain",
                value: summary.averageStrain?.explorerNumber ?? "—",
                unit: "/ 21",
                explanation: "Average cardiovascular load per scored workout",
                symbol: "bolt.fill",
                tint: WhoopScopeTheme.strainBlue
            )
            ExplorerMetricCard(
                title: "Activity energy",
                value: Int(summary.totalKilocalories.rounded()).formatted(),
                unit: "kcal",
                explanation: "Total energy WHOOP attributed to these workouts",
                symbol: "flame.fill",
                tint: .orange
            )
        }
    }
}

private struct WorkoutLoadChart: View {
    let workouts: [WhoopWorkout]

    @State private var selectedDate: Date?

    var body: some View {
        ExplorerChartSurface(
            title: "Workout strain",
            symbol: "bolt.horizontal.fill",
            subtitle: selectedSubtitle
        ) {
            Chart {
                ForEach(workouts) { workout in
                    if let strain = workout.score?.strain {
                        PointMark(
                            x: .value("Date", workout.start),
                            y: .value("Workout strain", strain)
                        )
                        .foregroundStyle(WhoopScopeTheme.strainBlue)
                        .symbolSize(64)
                    }
                }
                if let selectedDate {
                    RuleMark(x: .value("Selected date", selectedDate))
                        .foregroundStyle(.secondary)
                        .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) {
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
            .chartYScale(domain: 0...21)
            .chartXSelection(value: $selectedDate)
            .frame(minHeight: 240)
            .accessibilityLabel("Workout strain by date")
        }
    }

    private var selectedWorkout: WhoopWorkout? {
        guard let selectedDate else { return nil }
        return workouts.min {
            abs($0.start.timeIntervalSince(selectedDate))
                < abs($1.start.timeIntervalSince(selectedDate))
        }
    }

    private var selectedSubtitle: String {
        guard let workout = selectedWorkout else {
            return "Each point is one activity on WHOOP’s logarithmic 0–21 scale"
        }
        let strain = workout.score?.strain.explorerNumber ?? "—"
        return "\(explorerDate(workout.start)) · \(workout.sportName.localizedCapitalized) · \(strain) strain"
    }
}

private struct SportBreakdownChart: View {
    let sports: [SportSummary]

    var body: some View {
        ExplorerChartSurface(
            title: "Activity mix",
            symbol: "chart.bar.xaxis",
            subtitle: "Workout count grouped by activity type"
        ) {
            Chart(Array(sports.prefix(8))) { sport in
                BarMark(
                    x: .value("Workout count", sport.workoutCount),
                    y: .value("Activity", sport.name)
                )
                .foregroundStyle(WhoopScopeTheme.strainBlue.gradient)
                .annotation(position: .trailing) {
                    Text("\(sport.workoutCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(minHeight: 240)
            .accessibilityLabel("Workout count by activity type")
        }
    }
}

private struct WorkoutFilterBar: View {
    @Binding var query: String
    @Binding var selectedSport: String
    let sports: [String]

    var body: some View {
        HStack(spacing: 12) {
            TextField("Search activities", text: $query)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 320)
                .accessibilityHint("Filters workout history by activity name")

            Picker("Activity", selection: $selectedSport) {
                ForEach(sports, id: \.self) { sport in
                    Text(sport).tag(sport)
                }
            }
            .frame(width: 220)

            Text("\(sports.count - 1) activity types")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
