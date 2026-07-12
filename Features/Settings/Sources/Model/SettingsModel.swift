import Foundation
import Observation
import WhoopScopeDomain

@MainActor
@Observable
public final class SettingsModel {
    public private(set) var authenticationStatus: AuthenticationStatus?
    public private(set) var account: WhoopAccount?
    public private(set) var isWorking = false
    public private(set) var errorMessage: String?

    private let authenticationService: any AuthenticationService
    private let loadAccount: (any LoadWhoopAccountUseCase)?

    public init(
        authenticationService: any AuthenticationService,
        loadAccount: (any LoadWhoopAccountUseCase)? = nil
    ) {
        self.authenticationService = authenticationService
        self.loadAccount = loadAccount
    }

    public func load() async {
        authenticationStatus = await authenticationService.status()
        if authenticationStatus == .signedIn {
            await refreshAccount()
        }
    }

    @discardableResult
    public func signIn() async -> Bool {
        guard !isWorking else { return false }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await authenticationService.signIn()
            authenticationStatus = .signedIn
            await refreshAccount()
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            authenticationStatus = .signedOut
            return false
        }
    }

    public func signOut() async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            try await authenticationService.signOut()
            authenticationStatus = .signedOut
            account = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            authenticationStatus = .signedOut
            account = nil
        }
    }

    private func refreshAccount() async {
        guard let loadAccount else { return }
        do {
            if account == nil {
                account = try await loadAccount.execute(refresh: false)
            }
            account = try await loadAccount.execute(refresh: true)
        } catch is CancellationError {
            return
        } catch let error as AuthenticationError {
            errorMessage = error.localizedDescription
            if error == .sessionExpired || error == .invalidCredentials {
                authenticationStatus = .signedOut
                account = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
