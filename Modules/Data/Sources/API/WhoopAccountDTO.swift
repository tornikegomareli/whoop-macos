import Foundation
import WhoopScopeDomain

struct WhoopUserProfileDTO: Decodable, Sendable {
    let userID: Int64
    let email: String
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case userID = "userId"
        case email
        case firstName
        case lastName
    }

    var domainValue: WhoopUserProfile {
        WhoopUserProfile(
            userID: userID,
            email: email,
            firstName: firstName,
            lastName: lastName
        )
    }
}

struct WhoopBodyMeasurementsDTO: Decodable, Sendable {
    let heightMeters: Double
    let weightKilograms: Double
    let maxHeartRate: Int

    enum CodingKeys: String, CodingKey {
        case heightMeters = "heightMeter"
        case weightKilograms = "weightKilogram"
        case maxHeartRate
    }

    var domainValue: WhoopBodyMeasurements {
        WhoopBodyMeasurements(
            heightMeters: heightMeters,
            weightKilograms: weightKilograms,
            maxHeartRate: maxHeartRate
        )
    }
}
