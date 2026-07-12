import Foundation
import Testing
@testable import WhoopScopeAuthentication

@Test
func brokerConfigurationBuildsWHOOPAuthorizationURL() throws {
    let json = Data(
        """
        {
          "client_id": "public-client-id",
          "authorization_url": "https://api.prod.whoop.com/oauth/oauth2/auth",
          "redirect_uri": "whoopscope://oauth/callback",
          "callback_scheme": "whoopscope",
          "scopes": ["offline", "read:profile", "read:sleep"]
        }
        """.utf8
    )
    let configuration = try JSONDecoder().decode(
        BrokerPublicConfiguration.self,
        from: json
    )
    let url = try configuration.authorizationURL(state: "12345678")
    let components = try #require(
        URLComponents(url: url, resolvingAgainstBaseURL: false)
    )
    let values = Dictionary(
        uniqueKeysWithValues: components.queryItems?.compactMap { item in
            item.value.map { (item.name, $0) }
        } ?? []
    )

    #expect(values["client_id"] == "public-client-id")
    #expect(values["redirect_uri"] == "whoopscope://oauth/callback")
    #expect(values["state"] == "12345678")
    #expect(values["scope"] == "offline read:profile read:sleep")
}

