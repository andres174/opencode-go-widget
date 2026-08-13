import XCTest
@testable import OpenCodeGoWidget

@MainActor
final class UsageHistoryStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() async throws {
        suiteName = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func snapshot(monthly: Double, day: Int = 1) -> UsageSnapshot {
        UsageSnapshot(
            date: Date(timeIntervalSince1970: TimeInterval(day * 86_400)),
            rollingPercent: 10,
            weeklyPercent: 20,
            monthlyPercent: monthly
        )
    }

    func testStartsEmpty() {
        let store = UsageHistoryStore(defaults: defaults)
        XCTAssertTrue(store.snapshots.isEmpty)
    }

    func testAppendsSnapshots() {
        let store = UsageHistoryStore(defaults: defaults)
        store.append(snapshot(monthly: 35))
        store.append(snapshot(monthly: 40, day: 2))

        XCTAssertEqual(store.snapshots.count, 2)
        XCTAssertEqual(store.snapshots.map(\.monthlyPercent), [35, 40])
    }

    func testSkipsConsecutiveIdenticalSnapshots() {
        let store = UsageHistoryStore(defaults: defaults)
        store.append(snapshot(monthly: 35))
        store.append(snapshot(monthly: 35, day: 2))

        XCTAssertEqual(store.snapshots.count, 1)
    }

    func testPersistsAcrossInstances() {
        let store = UsageHistoryStore(defaults: defaults)
        store.append(snapshot(monthly: 35))
        store.append(snapshot(monthly: 40, day: 2))

        let reloaded = UsageHistoryStore(defaults: defaults)

        XCTAssertEqual(reloaded.snapshots.count, 2)
        XCTAssertEqual(reloaded.snapshots.map(\.monthlyPercent), [35, 40])
    }

    func testCapsAtLimitDroppingOldest() {
        let store = UsageHistoryStore(defaults: defaults, limit: 3)
        for day in 1...5 {
            store.append(snapshot(monthly: Double(day), day: day))
        }

        XCTAssertEqual(store.snapshots.count, 3)
        XCTAssertEqual(store.snapshots.map(\.monthlyPercent), [3, 4, 5])
    }

    func testClearRemovesPersistedData() {
        let store = UsageHistoryStore(defaults: defaults)
        store.append(snapshot(monthly: 35))

        store.clear()

        XCTAssertTrue(store.snapshots.isEmpty)
        let reloaded = UsageHistoryStore(defaults: defaults)
        XCTAssertTrue(reloaded.snapshots.isEmpty)
    }
}
