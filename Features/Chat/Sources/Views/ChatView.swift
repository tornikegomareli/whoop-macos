import SwiftUI

public struct ChatView: View {
    @Bindable private var model: ChatModel

    public init(model: ChatModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            ChatHeaderView(
                provider: model.settings.selectedProvider,
                canClear: !model.messages.isEmpty && !model.isResponding,
                clear: model.clearConversation
            )
            Divider()
            ChatTranscriptView(
                messages: model.messages,
                isResponding: model.isResponding,
                sendSuggestion: model.send
            )
            if let errorMessage = model.errorMessage {
                ChatErrorView(message: errorMessage)
            }
            ChatComposerView(
                draft: $model.draft,
                isResponding: model.isResponding,
                send: model.sendDraft
            )
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ChatHeaderView: View {
    let provider: AIProviderSelection
    let canClear: Bool
    let clear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Ask Your Data")
                    .font(.title2.bold())
                Label(
                    provider.title,
                    systemImage: provider == .openAI ? "cloud" : "apple.intelligence"
                )
                .font(.caption)
                .foregroundStyle(provider == .openAI ? .orange : .secondary)
            }
            Spacer()
            Button("Clear Conversation", systemImage: "trash", action: clear)
                .disabled(!canClear)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

private struct ChatTranscriptView: View {
    let messages: [ChatMessage]
    let isResponding: Bool
    let sendSuggestion: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if messages.isEmpty {
                        ChatWelcomeView(sendSuggestion: sendSuggestion)
                    }
                    ForEach(messages) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }
                    if isResponding {
                        ChatThinkingView()
                            .id("thinking")
                    }
                }
                .padding(24)
            }
            .onChange(of: messages.count) {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: isResponding) {
                if isResponding {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    }
                }
            }
        }
    }
}

private struct ChatWelcomeView: View {
    let sendSuggestion: (String) -> Void

    private let suggestions = [
        "How did I sleep last week compared with the week before?",
        "What is my recovery trend this month?",
        "Which recent workouts were followed by my best recovery?",
        "How are my steps and strain related over the last 30 days?",
    ]

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 34))
                .foregroundStyle(.purple)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("Explore your own patterns")
                    .font(.title3.bold())
                Text(
                    "Answers are grounded in synchronized WHOOP data and any complementary Apple Health summaries on this Mac."
                )
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)
            }
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(suggestion) { sendSuggestion(suggestion) }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }
            .frame(maxWidth: 720)
            Text("WhoopScope finds patterns; it does not provide medical advice.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

private struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 80)
            } else {
                Spacer(minLength: 80)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(attributedContent)
                .textSelection(.enabled)
            if let evidenceLabel = message.evidenceLabel {
                Label(evidenceLabel, systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            message.role == .user ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.10),
            in: .rect(cornerRadius: 16)
        )
        .frame(maxWidth: 720, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var attributedContent: AttributedString {
        (try? AttributedString(markdown: message.content)) ?? AttributedString(message.content)
    }
}

private struct ChatThinkingView: View {
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Reading your local evidence…")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.10), in: .rect(cornerRadius: 16))
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ChatErrorView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.08))
    }
}

private struct ChatComposerView: View {
    @Binding var draft: String
    let isResponding: Bool
    let send: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Ask about your WHOOP data…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($isFocused)
                .onSubmit(send)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.secondary.opacity(0.09), in: .rect(cornerRadius: 14))
            Button("Send", systemImage: "arrow.up.circle.fill", action: send)
                .labelStyle(.iconOnly)
                .font(.title2)
                .buttonStyle(.plain)
                .disabled(
                    draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isResponding
                )
                .accessibilityHint("Sends your question to the selected model")
        }
        .padding(16)
        .background(.bar)
    }
}
