public struct LoadExplorer: LoadExplorerUseCase, Sendable {
    private let repository: any ExplorerRepository

    public init(repository: any ExplorerRepository) {
        self.repository = repository
    }

    public func execute(refresh: Bool) async throws -> WhoopDataArchive {
        try await repository.archive(refresh: refresh)
    }
}
