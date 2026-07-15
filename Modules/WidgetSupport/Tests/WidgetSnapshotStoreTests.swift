import Foundation
import Testing
@testable import WhoopScopeWidgetSupport

@Test
func widgetSnapshotRoundTripsThroughSharedDefaults() throws {
    let suiteName = "com.whoopscope.tests.\(UUID().uuidString)"
    let store = WidgetSnapshotStore(suiteName: suiteName)
    let snapshot = WidgetSnapshot.preview
    defer { store.clear() }

    try store.save(snapshot)

    #expect(store.load() == snapshot)
}

@Test
func clearingWidgetSnapshotRemovesDisplayedHealthData() throws {
    let suiteName = "com.whoopscope.tests.\(UUID().uuidString)"
    let store = WidgetSnapshotStore(suiteName: suiteName)
    try store.save(.preview)

    store.clear()

    #expect(store.load() == nil)
}
