import Foundation

struct OAuthTokenSet: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let scope: String
    let tokenType: String
}

