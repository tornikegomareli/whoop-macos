import WhoopScopeDomain

struct StaticDashboardRepository: DashboardRepository {
    let snapshot: DashboardSnapshot

    func dashboard() async throws -> DashboardSnapshot {
        snapshot
    }
}

