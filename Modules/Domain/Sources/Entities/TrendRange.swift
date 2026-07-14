import Foundation

public enum TrendRange: Int, CaseIterable, Identifiable, Equatable, Sendable {
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90

    public var id: Self { self }
    public var dayCount: Int { rawValue }

    public var shortTitle: String {
        switch self {
        case .sevenDays: "7D"
        case .thirtyDays: "30D"
        case .ninetyDays: "90D"
        }
    }

    public var title: String {
        switch self {
        case .sevenDays: "7 days"
        case .thirtyDays: "30 days"
        case .ninetyDays: "90 days"
        }
    }
}
