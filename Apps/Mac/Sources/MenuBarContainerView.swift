import SwiftUI
import WhoopScopeDashboard

struct MenuBarContainerView: View {
    let dashboardModel: DashboardModel
    let statusLabel: String?

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MenuBarSummaryView(
            model: dashboardModel,
            statusLabel: statusLabel,
            openDashboard: openDashboard
        )
    }

    private func openDashboard() {
        openWindow(id: "dashboard")
        NSApp.activate()
    }
}
