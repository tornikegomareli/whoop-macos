import SwiftUI
import WhoopScopeHealthBridge

public struct SettingsView: View {
    private let model: SettingsModel
    private let healthReceiver: HealthBridgeReceiver

    public init(model: SettingsModel, healthReceiver: HealthBridgeReceiver) {
        self.model = model
        self.healthReceiver = healthReceiver
    }

    public var body: some View {
        Form {
            Section("WHOOP account") {
                if let status = model.authenticationStatus {
                    switch status {
                    case .signedOut:
                        BrokerConnectionView(model: model)
                    case .signedIn:
                        ConnectedAccountView(model: model)
                    }
                } else {
                    ProgressView("Checking WHOOP connection…")
                }
            }

            Section("Privacy") {
                LabeledContent("Token storage", value: "Apple Keychain")
                LabeledContent("WHOOP redirect", value: "whoopscope://oauth/callback")
                Text("The Client Secret remains on WhoopScope's authentication broker and never enters this app.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Apple Health companion") {
                LabeledContent("Local receiver") {
                    Label(healthStatus.title, systemImage: healthStatus.symbol)
                        .foregroundStyle(healthStatus.color)
                }
                if let deviceName = healthReceiver.lastDeviceName,
                   let importedAt = healthReceiver.lastImportedAt
                {
                    LabeledContent("Last iPhone", value: deviceName)
                    LabeledContent("Last import") {
                        Text(importedAt, format: .relative(presentation: .named))
                    }
                }
                Text("Open the WhoopScope companion on iPhone to send selected Apple Health summaries directly to this Mac. Sleep is never requested.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .task {
            await model.load()
        }
    }

    private var healthStatus: (title: String, symbol: String, color: Color) {
        switch healthReceiver.connectionState {
        case .searching:
            ("Ready for iPhone", "antenna.radiowaves.left.and.right", .secondary)
        case let .connecting(name):
            ("Connecting to \(name)", "link", .blue)
        case let .connected(name):
            ("Connected to \(name)", "checkmark.circle.fill", .green)
        case let .transferring(name):
            ("Importing from \(name)", "arrow.down.circle", .blue)
        case .completed:
            ("Import complete", "checkmark.seal.fill", .green)
        case .failed:
            ("Receiver needs attention", "exclamationmark.triangle.fill", .red)
        }
    }
}
