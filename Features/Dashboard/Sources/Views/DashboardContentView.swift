import SwiftUI
import WhoopScopeDesignSystem
import WhoopScopeDomain

struct DashboardContentView: View {
    let snapshot: DashboardSnapshot
    let isRefreshing: Bool
    let refresh: () -> Void

    private let metricColumns = [
        GridItem(.flexible(minimum: 210), spacing: WhoopScopeTheme.cardSpacing),
        GridItem(.flexible(minimum: 210), spacing: WhoopScopeTheme.cardSpacing),
        GridItem(.flexible(minimum: 210), spacing: WhoopScopeTheme.cardSpacing),
    ]

    private let insightColumns = [
        GridItem(.adaptive(minimum: 340), spacing: WhoopScopeTheme.cardSpacing),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: WhoopScopeTheme.sectionSpacing) {
                DashboardHeaderView(
                    snapshot: snapshot,
                    isRefreshing: isRefreshing,
                    refresh: refresh
                )

                LazyVGrid(columns: metricColumns, spacing: WhoopScopeTheme.cardSpacing) {
                    RecoveryMetricCard(recovery: snapshot.recovery)
                    StrainMetricCard(strain: snapshot.strain)
                    SleepMetricCard(sleep: snapshot.sleep)
                }

                LazyVGrid(columns: insightColumns, spacing: WhoopScopeTheme.cardSpacing) {
                    RecoveryTrendCard(history: snapshot.history)
                    StrainLoadCard(history: snapshot.history)
                }

                LazyVGrid(columns: insightColumns, spacing: WhoopScopeTheme.cardSpacing) {
                    SleepBalanceCard(sleep: snapshot.sleep)
                    RecentWorkoutsCard(workouts: snapshot.recentWorkouts)
                }
            }
            .padding(WhoopScopeTheme.pagePadding)
        }
        .scrollContentBackground(.visible)
        .background {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.08),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}
