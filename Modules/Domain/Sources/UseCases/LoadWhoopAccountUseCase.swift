import Foundation

public protocol LoadWhoopAccountUseCase: Sendable {
    func execute(refresh: Bool) async throws -> WhoopAccount?
}
