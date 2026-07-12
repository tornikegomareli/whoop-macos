import Foundation
import Testing
@testable import WhoopScopeDomain

@Test
func loadWHOOPAccountUsesStoredDataWhenRefreshIsFalse() async throws {
    let expected = testWHOOPAccount
    let repository = StubWhoopAccountRepository(account: expected)
    let useCase = LoadWhoopAccount(repository: repository)

    let account = try await useCase.execute(refresh: false)

    #expect(account == expected)
    #expect(await repository.storedCount == 1)
    #expect(await repository.refreshCount == 0)
}

@Test
func loadWHOOPAccountRefreshesWhenRequested() async throws {
    let expected = testWHOOPAccount
    let repository = StubWhoopAccountRepository(account: expected)
    let useCase = LoadWhoopAccount(repository: repository)

    let account = try await useCase.execute(refresh: true)

    #expect(account == expected)
    #expect(await repository.storedCount == 0)
    #expect(await repository.refreshCount == 1)
}

private actor StubWhoopAccountRepository: WhoopAccountRepository {
    let account: WhoopAccount
    private(set) var storedCount = 0
    private(set) var refreshCount = 0

    init(account: WhoopAccount) {
        self.account = account
    }

    func storedAccount() async throws -> WhoopAccount? {
        storedCount += 1
        return account
    }

    func refreshAccount() async throws -> WhoopAccount {
        refreshCount += 1
        return account
    }
}

private let testWHOOPAccount = WhoopAccount(
    profile: WhoopUserProfile(
        userID: 42,
        email: "taylor@example.com",
        firstName: "Taylor",
        lastName: "Example"
    ),
    bodyMeasurements: WhoopBodyMeasurements(
        heightMeters: 1.8,
        weightKilograms: 75,
        maxHeartRate: 195
    ),
    syncedAt: Date(timeIntervalSince1970: 1_700_000_000)
)
