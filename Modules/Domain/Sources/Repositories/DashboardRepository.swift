import Foundation

public protocol DashboardRepository: Sendable {
    func dashboard() async throws -> DashboardSnapshot
}

