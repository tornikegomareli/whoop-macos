import Foundation

enum AppDestination: String, CaseIterable, Identifiable {
    case today
    case trends
    case sleep
    case recovery
    case strain
    case workouts
    case chat
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .today: "Today"
        case .trends: "Trends"
        case .sleep: "Sleep"
        case .recovery: "Recovery"
        case .strain: "Strain & Cycles"
        case .workouts: "Workouts"
        case .chat: "Ask Your Data"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .today: "square.grid.2x2"
        case .trends: "chart.xyaxis.line"
        case .sleep: "moon.stars"
        case .recovery: "heart.text.square"
        case .strain: "bolt"
        case .workouts: "figure.run"
        case .chat: "sparkles"
        case .settings: "gearshape"
        }
    }
}

