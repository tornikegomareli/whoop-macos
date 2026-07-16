import SwiftUI
import WhoopScopeAuthentication
import WhoopScopeData
import WhoopScopeDashboard
import WhoopScopeDomain
import WhoopScopeHealthBridge
import WhoopScopePersistence
import WhoopScopeSettings
import WhoopScopeTrends

@main
struct WhoopScopeApp: App {
    @State private var dashboardModel: DashboardModel
    @State private var settingsModel: SettingsModel
    @State private var trendsModel: TrendsModel
    @State private var healthReceiver: HealthBridgeReceiver

    init() {
        let authenticationService = WhoopBrokerAuthenticationService(
            brokerBaseURL: BrokerBaseURL.value,
            webAuthorizer: OAuthWebAuthorizer()
        )
        let database: WhoopScopeDatabase
        do {
            database = try .live()
        } catch {
            fatalError("Unable to open WhoopScope's local database: \(error)")
        }
        let apiClient = WhoopAPIClient { forceRefresh in
            try await authenticationService.accessToken(forceRefresh: forceRefresh)
        }
        let synchronizer = WhoopDataSynchronizer(
            apiClient: apiClient,
            database: database
        )
        let widgetPublisher = WidgetSnapshotPublisher()
        _healthReceiver = State(
            initialValue: HealthBridgeReceiver { payload in
                try await database.saveHealthEnrichment(payload)
            }
        )
        let dashboardRepository = LiveDashboardRepository(
            synchronizer: synchronizer,
            database: database
        )
        _dashboardModel = State(
            initialValue: DashboardModel(
                loadDashboard: LoadDashboard(repository: dashboardRepository),
                snapshotDidLoad: widgetPublisher.publish
            )
        )
        let trendsRepository = LiveTrendsRepository(
            synchronizer: synchronizer,
            database: database
        )
        _trendsModel = State(
            initialValue: TrendsModel(
                loadTrends: LoadTrends(repository: trendsRepository)
            )
        )
        let accountRepository = LiveWhoopAccountRepository(
            apiClient: apiClient,
            database: database
        )
        _settingsModel = State(
            initialValue: SettingsModel(
                authenticationService: authenticationService,
                loadAccount: LoadWhoopAccount(repository: accountRepository),
                didSignOut: widgetPublisher.clear
            )
        )
    }

    var body: some Scene {
        WindowGroup("WhoopScope", id: "dashboard") {
            RootView(
                dashboardModel: dashboardModel,
                settingsModel: settingsModel,
                trendsModel: trendsModel,
                healthReceiver: healthReceiver
            )
                .frame(minWidth: 980, minHeight: 680)
        }
        .defaultSize(width: 1_260, height: 820)

        MenuBarExtra {
            MenuBarContainerView(dashboardModel: dashboardModel)
        } label: {
            Image("MenuBarIcon", bundle: .main)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 18, height: 18)
                .accessibilityLabel(menuBarAccessibilityLabel)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: settingsModel, healthReceiver: healthReceiver)
                .frame(width: 540, height: 520)
        }
    }

    private var menuBarAccessibilityLabel: String {
        if let snapshot = dashboardModel.snapshot {
            "WhoopScope, recovery \(snapshot.recovery.score) percent"
        } else {
            "WhoopScope"
        }
    }
}
