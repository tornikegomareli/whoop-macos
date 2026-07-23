import SwiftUI
import WhoopScopeChat
import WhoopScopeDashboard
import WhoopScopeExplorers
import WhoopScopeHealthBridge
import WhoopScopeSettings
import WhoopScopeTrends

struct RootView: View {
    let dashboardModel: DashboardModel
    let settingsModel: SettingsModel
    let trendsModel: TrendsModel
    let explorerModel: ExplorerModel
    let healthReceiver: HealthBridgeReceiver
    let chatModel: ChatModel
    let aiSettings: AISettingsModel
    let isDemoMode: Bool

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
            case .sleep:
                SleepExplorerView(model: explorerModel)
                    .navigationTitle("Sleep")
            case .recovery:
                RecoveryExplorerView(model: explorerModel)
                    .navigationTitle("Recovery")
            case .strain:
                StrainExplorerView(model: explorerModel)
                    .navigationTitle("Strain & Cycles")
            case .workouts:
                WorkoutsExplorerView(model: explorerModel)
                    .navigationTitle("Workouts")
            case .settings:
                SettingsView(
                    model: settingsModel,
                    healthReceiver: healthReceiver,
                    aiSettings: aiSettings
                )
            case .chat:
                ChatView(model: chatModel)
                    .navigationTitle("Ask Your Data")
            }
        }
        .onOpenURL(perform: handleOpenURL)
        .toolbar {
            if isDemoMode {
                ToolbarItem(placement: .primaryAction) {
                    Label("Sample Data", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .help("This window uses synthetic data and does not access a WHOOP account.")
                }
            }
        }
        .task {
            if !isDemoMode {
                healthReceiver.start()
            }
        }
    }

    private func handleOpenURL(_ url: URL) {
        guard
            url.scheme == "whoopscope",
            url.host == "open",
            let destinationName = url.pathComponents.dropFirst().first,
            let destination = AppDestination(rawValue: destinationName)
        else { return }

        selection = destination
    }
}
