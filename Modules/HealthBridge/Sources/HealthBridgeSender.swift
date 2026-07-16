#if os(iOS)
@preconcurrency import MultipeerConnectivity
import Foundation
import Observation
import UIKit
import WhoopScopeDomain

@MainActor
@Observable
public final class HealthBridgeSender {
    public private(set) var peers: [HealthBridgePeer] = []
    public private(set) var connectionState: HealthBridgeConnectionState = .searching

    private let session: MCSession
    private let browser: MCNearbyServiceBrowser
    private let sessionDelegate: HealthSessionDelegateProxy
    private let browserDelegate: HealthBrowserDelegateProxy
    private var discoveredPeers: [String: MCPeerID] = [:]
    private var isBrowsing = false

    public init() {
        let peer = MCPeerID(displayName: UIDevice.current.name)
        let session = MCSession(
            peer: peer,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        let sessionDelegate = HealthSessionDelegateProxy()
        let browserDelegate = HealthBrowserDelegateProxy()

        self.session = session
        self.sessionDelegate = sessionDelegate
        self.browserDelegate = browserDelegate
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "whoopscope")

        session.delegate = sessionDelegate
        browser.delegate = browserDelegate
        browserDelegate.peerDidAppear = { [weak self] peer in
            Task { @MainActor [weak self] in self?.add(peer) }
        }
        browserDelegate.peerDidDisappear = { [weak self] peer in
            Task { @MainActor [weak self] in self?.remove(peer) }
        }
        browserDelegate.failureDidOccur = { [weak self] in
            Task { @MainActor [weak self] in
                self?.connectionState = .failed("The iPhone could not search for your Mac.")
            }
        }
        sessionDelegate.stateDidChange = { [weak self] peerName, state in
            Task { @MainActor [weak self] in
                self?.handleStateChange(peerName: peerName, state: state)
            }
        }
        sessionDelegate.dataDidArrive = { [weak self] data, peerName in
            Task { @MainActor [weak self] in
                self?.handle(data: data, from: peerName)
            }
        }
    }

    public func start() {
        guard !isBrowsing else { return }
        browser.startBrowsingForPeers()
        isBrowsing = true
        connectionState = .searching
    }

    public func stop() {
        guard isBrowsing else { return }
        browser.stopBrowsingForPeers()
        session.disconnect()
        isBrowsing = false
    }

    public func connect(to peer: HealthBridgePeer) {
        guard let nearbyPeer = discoveredPeers[peer.id] else { return }
        connectionState = .connecting(peer.name)
        browser.invitePeer(nearbyPeer, to: session, withContext: nil, timeout: 20)
    }

    public func send(_ payload: HealthEnrichmentPayload) throws {
        guard !session.connectedPeers.isEmpty else {
            connectionState = .failed("Connect to your Mac before sending Apple Health data.")
            return
        }
        let peerName = session.connectedPeers[0].displayName
        connectionState = .transferring(peerName)
        try session.send(
            HealthBridgeCodec.encode(.enrichment(payload)),
            toPeers: session.connectedPeers,
            with: .reliable
        )
    }

    private func add(_ peer: MCPeerID) {
        let identifier = peer.displayName
        discoveredPeers[identifier] = peer
        peers = discoveredPeers.values
            .map { HealthBridgePeer(id: $0.displayName, name: $0.displayName) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func remove(_ peer: MCPeerID) {
        discoveredPeers.removeValue(forKey: peer.displayName)
        peers.removeAll { $0.id == peer.displayName }
    }

    private func handleStateChange(peerName: String, state: MCSessionState) {
        switch state {
        case .notConnected:
            connectionState = .searching
        case .connecting:
            connectionState = .connecting(peerName)
        case .connected:
            connectionState = .connected(peerName)
        @unknown default:
            connectionState = .searching
        }
    }

    private func handle(data: Data, from peerName: String) {
        guard let message = try? HealthBridgeCodec.decode(data) else { return }
        switch message.kind {
        case .acknowledgement:
            connectionState = .completed(message.message ?? peerName)
        case .failure:
            connectionState = .failed(message.message ?? "The Mac could not import the transfer.")
        case .enrichment:
            break
        }
    }
}

private final class HealthBrowserDelegateProxy: NSObject,
    MCNearbyServiceBrowserDelegate,
    @unchecked Sendable
{
    nonisolated(unsafe) var peerDidAppear: ((MCPeerID) -> Void)?
    nonisolated(unsafe) var peerDidDisappear: ((MCPeerID) -> Void)?
    nonisolated(unsafe) var failureDidOccur: (() -> Void)?

    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        guard info?["app"] == "WhoopScope" else { return }
        peerDidAppear?(peerID)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        peerDidDisappear?(peerID)
    }

    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: any Error
    ) {
        failureDidOccur?()
    }
}
#endif
