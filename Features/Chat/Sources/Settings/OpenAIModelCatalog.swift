import Foundation

public struct OpenAIModelOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let owner: String

    public init(id: String, owner: String) {
        self.id = id
        self.owner = owner
    }
}

public protocol OpenAIModelListing: Sendable {
    func listModels(apiKey: String) async throws -> [OpenAIModelOption]
}

public struct OpenAIModelCatalog: OpenAIModelListing, Sendable {
    private let dataLoader:
        @Sendable (URLRequest) async throws -> (Data, URLResponse)

    public init(session: URLSession = .shared) {
        dataLoader = { request in
            try await session.data(for: request)
        }
    }

    init(
        dataLoader: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)
    ) {
        self.dataLoader = dataLoader
    }

    public func listModels(apiKey: String) async throws -> [OpenAIModelOption] {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await dataLoader(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidOpenAIResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message =
                (try? JSONDecoder().decode(OpenAIModelErrorEnvelope.self, from: data))?
                .error.message ?? "HTTP \(httpResponse.statusCode)"
            throw AIProviderError.openAIModelListFailed(message)
        }

        let envelope = try JSONDecoder().decode(OpenAIModelListEnvelope.self, from: data)
        return envelope.data
            .filter { Self.isCompatibleTextModel($0.id) }
            .map { OpenAIModelOption(id: $0.id, owner: $0.ownedBy) }
            .sorted { left, right in
                left.id.localizedStandardCompare(right.id) == .orderedDescending
            }
    }

    static func isCompatibleTextModel(_ modelID: String) -> Bool {
        let id = modelID.lowercased()
        let incompatibleFamilies = [
            "audio",
            "computer-use",
            "dall-e",
            "embedding",
            "image",
            "moderation",
            "realtime",
            "sora",
            "transcribe",
            "tts",
            "whisper",
        ]

        guard !incompatibleFamilies.contains(where: id.contains) else {
            return false
        }
        return id != "babbage-002" && id != "davinci-002"
    }
}

private struct OpenAIModelListEnvelope: Decodable {
    struct Model: Decodable {
        let id: String
        let ownedBy: String

        enum CodingKeys: String, CodingKey {
            case id
            case ownedBy = "owned_by"
        }
    }

    let data: [Model]
}

private struct OpenAIModelErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}
