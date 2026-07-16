import Foundation
import Observation
import WhoopScopeDomain
import WhoopScopeHealthBridge

@MainActor
@Observable
final class CompanionModel {
    enum HealthState: Equatable {
        case ready
        case loading
        case loaded(sampleCount: Int, dayCount: Int)
        case failed(String)
    }

    private(set) var healthState: HealthState = .ready
    private(set) var payload: HealthEnrichmentPayload?
    let sender: HealthBridgeSender

    private let reader: HealthKitReader

    init(
        reader: HealthKitReader = HealthKitReader(),
        sender: HealthBridgeSender = HealthBridgeSender()
    ) {
        self.reader = reader
        self.sender = sender
    }

    func start() {
        sender.start()
    }

    func stop() {
        sender.stop()
    }

    func requestAccessAndLoad() {
        guard healthState != .loading else { return }
        healthState = .loading
        Task {
            do {
                try await reader.requestAuthorization()
                let payload = try await reader.loadPayload()
                self.payload = payload
                let dayCount = Set(payload.samples.map(\.date)).count
                healthState = .loaded(sampleCount: payload.samples.count, dayCount: dayCount)
            } catch {
                healthState = .failed(error.localizedDescription)
            }
        }
    }

    func connect(to peer: HealthBridgePeer) {
        sender.connect(to: peer)
    }

    func sendToMac() {
        guard let payload else { return }
        do {
            try sender.send(payload)
        } catch {
            healthState = .failed("Apple Health data could not be sent to your Mac.")
        }
    }
}
