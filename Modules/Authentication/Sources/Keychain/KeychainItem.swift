import Foundation

enum KeychainItem: String, Sendable {
    case installationID = "app.installation-id"
    case legacyClientCredentials = "whoop.client-credentials"
    case tokenSet = "whoop.token-set"
}
