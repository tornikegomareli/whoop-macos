import Foundation

public struct WidgetSnapshotStore: Sendable {
    private let suiteName: String
    private let defaultsKey: String

    public init(
        suiteName: String = WidgetConstants.appGroupIdentifier,
        defaultsKey: String = WidgetConstants.snapshotDefaultsKey
    ) {
        self.suiteName = suiteName
        self.defaultsKey = defaultsKey
    }

    public func load() -> WidgetSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: suiteName),
            let data = defaults.data(forKey: defaultsKey)
        else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    public func save(_ snapshot: WidgetSnapshot) throws {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw WidgetSnapshotStoreError.unavailableSharedContainer
        }
        defaults.set(try JSONEncoder().encode(snapshot), forKey: defaultsKey)
    }

    public func clear() {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: defaultsKey)
    }
}

public enum WidgetSnapshotStoreError: Error, Equatable {
    case unavailableSharedContainer
}
