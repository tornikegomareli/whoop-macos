import Foundation

struct AICompletionRequest: Sendable {
    let question: String
    let conversation: String
    let evidence: String
}

protocol AIChatProvider: Sendable {
    func complete(_ request: AICompletionRequest) async throws -> String
}

enum ChatInstructions {
    static let text = """
        You are WhoopScope, a careful analyst of the user's own fitness and wellness data.
        Answer only from the EVIDENCE supplied with the request. Never invent a value, date, workout, or causal explanation.
        State the exact comparison periods when comparing trends. Distinguish association from causation.
        Keep answers concise but useful, normally two to five short paragraphs or a few bullets.
        If the evidence cannot answer the question, say what is missing. Do not diagnose, prescribe, or present medical advice.
        WHOOP is the sole source for sleep and recovery. Apple Health evidence is complementary and never supplies sleep.
        """

    static func prompt(for request: AICompletionRequest) -> String {
        """
        RECENT CONVERSATION:
        \(request.conversation.isEmpty ? "None" : request.conversation)

        QUESTION:
        \(request.question)

        EVIDENCE:
        \(request.evidence)
        """
    }
}
