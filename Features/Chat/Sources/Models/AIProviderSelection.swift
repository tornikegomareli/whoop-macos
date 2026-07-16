import Foundation

public enum AIProviderSelection: String, CaseIterable, Identifiable, Sendable {
    case appleIntelligence
    case openAI

    public var id: Self { self }

    public var title: String {
        switch self {
        case .appleIntelligence: "Apple Intelligence"
        case .openAI: "OpenAI"
        }
    }

    public var privacySummary: String {
        switch self {
        case .appleIntelligence:
            "Answers are generated on this Mac. Your health data stays on-device."
        case .openAI:
            "The grounded evidence for each question is sent directly to OpenAI using your API key."
        }
    }
}

public struct AIProviderConfiguration: Sendable {
    public let selection: AIProviderSelection
    public let openAIModel: String

    public init(selection: AIProviderSelection, openAIModel: String) {
        self.selection = selection
        self.openAIModel = openAIModel
    }
}
