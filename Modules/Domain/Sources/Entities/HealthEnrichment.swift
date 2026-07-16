import Foundation

public enum HealthMetricKind: String, CaseIterable, Codable, Sendable {
    case steps
    case walkingRunningDistance
    case flightsClimbed
    case exerciseMinutes
    case standMinutes
    case mindfulMinutes
    case dietaryWater
    case vo2Max
    case walkingSpeed
    case walkingStepLength
    case walkingAsymmetry
    case walkingDoubleSupport
    case bodyFatPercentage
    case leanBodyMass
    case waistCircumference

    public var displayName: String {
        switch self {
        case .steps: "Steps"
        case .walkingRunningDistance: "Walking + running distance"
        case .flightsClimbed: "Flights climbed"
        case .exerciseMinutes: "Exercise time"
        case .standMinutes: "Stand time"
        case .mindfulMinutes: "Mindful time"
        case .dietaryWater: "Water"
        case .vo2Max: "Cardio fitness"
        case .walkingSpeed: "Walking speed"
        case .walkingStepLength: "Walking step length"
        case .walkingAsymmetry: "Walking asymmetry"
        case .walkingDoubleSupport: "Walking double support"
        case .bodyFatPercentage: "Body fat"
        case .leanBodyMass: "Lean body mass"
        case .waistCircumference: "Waist circumference"
        }
    }
}

public struct HealthMetricSample: Codable, Equatable, Identifiable, Sendable {
    public let kind: HealthMetricKind
    public let date: Date
    public let value: Double
    public let unit: String
    public let source: String

    public var id: String {
        "\(kind.rawValue)|\(date.timeIntervalSince1970)|\(source)"
    }

    public init(
        kind: HealthMetricKind,
        date: Date,
        value: Double,
        unit: String,
        source: String
    ) {
        self.kind = kind
        self.date = date
        self.value = value
        self.unit = unit
        self.source = source
    }
}

public struct HealthEnrichmentPayload: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let deviceName: String
    public let samples: [HealthMetricSample]

    public init(
        generatedAt: Date,
        deviceName: String,
        samples: [HealthMetricSample]
    ) {
        self.generatedAt = generatedAt
        self.deviceName = deviceName
        self.samples = samples
    }
}
