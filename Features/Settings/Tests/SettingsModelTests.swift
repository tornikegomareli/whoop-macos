import Testing
@testable import WhoopScopeSettings
import WhoopScopeDomain

@MainActor
@Test
func settingsModelConnectsThroughAuthenticationService() async {
    let service = FakeAuthenticationService()
    let model = SettingsModel(authenticationService: service)

    let connected = await model.signIn()

    #expect(connected)
    #expect(model.authenticationStatus == .signedIn)
    #expect(await service.signInCount == 1)
}

@MainActor
@Test
func expiredSessionReturnsSettingsToSignedOutState() async {
    let service = FakeAuthenticationService(status: .signedIn)
    let model = SettingsModel(
        authenticationService: service,
        loadAccount: ExpiredAccountLoader()
    )

    await model.load()

    #expect(model.authenticationStatus == .signedOut)
    #expect(model.errorMessage == AuthenticationError.sessionExpired.localizedDescription)
}

private struct ExpiredAccountLoader: LoadWhoopAccountUseCase {
    func execute(refresh: Bool) async throws -> WhoopAccount? {
        throw AuthenticationError.sessionExpired
    }
}
