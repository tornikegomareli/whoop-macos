import AuthenticationServices
import Foundation
import Testing
@testable import WhoopScopeAuthentication
import WhoopScopeDomain

@Test
func oauthCallbackCanArriveOffMainActor() async throws {
    let expectedURL = try #require(URL(string: "whoopscope://oauth/callback?code=test"))

    let callbackURL = try await withCheckedThrowingContinuation { continuation in
        let handler = OAuthCallbackBridge.makeHandler(
            continuation: continuation,
            didFinish: {}
        )
        Task { @concurrent in
            handler(expectedURL, nil)
        }
    }

    #expect(callbackURL == expectedURL)
}

@Test
func oauthCancellationBecomesAuthorizationDenied() async throws {
    await #expect(throws: AuthenticationError.authorizationDenied) {
        try await withCheckedThrowingContinuation { continuation in
            let handler = OAuthCallbackBridge.makeHandler(
                continuation: continuation,
                didFinish: {}
            )
            handler(nil, ASWebAuthenticationSessionError(.canceledLogin))
        } as URL
    }
}
