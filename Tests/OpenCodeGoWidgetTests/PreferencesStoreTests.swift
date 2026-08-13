import XCTest
@testable import OpenCodeGoWidget

@MainActor
final class PreferencesStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() async throws {
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testDefaultValues() {
        let store = PreferencesStore(defaults: defaults)

        XCTAssertEqual(store.refreshIntervalMinutes, 15)
        XCTAssertEqual(store.menuBarMetric, .monthly)
        XCTAssertFalse(store.notifyAt70)
        XCTAssertFalse(store.notifyAt85)
        XCTAssertFalse(store.notifyAt90)
    }

    func testChangesPersistAcrossInstances() {
        let store = PreferencesStore(defaults: defaults)
        store.refreshIntervalMinutes = 30
        store.menuBarMetric = .rolling
        store.notifyAt70 = true
        store.notifyAt85 = true
        store.notifyAt90 = false

        let reloaded = PreferencesStore(defaults: defaults)

        XCTAssertEqual(reloaded.refreshIntervalMinutes, 30)
        XCTAssertEqual(reloaded.menuBarMetric, .rolling)
        XCTAssertTrue(reloaded.notifyAt70)
        XCTAssertTrue(reloaded.notifyAt85)
        XCTAssertFalse(reloaded.notifyAt90)
    }

    func testIntervalClampedToMinimum() {
        defaults.set(-5, forKey: "refreshIntervalMinutes")
        let store = PreferencesStore(defaults: defaults)

        XCTAssertEqual(store.refreshIntervalMinutes, 1)
    }

    func testIntervalClampedToMaximum() {
        defaults.set(99999, forKey: "refreshIntervalMinutes")
        let store = PreferencesStore(defaults: defaults)

        XCTAssertEqual(store.refreshIntervalMinutes, 1440)
    }
}
