import Foundation
import Testing
@testable import WhoopScopeHealthBridge
import WhoopScopeDomain

@Test
func enrichmentPayloadRoundTripsThroughLocalTransportCodec() throws {
    let payload = HealthEnrichmentPayload(
        generatedAt: Date(timeIntervalSince1970: 1_700_100_000),
        deviceName: "Taylor’s iPhone",
        samples: [
            HealthMetricSample(
                kind: .steps,
                date: Date(timeIntervalSince1970: 1_700_000_000),
                value: 9_842,
                unit: "count",
                source: "Apple Health"
            ),
        ]
    )

    let encoded = try HealthBridgeCodec.encode(.enrichment(payload))
    let decoded = try HealthBridgeCodec.decode(encoded)

    #expect(decoded.kind == .enrichment)
    #expect(decoded.payload == payload)
}

@Test
func enrichmentContractDoesNotDefineSleep() {
    #expect(HealthMetricKind.allCases.map(\.rawValue).contains("sleep") == false)
}
