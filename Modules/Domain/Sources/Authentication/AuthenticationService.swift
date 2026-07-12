import Foundation

public protocol AuthenticationService: Sendable {
    func status() async -> AuthenticationStatus
    func signIn() async throws
    func signOut() async throws
}
