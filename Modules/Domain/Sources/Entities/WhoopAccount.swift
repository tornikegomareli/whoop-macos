import Foundation

public struct WhoopAccount: Equatable, Sendable {
    public let profile: WhoopUserProfile
    public let bodyMeasurements: WhoopBodyMeasurements
    public let syncedAt: Date

    public init(
        profile: WhoopUserProfile,
        bodyMeasurements: WhoopBodyMeasurements,
        syncedAt: Date
    ) {
        self.profile = profile
        self.bodyMeasurements = bodyMeasurements
        self.syncedAt = syncedAt
    }
}
