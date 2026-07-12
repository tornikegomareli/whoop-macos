import Foundation
import Testing
@testable import WhoopScopeAuthentication

@MainActor
@Test
func concurrentTokenRequestsShareOneRefreshOperation() async throws {
    let coordinator = OAuthTokenRefreshCoordinator()
    let counter = RefreshCounter()

    async let first = coordinator.tokenSet {
        await counter.increment()
        try await Task.sleep(for: .milliseconds(50))
        return testTokenSet
    }
    async let second = coordinator.tokenSet {
        await counter.increment()
        return testTokenSet
    }

    let values = try await [first, second]

    #expect(values == [testTokenSet, testTokenSet])
    #expect(await counter.value == 1)
}

private actor RefreshCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

private let testTokenSet = OAuthTokenSet(
    accessToken: "access",
    refreshToken: "refresh",
    expiresAt: Date(timeIntervalSince1970: 1_800_000_000),
    scope: "offline read:profile",
    tokenType: "bearer"
)
