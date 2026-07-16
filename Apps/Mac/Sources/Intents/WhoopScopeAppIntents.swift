import AppIntents
import Foundation
import WhoopScopeData
import WhoopScopeDomain
import WhoopScopePersistence

struct GetRecoveryIntent: AppIntent {
    static let title: LocalizedStringResource = "Get WHOOP Recovery"
    static let description = IntentDescription(
        "Shows your latest recovery score, HRV, and resting heart rate from WhoopScope."
    )
    static var supportedModes: IntentModes { .background }

    func perform() async -> some IntentResult & ProvidesDialog {
        guard let snapshot = await LocalMetricSnapshot.load() else {
            return .result(dialog: LocalMetricSnapshot.unavailableDialog)
        }

        let recovery = snapshot.recovery
        return .result(
            dialog: "Your latest WHOOP recovery is \(recovery.score) percent. HRV is \(recovery.heartRateVariabilityMilliseconds, format: .number.precision(.fractionLength(0))) milliseconds, and resting heart rate is \(recovery.restingHeartRate) beats per minute."
        )
    }
}

struct GetStrainIntent: AppIntent {
    static let title: LocalizedStringResource = "Get WHOOP Strain"
    static let description = IntentDescription(
        "Shows your latest day strain and activity totals from WhoopScope."
    )
    static var supportedModes: IntentModes { .background }

    func perform() async -> some IntentResult & ProvidesDialog {
        guard let snapshot = await LocalMetricSnapshot.load() else {
            return .result(dialog: LocalMetricSnapshot.unavailableDialog)
        }

        let strain = snapshot.strain
        return .result(
            dialog: "Your latest WHOOP day strain is \(strain.score, format: .number.precision(.fractionLength(1))) out of 21. You have burned \(strain.kilocalories) kilocalories with an average heart rate of \(strain.averageHeartRate) beats per minute."
        )
    }
}

struct GetSleepIntent: AppIntent {
    static let title: LocalizedStringResource = "Get WHOOP Sleep"
    static let description = IntentDescription(
        "Shows your latest sleep performance and sleep need from WhoopScope."
    )
    static var supportedModes: IntentModes { .background }

    func perform() async -> some IntentResult & ProvidesDialog {
        guard let snapshot = await LocalMetricSnapshot.load() else {
            return .result(dialog: LocalMetricSnapshot.unavailableDialog)
        }

        let sleep = snapshot.sleep
        let achieved = LocalMetricSnapshot.durationDescription(sleep.sleepAchieved)
        let needed = LocalMetricSnapshot.durationDescription(sleep.sleepNeed)
        return .result(
            dialog: "Your latest WHOOP sleep performance is \(sleep.performancePercentage) percent. You slept \(achieved), compared with \(needed) needed."
        )
    }
}

struct OpenTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Open WhoopScope Today"
    static let description = IntentDescription("Opens your WhoopScope Today dashboard.")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "whoopscope://open/today")!))
    }
}

struct OpenTrendsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open WHOOP Trends"
    static let description = IntentDescription("Opens your trends in WhoopScope.")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    func perform() async -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(URL(string: "whoopscope://open/trends")!))
    }
}

struct WhoopScopeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetRecoveryIntent(),
            phrases: [
                "What's my recovery in \(.applicationName)",
                "Show my recovery in \(.applicationName)",
            ],
            shortTitle: "WHOOP Recovery",
            systemImageName: "heart.fill"
        )
        AppShortcut(
            intent: GetStrainIntent(),
            phrases: [
                "What's my strain in \(.applicationName)",
                "Show my strain in \(.applicationName)",
            ],
            shortTitle: "WHOOP Strain",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: GetSleepIntent(),
            phrases: [
                "How did I sleep in \(.applicationName)",
                "Show my sleep in \(.applicationName)",
            ],
            shortTitle: "WHOOP Sleep",
            systemImageName: "moon.stars.fill"
        )
        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: ["Open my dashboard in \(.applicationName)"],
            shortTitle: "Open Today",
            systemImageName: "square.grid.2x2"
        )
        AppShortcut(
            intent: OpenTrendsIntent(),
            phrases: ["Open my trends in \(.applicationName)"],
            shortTitle: "Open Trends",
            systemImageName: "chart.xyaxis.line"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .navy
}

private enum LocalMetricSnapshot {
    nonisolated static let unavailableDialog: IntentDialog = "WhoopScope doesn't have synchronized WHOOP data yet. Open the app and refresh your dashboard first."

    nonisolated static func load() async -> DashboardSnapshot? {
        do {
            let database = try WhoopScopeDatabase.live()
            guard let archive = try await database.readArchive() else { return nil }
            return try DashboardSnapshotBuilder.build(from: archive, now: .now)
        } catch {
            return nil
        }
    }

    nonisolated static func durationDescription(_ duration: Duration) -> String {
        let totalMinutes = max(0, Int(duration.components.seconds) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes) minutes"
        }
        if minutes == 0 {
            return "\(hours) hours"
        }
        return "\(hours) hours and \(minutes) minutes"
    }
}
