import Foundation

public struct ChatMessage: Equatable, Identifiable, Sendable {
    public enum Role: Sendable {
        case user
        case assistant
    }

    public let id: UUID
    public let role: Role
    public let content: String
    public let createdAt: Date
    public let evidenceLabel: String?

    public init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        createdAt: Date = .now,
        evidenceLabel: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.evidenceLabel = evidenceLabel
    }
}
