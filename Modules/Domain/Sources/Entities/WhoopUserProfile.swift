import Foundation

public struct WhoopUserProfile: Equatable, Sendable {
    public let userID: Int64
    public let email: String
    public let firstName: String
    public let lastName: String

    public init(
        userID: Int64,
        email: String,
        firstName: String,
        lastName: String
    ) {
        self.userID = userID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }

    public var displayName: String {
        [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
