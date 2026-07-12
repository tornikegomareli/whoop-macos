import SwiftUI
import WhoopScopeAuthentication
import WhoopScopeData
import WhoopScopeDashboard
import WhoopScopeDomain
import WhoopScopePersistence
import WhoopScopeSettings

@main
struct WhoopScopeApp: App {
    @State private var dashboardModel: DashboardModel
    @State private var settingsModel: SettingsModel

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
        let dashboardRepository = LiveDashboardRepository(
            apiClient: apiClient,
            database: database
        )
        _dashboardModel = State(
            initialValue: DashboardModel(
                loadDashboard: LoadDashboard(repository: dashboardRepository)
            )
        )
        let accountRepository = LiveWhoopAccountRepository(
            apiClient: apiClient,
            database: database
        )
        _settingsModel = State(
            initialValue: SettingsModel(
                authenticationService: authenticationService,
                loadAccount: LoadWhoopAccount(repository: accountRepository)
            )
        )
    }

    var body: some Scene {
        WindowGroup("WhoopScope", id: "dashboard") {
            RootView(
                dashboardModel: dashboardModel,
                settingsModel: settingsModel
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
            SettingsView(model: settingsModel)
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
