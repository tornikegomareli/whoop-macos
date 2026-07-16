import Foundation

public enum AIProviderError: LocalizedError, Equatable {
    case appleIntelligenceUnavailable(String)
    case missingOpenAIKey
    case invalidOpenAIResponse
    case openAIRequestFailed(String)
    case secureStorageFailure
    case noSynchronizedData

    public var errorDescription: String? {
        switch self {
        case .appleIntelligenceUnavailable(let reason): reason
        case .missingOpenAIKey: "Add your OpenAI API key in Settings before using OpenAI."
        case .invalidOpenAIResponse: "OpenAI returned a response WhoopScope could not read."
        case .openAIRequestFailed(let message): "OpenAI could not answer: \(message)"
        case .secureStorageFailure: "WhoopScope could not access the API key in Keychain."
        case .noSynchronizedData:
            "Sync your WHOOP dashboard before asking questions about your data."
        }
    }
}
