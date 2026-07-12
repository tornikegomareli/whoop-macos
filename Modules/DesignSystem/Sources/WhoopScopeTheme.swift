import SwiftUI

public enum WhoopScopeTheme {
    public static let pagePadding: Double = 24
    public static let cardPadding: Double = 18
    public static let sectionSpacing: Double = 20
    public static let cardSpacing: Double = 14
    public static let cardCornerRadius: Double = 18

    public static let recoveryGreen = Color(
        red: 0.20,
        green: 0.82,
        blue: 0.48
    )
    public static let recoveryYellow = Color(
        red: 0.96,
        green: 0.72,
        blue: 0.20
    )
    public static let recoveryRed = Color(
        red: 0.95,
        green: 0.30,
        blue: 0.32
    )
    public static let strainBlue = Color(
        red: 0.31,
        green: 0.64,
        blue: 1.00
    )
    public static let sleepPurple = Color(
        red: 0.58,
        green: 0.45,
        blue: 0.96
    )

    public static func recoveryColor(for score: Int) -> Color {
        if score >= 67 {
            recoveryGreen
        } else if score >= 34 {
            recoveryYellow
        } else {
            recoveryRed
        }
    }
}

