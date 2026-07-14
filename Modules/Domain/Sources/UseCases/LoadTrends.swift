public struct LoadTrends: LoadTrendsUseCase, Sendable {
    private let repository: any TrendsRepository

    public init(repository: any TrendsRepository) {
        self.repository = repository
    }

    public func execute(range: TrendRange, refresh: Bool) async throws -> TrendsSnapshot {
        try await repository.trends(range: range, refresh: refresh)
    }
}
