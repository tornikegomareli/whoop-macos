public protocol LoadTrendsUseCase: Sendable {
    func execute(range: TrendRange, refresh: Bool) async throws -> TrendsSnapshot
}
