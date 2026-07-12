import SwiftUI

public struct SettingsView: View {
    private let model: SettingsModel

    public init(model: SettingsModel) {
        self.model = model
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
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .task {
            await model.load()
        }
    }
}
