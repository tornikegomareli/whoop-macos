import Foundation

public protocol WhoopAccountRepository: Sendable {
    func storedAccount() async throws -> WhoopAccount?
    func refreshAccount() async throws -> WhoopAccount
}
