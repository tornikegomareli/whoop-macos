import Foundation

public struct LoadDashboard: LoadDashboardUseCase {
    private let repository: any DashboardRepository

    public init(repository: any DashboardRepository) {
        self.repository = repository
    }

    public func execute() async throws -> DashboardSnapshot {
        try Task.checkCancellation()
        return try await repository.dashboard()
    }
}

