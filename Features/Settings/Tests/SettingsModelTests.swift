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
    let recorder = SignOutRecorder()
    let model = SettingsModel(
        authenticationService: service,
        loadAccount: ExpiredAccountLoader(),
        didSignOut: recorder.record
    )

    await model.load()

    #expect(model.authenticationStatus == .signedOut)
    #expect(model.errorMessage == AuthenticationError.sessionExpired.localizedDescription)
    #expect(recorder.count == 1)
}

@MainActor
private final class SignOutRecorder {
    private(set) var count = 0

    func record() {
        count += 1
    }
}

private struct ExpiredAccountLoader: LoadWhoopAccountUseCase {
    func execute(refresh: Bool) async throws -> WhoopAccount? {
        throw AuthenticationError.sessionExpired
    }
}
