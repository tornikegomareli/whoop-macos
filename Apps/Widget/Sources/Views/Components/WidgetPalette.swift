import SwiftUI

enum WidgetPalette {
    static let recovery = Color(red: 0.20, green: 0.82, blue: 0.48)
    static let recoveryYellow = Color(red: 0.96, green: 0.72, blue: 0.20)
    static let recoveryRed = Color(red: 0.95, green: 0.30, blue: 0.32)
    static let strain = Color(red: 0.31, green: 0.64, blue: 1.00)
    static let sleep = Color(red: 0.58, green: 0.45, blue: 0.96)

    static func recovery(for score: Int) -> Color {
        if score >= 67 {
            recovery
        } else if score >= 34 {
            recoveryYellow
        } else {
            recoveryRed
        }
    }
}
