#if os(macOS)
@preconcurrency import MultipeerConnectivity
import Foundation
import Observation
import WhoopScopeDomain

@MainActor
@Observable
public final class HealthBridgeReceiver {
    public private(set) var connectionState: HealthBridgeConnectionState = .searching
    public private(set) var lastImportedAt: Date?
    public private(set) var lastDeviceName: String?
    public private(set) var pendingDeviceName: String?

    private let receivePayload: @Sendable (HealthEnrichmentPayload) async throws -> Void
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let sessionDelegate: HealthSessionDelegateProxy
    private let advertiserDelegate: HealthAdvertiserDelegateProxy
    private var pendingInvitation: HealthBridgeInvitation?
    private var isAdvertising = false

    public init(
        receivePayload: @escaping @Sendable (HealthEnrichmentPayload) async throws -> Void
    ) {
        let peer = MCPeerID(displayName: Host.current().localizedName ?? "WhoopScope Mac")
        let session = MCSession(
            peer: peer,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        let sessionDelegate = HealthSessionDelegateProxy()
        let advertiserDelegate = HealthAdvertiserDelegateProxy(session: session)

        self.receivePayload = receivePayload
        self.session = session
        self.sessionDelegate = sessionDelegate
        self.advertiserDelegate = advertiserDelegate
        advertiser = MCNearbyServiceAdvertiser(
            peer: peer,
            discoveryInfo: ["app": "WhoopScope"],
            serviceType: "whoopscope"
        )

        session.delegate = sessionDelegate
        advertiser.delegate = advertiserDelegate
        sessionDelegate.stateDidChange = { [weak self] peerName, state in
            Task { @MainActor [weak self] in
                self?.handleStateChange(peerName: peerName, state: state)
            }
        }
        sessionDelegate.dataDidArrive = { [weak self] data, peerName in
            Task { @MainActor [weak self] in
                await self?.handle(data: data, from: peerName)
            }
        }
        advertiserDelegate.failureDidOccur = { [weak self] message in
            Task { @MainActor [weak self] in
                self?.connectionState = .failed(message)
            }
        }
        advertiserDelegate.invitationDidArrive = { [weak self] invitation in
            Task { @MainActor [weak self] in
                self?.handle(invitation: invitation)
            }
        }
    }

    public func start() {
        guard !isAdvertising else { return }
        advertiser.startAdvertisingPeer()
        isAdvertising = true
        connectionState = .searching
    }

    public func stop() {
        guard isAdvertising else { return }
        declinePendingDevice()
        advertiser.stopAdvertisingPeer()
        session.disconnect()
        isAdvertising = false
    }

    public func approvePendingDevice() {
        guard let pendingInvitation else { return }
        self.pendingInvitation = nil
        pendingDeviceName = nil
        connectionState = .connecting(pendingInvitation.peerName)
        pendingInvitation.respond(accept: true)
    }

    public func declinePendingDevice() {
        guard let pendingInvitation else { return }
        self.pendingInvitation = nil
        pendingDeviceName = nil
        pendingInvitation.respond(accept: false)
        connectionState = .searching
    }

    private func handle(invitation: HealthBridgeInvitation) {
        guard session.connectedPeers.isEmpty else {
            invitation.respond(accept: false)
            return
        }

        pendingInvitation?.respond(accept: false)
        pendingInvitation = invitation
        pendingDeviceName = invitation.peerName
    }

    private func handleStateChange(peerName: String, state: MCSessionState) {
        switch state {
        case .notConnected:
            connectionState = .searching
        case .connecting:
            connectionState = .connecting(peerName)
        case .connected:
            pendingInvitation = nil
            pendingDeviceName = nil
            connectionState = .connected(peerName)
        @unknown default:
            connectionState = .searching
        }
    }

    private func handle(data: Data, from peerName: String) async {
        do {
            let message = try HealthBridgeCodec.decode(data)
            guard message.kind == .enrichment, let payload = message.payload else { return }
            connectionState = .transferring(peerName)
            try await receivePayload(payload)
            lastImportedAt = payload.generatedAt
            lastDeviceName = payload.deviceName
            connectionState = .completed(peerName)
            try send(.acknowledgement("Imported \(payload.samples.count) Apple Health summaries."))
        } catch {
            connectionState = .failed("Apple Health transfer could not be imported.")
            try? send(.failure("The Mac could not import this Apple Health transfer."))
        }
    }

    private func send(_ message: HealthBridgeMessage) throws {
        guard !session.connectedPeers.isEmpty else { return }
        try session.send(
            HealthBridgeCodec.encode(message),
            toPeers: session.connectedPeers,
            with: .reliable
        )
    }
}

private final class HealthAdvertiserDelegateProxy: NSObject,
    MCNearbyServiceAdvertiserDelegate,
    @unchecked Sendable
{
    nonisolated(unsafe) var failureDidOccur: ((String) -> Void)?
    nonisolated(unsafe) var invitationDidArrive: ((HealthBridgeInvitation) -> Void)?
    private let session: MCSession

    init(session: MCSession) {
        self.session = session
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard let invitationDidArrive else {
            invitationHandler(false, nil)
            return
        }
        invitationDidArrive(
            HealthBridgeInvitation(
                peerName: peerID.displayName,
                session: session,
                handler: invitationHandler
            )
        )
    }

    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: any Error
    ) {
        failureDidOccur?("Your Mac could not advertise for the iPhone companion.")
    }
}

private final class HealthBridgeInvitation: @unchecked Sendable {
    let peerName: String

    private let session: MCSession
    private let handler: (Bool, MCSession?) -> Void
    private let lock = NSLock()
    private var hasResponded = false

    init(
        peerName: String,
        session: MCSession,
        handler: @escaping (Bool, MCSession?) -> Void
    ) {
        self.peerName = peerName
        self.session = session
        self.handler = handler
    }

    func respond(accept: Bool) {
        lock.lock()
        guard !hasResponded else {
            lock.unlock()
            return
        }
        hasResponded = true
        lock.unlock()

        handler(accept, accept ? session : nil)
    }
}
#endif
