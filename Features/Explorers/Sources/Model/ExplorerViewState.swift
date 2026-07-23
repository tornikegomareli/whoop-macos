public enum ExplorerViewState: Equatable {
    case idle
    case loading
    case loaded(ExplorerSnapshot)
    case failed(message: String)
}
