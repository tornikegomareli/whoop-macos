import Foundation

public protocol LoadDashboardUseCase: Sendable {
    func execute() async throws -> DashboardSnapshot
}

