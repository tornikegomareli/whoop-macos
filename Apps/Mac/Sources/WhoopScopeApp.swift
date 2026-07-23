import SwiftUI
import WhoopScopeAuthentication
import WhoopScopeChat
import WhoopScopeData
import WhoopScopeDashboard
import WhoopScopeDomain
import WhoopScopeExplorers
import WhoopScopeHealthBridge
import WhoopScopePersistence
import WhoopScopePreviewData
import WhoopScopeSettings
import WhoopScopeTrends

@main
struct WhoopScopeApp: App {
    @State private var dashboardModel: DashboardModel
    @State private var settingsModel: SettingsModel
    @State private var trendsModel: TrendsModel
    @State private var explorerModel: ExplorerModel
    @State private var healthReceiver: HealthBridgeReceiver
    @State private var aiSettings: AISettingsModel
    @State private var chatModel: ChatModel
    private let isDemoMode: Bool

    init() {
        let isDemoMode = ProcessInfo.processInfo.arguments.contains("--demo-data")
        let composition: AppComposition
        do {
            composition = try isDemoMode ? .demo() : .live()
        } catch {
            fatalError("Unable to open WhoopScope's local database: \(error)")
        }
        self.isDemoMode = isDemoMode
        _dashboardModel = State(initialValue: composition.dashboardModel)
        _settingsModel = State(initialValue: composition.settingsModel)
        _trendsModel = State(initialValue: composition.trendsModel)
        _explorerModel = State(initialValue: composition.explorerModel)
        _healthReceiver = State(initialValue: composition.healthReceiver)
        _aiSettings = State(initialValue: composition.aiSettings)
        _chatModel = State(initialValue: composition.chatModel)
    }

    var body: some Scene {
        WindowGroup("WhoopScope", id: "dashboard") {
            RootView(
                dashboardModel: dashboardModel,
                settingsModel: settingsModel,
                trendsModel: trendsModel,
                explorerModel: explorerModel,
                healthReceiver: healthReceiver,
                chatModel: chatModel,
                aiSettings: aiSettings,
                isDemoMode: isDemoMode
            )
                .frame(minWidth: 980, minHeight: 680)
        }
        .defaultSize(width: 1_260, height: 820)

        MenuBarExtra {
            MenuBarContainerView(
                dashboardModel: dashboardModel,
                statusLabel: isDemoMode ? "Sample data" : nil
            )
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
            SettingsView(
                model: settingsModel,
                healthReceiver: healthReceiver,
                aiSettings: aiSettings
            )
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

@MainActor
private struct AppComposition {
    let dashboardModel: DashboardModel
    let settingsModel: SettingsModel
    let trendsModel: TrendsModel
    let explorerModel: ExplorerModel
    let healthReceiver: HealthBridgeReceiver
    let aiSettings: AISettingsModel
    let chatModel: ChatModel

    static func live() throws -> AppComposition {
        let authenticationService = WhoopBrokerAuthenticationService(
            brokerBaseURL: BrokerBaseURL.value,
            webAuthorizer: OAuthWebAuthorizer()
        )
        let database = try WhoopScopeDatabase.live()
        let apiClient = WhoopAPIClient { forceRefresh in
            try await authenticationService.accessToken(forceRefresh: forceRefresh)
        }
        let synchronizer = WhoopDataSynchronizer(
            apiClient: apiClient,
            database: database
        )
        let widgetPublisher = WidgetSnapshotPublisher()
        let aiSettings = AISettingsModel()
        return AppComposition(
            dashboardModel: DashboardModel(
                loadDashboard: LoadDashboard(
                    repository: LiveDashboardRepository(
                        synchronizer: synchronizer,
                        database: database
                    )
                ),
                snapshotDidLoad: widgetPublisher.publish
            ),
            settingsModel: SettingsModel(
                authenticationService: authenticationService,
                loadAccount: LoadWhoopAccount(
                    repository: LiveWhoopAccountRepository(
                        apiClient: apiClient,
                        database: database
                    )
                ),
                didSignOut: widgetPublisher.clear
            ),
            trendsModel: TrendsModel(
                loadTrends: LoadTrends(
                    repository: LiveTrendsRepository(
                        synchronizer: synchronizer,
                        database: database
                    )
                )
            ),
            explorerModel: ExplorerModel(
                loadExplorer: LoadExplorer(
                    repository: LiveExplorerRepository(
                        synchronizer: synchronizer,
                        database: database
                    )
                )
            ),
            healthReceiver: HealthBridgeReceiver { payload in
                try await database.saveHealthEnrichment(payload)
            },
            aiSettings: aiSettings,
            chatModel: ChatModel(database: database, settings: aiSettings)
        )
    }

    static func demo(now: Date = .now) throws -> AppComposition {
        let archive = FixtureWhoopData.archive(now: now)
        let database = try WhoopScopeDatabase.inMemory(seed: archive)
        let aiSettings = AISettingsModel()
        return AppComposition(
            dashboardModel: DashboardModel(
                loadDashboard: LoadDashboard(
                    repository: FixtureDashboardRepository(now: now)
                )
            ),
            settingsModel: SettingsModel(
                authenticationService: FixtureAuthenticationService(),
                loadAccount: LoadWhoopAccount(
                    repository: FixtureWhoopAccountRepository(account: archive.account)
                )
            ),
            trendsModel: TrendsModel(
                loadTrends: LoadTrends(
                    repository: FixtureTrendsRepository(archive: archive, now: now)
                )
            ),
            explorerModel: ExplorerModel(
                loadExplorer: LoadExplorer(
                    repository: FixtureExplorerRepository(archive: archive)
                )
            ),
            healthReceiver: HealthBridgeReceiver { _ in },
            aiSettings: aiSettings,
            chatModel: ChatModel(database: database, settings: aiSettings)
        )
    }
}
