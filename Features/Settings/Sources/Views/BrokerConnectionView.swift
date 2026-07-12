import SwiftUI

struct BrokerConnectionView: View {
    let model: SettingsModel

    var body: some View {
        Text("Connect your WHOOP account in the secure WHOOP authorization window. WhoopScope never receives or stores the app's Client Secret.")
            .font(.callout)
            .foregroundStyle(.secondary)

        if let errorMessage = model.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .accessibilityLabel("Connection error: \(errorMessage)")
        }

        Button(
            model.isWorking ? "Connecting…" : "Connect WHOOP",
            systemImage: "person.badge.key",
            action: connect
        )
        .buttonStyle(.borderedProminent)
        .disabled(model.isWorking)
    }

    private func connect() {
        Task { await model.signIn() }
    }
}

