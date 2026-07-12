import SwiftUI

public struct CardSurface: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(WhoopScopeTheme.cardPadding)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: WhoopScopeTheme.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: WhoopScopeTheme.cardCornerRadius)
                    .stroke(.separator.opacity(0.35), lineWidth: 1)
            }
    }
}

