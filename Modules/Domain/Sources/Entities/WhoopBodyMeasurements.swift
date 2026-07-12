import Foundation

public struct WhoopBodyMeasurements: Equatable, Sendable {
    public let heightMeters: Double
    public let weightKilograms: Double
    public let maxHeartRate: Int

    public init(
        heightMeters: Double,
        weightKilograms: Double,
        maxHeartRate: Int
    ) {
        self.heightMeters = heightMeters
        self.weightKilograms = weightKilograms
        self.maxHeartRate = maxHeartRate
    }
}
