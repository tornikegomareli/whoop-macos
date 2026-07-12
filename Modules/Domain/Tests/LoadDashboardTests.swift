import Testing
import WhoopScopeDomain

@Test
func loadDashboardReturnsRepositorySnapshot() async throws {
    let expected = TestDashboardSnapshot.value
    let repository = StaticDashboardRepository(snapshot: expected)
    let useCase = LoadDashboard(repository: repository)

    let result = try await useCase.execute()

    #expect(result == expected)
}

