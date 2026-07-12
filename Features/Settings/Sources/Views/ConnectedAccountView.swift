import SwiftUI

struct ConnectedAccountView: View {
    let model: SettingsModel

    @State private var isConfirmingSignOut = false

    var body: some View {
        LabeledContent {
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } label: {
            Text("WHOOP")
        }

        Text("WhoopScope stores your rotating WHOOP tokens in Keychain and refreshes them through its authentication broker.")
            .font(.callout)
            .foregroundStyle(.secondary)

        if let account = model.account {
            LabeledContent("Member", value: account.profile.displayName)
            LabeledContent("Email", value: account.profile.email)
            LabeledContent(
                "Body",
                value: String(
                    format: "%.0f cm · %.1f kg",
                    account.bodyMeasurements.heightMeters * 100,
                    account.bodyMeasurements.weightKilograms
                )
            )
            LabeledContent(
                "Max heart rate",
                value: "\(account.bodyMeasurements.maxHeartRate) bpm"
            )
        } else if model.errorMessage == nil {
            ProgressView("Syncing WHOOP profile…")
                .controlSize(.small)
        }

        if let errorMessage = model.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }

        Button("Disconnect WHOOP", systemImage: "person.crop.circle.badge.xmark") {
            isConfirmingSignOut = true
        }
        .disabled(model.isWorking)
        .confirmationDialog(
            "Disconnect WHOOP?",
            isPresented: $isConfirmingSignOut
        ) {
            Button("Disconnect and Revoke Access", role: .destructive, action: signOut)
        } message: {
            Text("WhoopScope will revoke its WHOOP access and remove its credentials and tokens from Keychain.")
        }
    }

    private func signOut() {
        Task { await model.signOut() }
    }
}
