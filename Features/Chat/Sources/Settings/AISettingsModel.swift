import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
public final class AISettingsModel {
    public var selectedProvider: AIProviderSelection {
        didSet { defaults.set(selectedProvider.rawValue, forKey: Keys.provider) }
    }
    public var openAIModel: String {
        didSet { defaults.set(openAIModel, forKey: Keys.model) }
    }
    public var apiKeyDraft = ""
    public private(set) var hasStoredOpenAIKey = false
    public private(set) var isWorking = false
    public private(set) var statusMessage: String?

    private let keyStore: OpenAIKeyStore
    private let defaults: UserDefaults

    public init(
        keyStore: OpenAIKeyStore = OpenAIKeyStore(),
        defaults: UserDefaults = .standard
    ) {
        self.keyStore = keyStore
        self.defaults = defaults
        selectedProvider =
            defaults.string(forKey: Keys.provider)
            .flatMap(AIProviderSelection.init(rawValue:)) ?? .appleIntelligence
        openAIModel = defaults.string(forKey: Keys.model) ?? "gpt-5.4-mini"
    }

    public var configuration: AIProviderConfiguration {
        AIProviderConfiguration(
            selection: selectedProvider,
            openAIModel: openAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    public var appleIntelligenceStatus: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            "Available on this Mac"
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: "This Mac is not eligible"
            case .appleIntelligenceNotEnabled: "Enable Apple Intelligence in System Settings"
            case .modelNotReady: "The on-device model is still downloading"
            @unknown default: "Apple Intelligence is unavailable right now"
            }
        }
    }

    public func load() async {
        do {
            hasStoredOpenAIKey = try await keyStore.read() != nil
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    public func saveOpenAIKey() async {
        let key = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            statusMessage = "Enter an OpenAI API key first."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await keyStore.save(key)
            apiKeyDraft = ""
            hasStoredOpenAIKey = true
            statusMessage = "OpenAI API key saved in Keychain."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    public func removeOpenAIKey() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await keyStore.delete()
            apiKeyDraft = ""
            hasStoredOpenAIKey = false
            statusMessage = "OpenAI API key removed."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    public func openAIKey() async throws -> String {
        guard let key = try await keyStore.read(), !key.isEmpty else {
            throw AIProviderError.missingOpenAIKey
        }
        return key
    }

    private enum Keys {
        static let provider = "ai.provider"
        static let model = "ai.openai.model"
    }
}
