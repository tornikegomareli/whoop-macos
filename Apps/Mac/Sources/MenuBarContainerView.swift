import SwiftUI
import WhoopScopeDashboard

struct MenuBarContainerView: View {
    let dashboardModel: DashboardModel

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MenuBarSummaryView(
            model: dashboardModel,
            openDashboard: openDashboard
        )
    }

    private func openDashboard() {
        openWindow(id: "dashboard")
        NSApp.activate()
    }
}

