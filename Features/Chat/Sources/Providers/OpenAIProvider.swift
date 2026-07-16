import Foundation

struct OpenAIProvider: AIChatProvider {
    let apiKey: String
    let model: String
    var session: URLSession = .shared

    func complete(_ request: AICompletionRequest) async throws -> String {
        var urlRequest = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(
            OpenAIRequestBody(
                model: model,
                instructions: ChatInstructions.text,
                input: ChatInstructions.prompt(for: request),
                maxOutputTokens: 900,
                store: false
            )
        )

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidOpenAIResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message =
                (try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data))?
                .error.message ?? "HTTP \(httpResponse.statusCode)"
            throw AIProviderError.openAIRequestFailed(message)
        }

        return try Self.responseText(from: data)
    }

    static func responseText(from data: Data) throws -> String {
        let envelope = try JSONDecoder().decode(OpenAIResponseEnvelope.self, from: data)
        let text = envelope.output
            .flatMap { $0.content ?? [] }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw AIProviderError.invalidOpenAIResponse }
        return text
    }
}

private struct OpenAIRequestBody: Encodable {
    let model: String
    let instructions: String
    let input: String
    let maxOutputTokens: Int
    let store: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case instructions
        case input
        case maxOutputTokens = "max_output_tokens"
        case store
    }
}

private struct OpenAIResponseEnvelope: Decodable {
    struct Output: Decodable {
        struct Content: Decodable {
            let type: String
            let text: String?
        }

        let type: String
        let content: [Content]?
    }

    let output: [Output]
}

private struct OpenAIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}
