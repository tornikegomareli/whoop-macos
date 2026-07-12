import WhoopScopeDomain

actor FakeAuthenticationService: AuthenticationService {
    private(set) var currentStatus: AuthenticationStatus
    private(set) var signInCount = 0

    init(status: AuthenticationStatus = .signedOut) {
        currentStatus = status
    }

    func status() async -> AuthenticationStatus {
        currentStatus
    }

    func signIn() async throws {
        signInCount += 1
        currentStatus = .signedIn
    }

    func signOut() async throws {
        currentStatus = .signedOut
    }
}
