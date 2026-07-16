import SwiftUI

@main
struct WhoopScopeCompanionApp: App {
    @State private var model = CompanionModel()

    var body: some Scene {
        WindowGroup {
            CompanionView(model: model)
        }
    }
}
