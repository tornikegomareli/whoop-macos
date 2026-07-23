import SwiftUI
import WhoopScopeHealthBridge

struct CompanionView: View {
    let model: CompanionModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    healthCard
                    macCard
                    privacyCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("WhoopScope")
        }
        .task { model.start() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Apple Health companion", systemImage: "heart.text.square.fill")
                .font(.title2.bold())
                .foregroundStyle(.pink)
            Text("Add the useful context WHOOP doesn't provide, then send a private summary directly to your Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.background, in: .rect(cornerRadius: 20))
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("1. Prepare Apple Health", systemImage: "waveform.path.ecg")
                .font(.headline)

            Text("Includes activity, mobility, mindfulness, hydration, cardio fitness, and body composition for up to one year.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            healthStatus

            Button("Allow Access & Prepare", systemImage: "heart.circle.fill") {
                model.requestAccessAndLoad()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.healthState == .loading)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var healthStatus: some View {
        switch model.healthState {
        case .ready:
            Label("Ready to request selected read-only access", systemImage: "lock.shield")
                .foregroundStyle(.secondary)
        case .loading:
            HStack {
                ProgressView()
                Text("Preparing daily summaries…")
            }
        case let .loaded(sampleCount, dayCount):
            Label(
                "Prepared \(sampleCount) summaries across \(dayCount) days",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)
        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var macCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("2. Send to your Mac", systemImage: "macbook.and.iphone")
                .font(.headline)
            Text("Keep WhoopScope open on your Mac. After choosing it below, approve the connection in WhoopScope Settings on the Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if model.sender.peers.isEmpty {
                HStack {
                    ProgressView()
                    Text("Looking for your Mac…")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(model.sender.peers) { peer in
                    Button {
                        model.connect(to: peer)
                    } label: {
                        Label(peer.name, systemImage: "desktopcomputer")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                }
            }

            connectionStatus

            Button("Send Prepared Data", systemImage: "arrow.up.circle.fill") {
                model.sendToMac()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.payload == nil || !isConnected)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var connectionStatus: some View {
        switch model.sender.connectionState {
        case .searching:
            EmptyView()
        case let .connecting(name):
            Label("Connecting to \(name)…", systemImage: "antenna.radiowaves.left.and.right")
                .foregroundStyle(.secondary)
        case let .connected(name):
            Label("Connected to \(name)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case let .transferring(name):
            Label("Sending to \(name)…", systemImage: "arrow.up.circle")
                .foregroundStyle(.blue)
        case let .completed(message):
            Label(message, systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Private by design", systemImage: "lock.fill")
                .font(.headline)
            Text("Sleep is never requested. Your summary travels over an encrypted, direct Apple peer-to-peer session and is stored locally on your Mac.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var isConnected: Bool {
        switch model.sender.connectionState {
        case .connected, .completed:
            true
        default:
            false
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(.background, in: .rect(cornerRadius: 20))
    }
}
