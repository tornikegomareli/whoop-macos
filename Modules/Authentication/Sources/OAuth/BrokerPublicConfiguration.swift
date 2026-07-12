import Foundation
import WhoopScopeDomain

struct BrokerPublicConfiguration: Decodable, Equatable, Sendable {
    let clientID: String
    let authorizationURL: URL
    let redirectURI: String
    let callbackScheme: String
    let scopes: [String]

    private enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case authorizationURL = "authorization_url"
        case redirectURI = "redirect_uri"
        case callbackScheme = "callback_scheme"
        case scopes
    }

    func authorizationURL(state: String) throws -> URL {
        guard var components = URLComponents(
            url: authorizationURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw AuthenticationError.invalidCallback
        }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
        ]
        guard let url = components.url else {
            throw AuthenticationError.invalidCallback
        }
        return url
    }
}

