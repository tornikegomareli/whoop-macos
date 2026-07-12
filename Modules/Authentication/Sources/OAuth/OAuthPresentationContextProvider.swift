import AppKit
import AuthenticationServices

@MainActor
final class OAuthPresentationContextProvider: NSObject,
    ASWebAuthenticationPresentationContextProviding
{
    private let fallbackWindow = NSWindow()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow
            ?? NSApp.windows.first(where: \.isVisible)
            ?? fallbackWindow
    }
}
