public protocol TrendsRepository: Sendable {
    func trends(range: TrendRange, refresh: Bool) async throws -> TrendsSnapshot
}
