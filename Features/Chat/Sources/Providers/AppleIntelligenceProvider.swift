import Foundation
import FoundationModels

struct AppleIntelligenceProvider: AIChatProvider {
    func complete(_ request: AICompletionRequest) async throws -> String {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw AIProviderError.appleIntelligenceUnavailable(
                unavailableMessage(model.availability))
        }

        let session = LanguageModelSession(model: model, instructions: ChatInstructions.text)
        let response = try await session.respond(
            to: ChatInstructions.prompt(for: request),
            options: GenerationOptions(temperature: 0.2, maximumResponseTokens: 700)
        )
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func unavailableMessage(
        _ availability: SystemLanguageModel.Availability
    ) -> String {
        guard case .unavailable(let reason) = availability else {
            return "Apple Intelligence is unavailable right now."
        }
        switch reason {
        case .deviceNotEligible:
            return "This Mac cannot run Apple Intelligence. Choose OpenAI in Settings."
        case .appleIntelligenceNotEnabled:
            return "Enable Apple Intelligence in System Settings, or choose OpenAI."
        case .modelNotReady:
            return
                "The Apple Intelligence model is still downloading. Try again later or choose OpenAI."
        @unknown default:
            return "Apple Intelligence is unavailable right now. Choose OpenAI or try again later."
        }
    }
}
