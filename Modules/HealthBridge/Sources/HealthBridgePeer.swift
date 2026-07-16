import Foundation

public struct HealthBridgePeer: Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public enum HealthBridgeConnectionState: Equatable, Sendable {
    case searching
    case connecting(String)
    case connected(String)
    case transferring(String)
    case completed(String)
    case failed(String)
}
