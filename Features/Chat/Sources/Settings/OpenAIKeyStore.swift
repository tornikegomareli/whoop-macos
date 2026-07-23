import Foundation
import Security

public protocol OpenAIKeyStoring: Sendable {
    func save(_ key: String) async throws
    func read() async throws -> String?
    func delete() async throws
}

public actor OpenAIKeyStore: OpenAIKeyStoring {
    private let service = "com.whoopscope.credentials"
    private let account = "openai-api-key"

    public init() {}

    public func save(_ key: String) async throws {
        let data = Data(key.utf8)
        let query = baseQuery
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addition = query
            addition.merge(attributes) { _, new in new }
            guard SecItemAdd(addition as CFDictionary, nil) == errSecSuccess else {
                throw AIProviderError.secureStorageFailure
            }
        } else if updateStatus != errSecSuccess {
            throw AIProviderError.secureStorageFailure
        }
    }

    public func read() async throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            throw AIProviderError.secureStorageFailure
        }
        return value
    }

    public func delete() async throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AIProviderError.secureStorageFailure
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
