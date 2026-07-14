import WhoopScopeDomain

public enum TrendsViewState: Equatable {
    case idle
    case loading
    case loaded(TrendsSnapshot)
    case failed(message: String)
}
