import SwiftUI
import WhoopScopeDashboard
import WhoopScopeSettings
import WhoopScopeTrends

struct RootView: View {
    let dashboardModel: DashboardModel
    let settingsModel: SettingsModel
    let trendsModel: TrendsModel

    @State private var selection: AppDestination? = .today

    var body: some View {
        NavigationSplitView {
            List(AppDestination.allCases, selection: $selection) { destination in
                NavigationLink(value: destination) {
                    Label(destination.title, systemImage: destination.symbol)
                }
            }
            .navigationTitle("WhoopScope")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            switch selection ?? .today {
            case .today:
                DashboardView(model: dashboardModel)
                    .navigationTitle("Today")
            case .trends:
                TrendsView(model: trendsModel)
                    .navigationTitle("Trends")
            case .settings:
                SettingsView(model: settingsModel)
            case let destination:
                PlannedFeatureView(destination: destination)
            }
        }
    }
}
