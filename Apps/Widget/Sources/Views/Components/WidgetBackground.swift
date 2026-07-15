import SwiftUI

struct WidgetBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.075, green: 0.08, blue: 0.115)

            LinearGradient(
                colors: [
                    WidgetPalette.recovery.opacity(0.16),
                    WidgetPalette.sleep.opacity(0.10),
                    .clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
