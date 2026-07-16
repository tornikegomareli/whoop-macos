import Foundation
import WhoopScopeDomain

struct HealthBridgeMessage: Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case enrichment
        case acknowledgement
        case failure
    }

    let kind: Kind
    let payload: HealthEnrichmentPayload?
    let message: String?

    static func enrichment(_ payload: HealthEnrichmentPayload) -> Self {
        Self(kind: .enrichment, payload: payload, message: nil)
    }

    static func acknowledgement(_ message: String) -> Self {
        Self(kind: .acknowledgement, payload: nil, message: message)
    }

    static func failure(_ message: String) -> Self {
        Self(kind: .failure, payload: nil, message: message)
    }
}

enum HealthBridgeCodec {
    static func encode(_ message: HealthBridgeMessage) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(message)
    }

    static func decode(_ data: Data) throws -> HealthBridgeMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(HealthBridgeMessage.self, from: data)
    }
}
