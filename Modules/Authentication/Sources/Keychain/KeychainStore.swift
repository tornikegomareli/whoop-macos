import Foundation
import Security
import WhoopScopeDomain

actor KeychainStore {
    private let service: String

    init(service: String = "com.whoopscope.credentials") {
        self.service = service
    }

    func save<Value: Encodable & Sendable>(
        _ value: Value,
        as item: KeychainItem
    ) throws {
        let data = try JSONEncoder().encode(value)
        let query = baseQuery(for: item)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addition = query
            addition.merge(attributes) { _, new in new }
            guard SecItemAdd(addition as CFDictionary, nil) == errSecSuccess else {
                throw AuthenticationError.keychainFailure
            }
        } else if status != errSecSuccess {
            throw AuthenticationError.keychainFailure
        }
    }

    func read<Value: Decodable & Sendable>(
        _ type: Value.Type,
        for item: KeychainItem
    ) throws -> Value? {
        var query = baseQuery(for: item)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw AuthenticationError.keychainFailure
        }
        return try JSONDecoder().decode(type, from: data)
    }

    func delete(_ item: KeychainItem) throws {
        let status = SecItemDelete(baseQuery(for: item) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthenticationError.keychainFailure
        }
    }

    private func baseQuery(for item: KeychainItem) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: item.rawValue,
        ]
    }
}

