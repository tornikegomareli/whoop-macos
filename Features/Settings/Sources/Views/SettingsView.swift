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
                if let pendingDeviceName = healthReceiver.pendingDeviceName {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(
                            "\(pendingDeviceName) wants to connect",
                            systemImage: "iphone.gen3.radiowaves.left.and.right"
                        )
                        .font(.headline)
                        Text("Approve only when you started this connection from your iPhone.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Allow", systemImage: "checkmark.shield.fill") {
                                healthReceiver.approvePendingDevice()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Decline", systemImage: "xmark") {
                                healthReceiver.declinePendingDevice()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                if let deviceName = healthReceiver.lastDeviceName,
                   let importedAt = healthReceiver.lastImportedAt
                {
                    LabeledContent("Last iPhone", value: deviceName)
                    LabeledContent("Last import") {
                        Text(importedAt, format: .relative(presentation: .named))
                    }
                }
                Text("Open the WhoopScope companion on iPhone, choose this Mac, then approve the connection here. Sleep is never requested.")
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
                    OpenAIModelPicker(settings: aiSettings)
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
        if healthReceiver.pendingDeviceName != nil {
            return ("Approval needed", "person.badge.shield.checkmark.fill", .orange)
        }

        switch healthReceiver.connectionState {
        case .searching:
            return ("Ready for iPhone", "antenna.radiowaves.left.and.right", .secondary)
        case let .connecting(name):
            return ("Connecting to \(name)", "link", .blue)
        case let .connected(name):
            return ("Connected to \(name)", "checkmark.circle.fill", .green)
        case let .transferring(name):
            return ("Importing from \(name)", "arrow.down.circle", .blue)
        case .completed:
            return ("Import complete", "checkmark.seal.fill", .green)
        case .failed:
            return ("Receiver needs attention", "exclamationmark.triangle.fill", .red)
        }
    }
}

private struct OpenAIModelPicker: View {
    @Bindable var settings: AISettingsModel

    var body: some View {
        LabeledContent("Model") {
            HStack(spacing: 8) {
                if settings.isLoadingOpenAIModels {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Loading OpenAI models")
                }

                Picker("OpenAI model", selection: $settings.openAIModel) {
                    ForEach(settings.modelPickerOptions) { model in
                        Text(model.id)
                            .tag(model.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(minWidth: 220, alignment: .trailing)
                .disabled(
                    !settings.hasStoredOpenAIKey
                        || settings.isLoadingOpenAIModels
                        || settings.availableOpenAIModels.isEmpty
                )

                Button("Refresh models", systemImage: "arrow.clockwise") {
                    Task { await settings.reloadOpenAIModels() }
                }
                .labelStyle(.iconOnly)
                .disabled(!settings.hasStoredOpenAIKey || settings.isLoadingOpenAIModels)
                .help("Refresh models available to this API key")
            }
        }

        if !settings.hasStoredOpenAIKey {
            Text("Save your API key to load the models available to your OpenAI account.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let error = settings.modelCatalogError {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if !settings.isLoadingOpenAIModels {
            Text("\(settings.availableOpenAIModels.count) compatible models available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
