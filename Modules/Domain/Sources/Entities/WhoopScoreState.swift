import Foundation

public enum WhoopScoreState: String, Codable, Equatable, Sendable {
    case scored = "SCORED"
    case pending = "PENDING_SCORE"
    case unscorable = "UNSCORABLE"
}
