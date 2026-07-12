import WhoopScopeDomain

public enum DashboardViewState: Equatable {
    case idle
    case loading
    case loaded(DashboardSnapshot)
    case failed(message: String)
}

