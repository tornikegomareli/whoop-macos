import Foundation
import Observation
import WhoopScopePersistence

@MainActor
@Observable
public final class ChatModel {
    public var draft = ""
    public private(set) var messages: [ChatMessage] = []
    public private(set) var isResponding = false
    public private(set) var errorMessage: String?

    public let settings: AISettingsModel
    private let grounding: GroundingContextBuilder

    public init(database: WhoopScopeDatabase, settings: AISettingsModel) {
        grounding = GroundingContextBuilder(database: database)
        self.settings = settings
    }

    public func sendDraft() {
        send(draft)
    }

    public func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isResponding else { return }
        draft = ""
        errorMessage = nil
        messages.append(ChatMessage(role: .user, content: question))
        isResponding = true

        let previousQuestion = messages.dropLast().last(where: { $0.role == .user })?.content
        let groundingQuestion = [previousQuestion, question].compactMap { $0 }.joined(
            separator: " ")
        let conversation = messages.dropLast().suffix(6).map { message in
            "\(message.role == .user ? "User" : "WhoopScope"): \(message.content)"
        }.joined(separator: "\n")
        let configuration = settings.configuration

        Task {
            defer { isResponding = false }
            do {
                let evidence = try await grounding.build(question: groundingQuestion)
                let request = AICompletionRequest(
                    question: question,
                    conversation: conversation,
                    evidence: evidence.content
                )
                let answer: String
                switch configuration.selection {
                case .appleIntelligence:
                    answer = try await AppleIntelligenceProvider().complete(request)
                case .openAI:
                    let key = try await settings.openAIKey()
                    answer = try await OpenAIProvider(
                        apiKey: key,
                        model: configuration.openAIModel
                    ).complete(request)
                }
                messages.append(
                    ChatMessage(
                        role: .assistant,
                        content: answer,
                        evidenceLabel: evidence.label
                    )
                )
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    public func clearConversation() {
        guard !isResponding else { return }
        messages.removeAll()
        errorMessage = nil
    }
}
