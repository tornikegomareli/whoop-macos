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
    public private(set) var isLoadingOpenAIModels = false
    public private(set) var availableOpenAIModels: [OpenAIModelOption] = []
    public private(set) var modelCatalogError: String?
    public private(set) var statusMessage: String?

    private let keyStore: any OpenAIKeyStoring
    private let modelCatalog: any OpenAIModelListing
    private let defaults: UserDefaults

    public init(
        keyStore: any OpenAIKeyStoring = OpenAIKeyStore(),
        modelCatalog: any OpenAIModelListing = OpenAIModelCatalog(),
        defaults: UserDefaults = .standard
    ) {
        self.keyStore = keyStore
        self.modelCatalog = modelCatalog
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

    public var modelPickerOptions: [OpenAIModelOption] {
        guard !availableOpenAIModels.contains(where: { $0.id == openAIModel }) else {
            return availableOpenAIModels
        }
        return [
            OpenAIModelOption(id: openAIModel, owner: "Previously selected")
        ] + availableOpenAIModels
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
            guard let key = try await keyStore.read(), !key.isEmpty else {
                hasStoredOpenAIKey = false
                availableOpenAIModels = []
                modelCatalogError = nil
                return
            }
            hasStoredOpenAIKey = true
            await loadOpenAIModels(apiKey: key)
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
            await loadOpenAIModels(apiKey: key)
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
            availableOpenAIModels = []
            modelCatalogError = nil
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

    public func reloadOpenAIModels() async {
        do {
            let key = try await openAIKey()
            await loadOpenAIModels(apiKey: key)
        } catch {
            modelCatalogError = error.localizedDescription
        }
    }

    private func loadOpenAIModels(apiKey: String) async {
        guard !isLoadingOpenAIModels else { return }
        isLoadingOpenAIModels = true
        defer { isLoadingOpenAIModels = false }

        do {
            let models = try await modelCatalog.listModels(apiKey: apiKey)
            guard !models.isEmpty else {
                availableOpenAIModels = []
                modelCatalogError = "OpenAI did not return any compatible text models."
                return
            }

            availableOpenAIModels = models
            modelCatalogError = nil
            if !models.contains(where: { $0.id == openAIModel }) {
                openAIModel = models[0].id
            }
        } catch {
            modelCatalogError = error.localizedDescription
        }
    }

    private enum Keys {
        static let provider = "ai.provider"
        static let model = "ai.openai.model"
    }
}
