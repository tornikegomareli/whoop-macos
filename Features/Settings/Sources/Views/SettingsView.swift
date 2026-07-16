import SwiftUI
import WhoopScopeChat
import WhoopScopeHealthBridge

public struct SettingsView: View {
    private let model: SettingsModel
    private let healthReceiver: HealthBridgeReceiver
    @Bindable private var aiSettings: AISettingsModel

    public init(
        model: SettingsModel,
        healthReceiver: HealthBridgeReceiver,
        aiSettings: AISettingsModel
    ) {
        self.model = model
        self.healthReceiver = healthReceiver
        self.aiSettings = aiSettings
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

            Section("Ask Your Data") {
                Picker("Provider", selection: $aiSettings.selectedProvider) {
                    ForEach(AIProviderSelection.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                Text(aiSettings.selectedProvider.privacySummary)
                    .font(.callout)
                    .foregroundStyle(aiSettings.selectedProvider == .openAI ? .orange : .secondary)

                if aiSettings.selectedProvider == .appleIntelligence {
                    LabeledContent(
                        "On-device model",
                        value: aiSettings.appleIntelligenceStatus
                    )
                } else {
                    SecureField("OpenAI API key", text: $aiSettings.apiKeyDraft)
                        .textContentType(.password)
                    TextField("Model", text: $aiSettings.openAIModel)
                    HStack {
                        Button("Save Key", systemImage: "key.fill") {
                            Task { await aiSettings.saveOpenAIKey() }
                        }
                        .disabled(aiSettings.apiKeyDraft.isEmpty || aiSettings.isWorking)
                        if aiSettings.hasStoredOpenAIKey {
                            Label("Stored in Keychain", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Button("Remove Key", systemImage: "trash", role: .destructive) {
                                Task { await aiSettings.removeOpenAIKey() }
                            }
                        }
                    }
                }
                if let statusMessage = aiSettings.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .task {
            await model.load()
            await aiSettings.load()
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
