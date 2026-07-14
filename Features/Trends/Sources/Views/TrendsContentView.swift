import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct TrendsContentView: View {
    let snapshot: TrendsSnapshot
    let selectedRange: TrendRange
    let isRefreshing: Bool
    let selectRange: (TrendRange) -> Void
    let refresh: () -> Void

    private let summaryColumns = [
        GridItem(.adaptive(minimum: 180), spacing: WhoopScopeTheme.cardSpacing),
    ]
    private let chartColumns = [
        GridItem(.adaptive(minimum: 360), spacing: WhoopScopeTheme.cardSpacing),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: WhoopScopeTheme.sectionSpacing) {
                TrendsHeaderView(
                    snapshot: snapshot,
                    selectedRange: selectedRange,
                    isRefreshing: isRefreshing,
                    selectRange: selectRange,
                    refresh: refresh
                )

                LazyVGrid(columns: summaryColumns, spacing: WhoopScopeTheme.cardSpacing) {
                    TrendSummaryCard.recovery(snapshot)
                    TrendSummaryCard.strain(snapshot)
                    TrendSummaryCard.sleep(snapshot)
                    TrendSummaryCard.hrv(snapshot)
                    TrendSummaryCard.restingHeartRate(snapshot)
                }

                if snapshot.days.isEmpty {
                    ContentUnavailableView(
                        "No trend data yet",
                        systemImage: "chart.xyaxis.line",
                        description: Text(
                            "Trends will appear after WHOOP has scored your first cycle, recovery, and sleep."
                        )
                    )
                    .cardSurface()
                } else {
                    ReadinessTrendChart(snapshot: snapshot)
                    StrainTrendChart(snapshot: snapshot)

                    LazyVGrid(columns: chartColumns, spacing: WhoopScopeTheme.cardSpacing) {
                        HRVTrendChart(snapshot: snapshot)
                        RestingHeartRateTrendChart(snapshot: snapshot)
                    }
                }
            }
            .padding(WhoopScopeTheme.pagePadding)
        }
        .scrollContentBackground(.visible)
        .background {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}
