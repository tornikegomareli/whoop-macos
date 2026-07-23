public protocol ExplorerRepository: Sendable {
    func archive(refresh: Bool) async throws -> WhoopDataArchive
}
