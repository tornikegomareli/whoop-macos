import Foundation
import Testing

@testable import WhoopScopeChat

@Test
func modelCatalogLoadsAccountModelsAndFiltersIncompatibleFamilies() async throws {
    let responseData = Data(
        #"""
        {
          "object": "list",
          "data": [
            { "id": "gpt-5.4-mini", "object": "model", "created": 1, "owned_by": "system" },
            { "id": "ft:gpt-4.1-mini:personal:coach:123", "object": "model", "created": 2, "owned_by": "personal" },
            { "id": "text-embedding-3-large", "object": "model", "created": 3, "owned_by": "system" },
            { "id": "gpt-image-1", "object": "model", "created": 4, "owned_by": "system" },
            { "id": "omni-moderation-latest", "object": "model", "created": 5, "owned_by": "system" },
            { "id": "whisper-1", "object": "model", "created": 6, "owned_by": "system" },
            { "id": "babbage-002", "object": "model", "created": 7, "owned_by": "system" }
          ]
        }
        """#.utf8
    )
    let response = HTTPURLResponse(
        url: URL(string: "https://api.openai.com/v1/models")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!
    let probe = OpenAIRequestProbe()
    let catalog = OpenAIModelCatalog { request in
        await probe.record(request)
        return (responseData, response)
    }

    let models = try await catalog.listModels(apiKey: "test-api-key")

    #expect(models.map(\.id) == [
        "gpt-5.4-mini",
        "ft:gpt-4.1-mini:personal:coach:123",
    ])
    #expect(await probe.url == URL(string: "https://api.openai.com/v1/models"))
    #expect(await probe.authorization == "Bearer test-api-key")
}

@Test
func modelCatalogSurfacesOpenAIErrorMessage() async {
    let responseData = Data(
        #"""
        {
          "error": {
            "message": "Incorrect API key provided."
          }
        }
        """#.utf8
    )
    let response = HTTPURLResponse(
        url: URL(string: "https://api.openai.com/v1/models")!,
        statusCode: 401,
        httpVersion: nil,
        headerFields: nil
    )!
    let catalog = OpenAIModelCatalog { _ in
        (responseData, response)
    }

    await #expect(throws: AIProviderError.self) {
        _ = try await catalog.listModels(apiKey: "invalid")
    }
}

@Test
@MainActor
func settingsSelectsAnAvailableModelWhenTheSavedModelNoLongerExists() async {
    let suiteName = "OpenAIModelCatalogTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    defaults.set("retired-model", forKey: "ai.openai.model")

    let model = AISettingsModel(
        keyStore: InMemoryOpenAIKeyStore(key: "test-api-key"),
        modelCatalog: StubOpenAIModelCatalog(
            models: [
                OpenAIModelOption(id: "gpt-5.4-mini", owner: "system"),
                OpenAIModelOption(id: "gpt-5.4", owner: "system"),
            ]
        ),
        defaults: defaults
    )

    await model.load()

    #expect(model.hasStoredOpenAIKey)
    #expect(model.openAIModel == "gpt-5.4-mini")
    #expect(model.availableOpenAIModels.count == 2)
    #expect(model.modelCatalogError == nil)
}

private actor OpenAIRequestProbe {
    private(set) var url: URL?
    private(set) var authorization: String?

    func record(_ request: URLRequest) {
        url = request.url
        authorization = request.value(forHTTPHeaderField: "Authorization")
    }
}

private actor InMemoryOpenAIKeyStore: OpenAIKeyStoring {
    private var key: String?

    init(key: String?) {
        self.key = key
    }

    func save(_ key: String) async throws {
        self.key = key
    }

    func read() async throws -> String? {
        key
    }

    func delete() async throws {
        key = nil
    }
}

private struct StubOpenAIModelCatalog: OpenAIModelListing {
    let models: [OpenAIModelOption]

    func listModels(apiKey: String) async throws -> [OpenAIModelOption] {
        models
    }
}
