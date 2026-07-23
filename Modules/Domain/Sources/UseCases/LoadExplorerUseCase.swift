public protocol LoadExplorerUseCase: Sendable {
    func execute(refresh: Bool) async throws -> WhoopDataArchive
}
