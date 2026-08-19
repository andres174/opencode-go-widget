import XCTest
@testable import OpenCodeGoWidget

final class MockKeychain: KeychainStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: String?
    var errorToThrow: Error?
    var savedValues: [String] = []

    init(storedValue: String? = nil) {
        self.storedValue = storedValue
    }

    func read() throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        if let errorToThrow { throw errorToThrow }
        return storedValue
    }

    func save(_ value: String) throws {
        lock.lock()
        defer { lock.unlock() }
        if let errorToThrow { throw errorToThrow }
        storedValue = value
        savedValues.append(value)
    }

    func delete() throws {
        lock.lock()
        defer { lock.unlock() }
        if let errorToThrow { throw errorToThrow }
        storedValue = nil
    }
}

final class MockNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var sent: [(title: String, body: String)] = []
    private var didRequestAuthorization = false

    var sentNotifications: [(title: String, body: String)] {
        lock.lock()
        defer { lock.unlock() }
        return sent
    }

    var authorizationRequested: Bool {
        lock.lock()
        defer { lock.unlock() }
        return didRequestAuthorization
    }

    func requestAuthorization() async {
        lock.withLock { didRequestAuthorization = true }
    }

    func notify(title: String, body: String) async {
        lock.withLock { sent.append((title, body)) }
    }
}

final class BlockingMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestCount = 0
    nonisolated(unsafe) static var gate: DispatchSemaphore?
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var body: Data = Data()
    nonisolated(unsafe) static var error: Error?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
        if let error = Self.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        Self.gate?.wait()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BlockingMockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

@MainActor
final class UsageViewModelTests: XCTestCase {
    private let endpoint = URL(string: "https://example.test/v1/usage")!

    private static func payload(monthlyPercent: Double, rolling: Double = 12, weekly: Double = 8) -> Data {
        Data(
            #"{"usage":{"rolling":{"percent":\#(rolling),"resetsAt":null},"weekly":{"percent":\#(weekly),"resetsAt":null},"monthly":{"percent":\#(monthlyPercent),"resetsAt":null}}}"#.utf8
        )
    }

    override func tearDown() {
        BlockingMockURLProtocol.gate?.signal()
        BlockingMockURLProtocol.gate = nil
        BlockingMockURLProtocol.requestCount = 0
        BlockingMockURLProtocol.statusCode = 200
        BlockingMockURLProtocol.body = Data()
        BlockingMockURLProtocol.error = nil
        super.tearDown()
    }

    private func makeTestDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test-\(UUID().uuidString)")!
    }

    private func makeViewModel(
        keychain: MockKeychain,
        preferences: PreferencesStore? = nil,
        notifier: MockNotificationScheduler? = nil,
        history: UsageHistoryStore? = nil
    ) -> (viewModel: UsageViewModel, notifier: MockNotificationScheduler) {
        let notifier = notifier ?? MockNotificationScheduler()
        let preferences = preferences ?? PreferencesStore(defaults: makeTestDefaults())
        let history = history ?? UsageHistoryStore(defaults: makeTestDefaults())
        let client = UsageAPIClient(endpoint: endpoint, session: BlockingMockURLProtocol.makeSession())
        let viewModel = UsageViewModel(
            keychain: keychain,
            client: client,
            preferences: preferences,
            notifier: notifier,
            history: history
        )
        return (viewModel, notifier)
    }

    func testRefreshWithoutAPIKeySetsNeedsAPIKey() async {
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: nil))

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .needsAPIKey)
    }

    func testRefreshWithEmptyAPIKeySetsNeedsAPIKey() async {
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: ""))

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .needsAPIKey)
    }

    func testRefreshSuccessUpdatesStateAndTimestamp() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))

        await viewModel.refresh()

        guard case .loaded(let usage) = viewModel.state else {
            return XCTFail("Expected loaded state, got \(viewModel.state)")
        }
        XCTAssertEqual(usage.usage.monthly.percent, 35)
        XCTAssertNotNil(viewModel.lastUpdated)
        XCTAssertEqual(viewModel.summaryPercent, 35)
    }

    func testRefreshUnauthorizedSetsFailedState() async {
        BlockingMockURLProtocol.statusCode = 401
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "bad-key"))

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .failed("Invalid or expired API key."))
        XCTAssertNil(viewModel.lastUpdated)
    }

    func testRefreshNetworkErrorSetsOfflineState() async {
        BlockingMockURLProtocol.error = URLError(.notConnectedToInternet)
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))

        await viewModel.refresh()

        guard case .offline = viewModel.state else {
            return XCTFail("Expected offline state, got \(viewModel.state)")
        }
        XCTAssertEqual(viewModel.summarySymbol, "exclamationmark.triangle")
    }

    func testSummarySymbolWhileLoading() async {
        BlockingMockURLProtocol.gate = DispatchSemaphore(value: 0)
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))

        async let refresh: Void = viewModel.refresh()
        await waitUntil(BlockingMockURLProtocol.requestCount == 1)
        XCTAssertEqual(viewModel.summarySymbol, "hourglass")

        BlockingMockURLProtocol.gate?.signal()
        _ = await refresh
    }

    func testSaveAPIKeyTrimsAndRefreshes() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        let keychain = MockKeychain(storedValue: nil)
        let (viewModel, _) = makeViewModel(keychain: keychain)

        viewModel.saveAPIKey("  test-key  ")
        await waitForLoadedState(viewModel)

        guard case .loaded = viewModel.state else {
            return XCTFail("Expected loaded state, got \(viewModel.state)")
        }
        XCTAssertEqual(keychain.savedValues, ["test-key"])
    }

    func testDeleteAPIKeyResetsState() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))
        await viewModel.refresh()
        XCTAssertNotNil(viewModel.lastUpdated)

        viewModel.deleteAPIKey()

        XCTAssertEqual(viewModel.state, .needsAPIKey)
        XCTAssertNil(viewModel.lastUpdated)
        XCTAssertNil(viewModel.latestUsage)
    }

    func testConcurrentRefreshesCoalesceIntoSingleRequest() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        BlockingMockURLProtocol.gate = DispatchSemaphore(value: 0)
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))

        async let first: Void = viewModel.refresh()
        async let second: Void = viewModel.refresh()
        await waitUntil(BlockingMockURLProtocol.requestCount == 1)
        XCTAssertEqual(BlockingMockURLProtocol.requestCount, 1)

        BlockingMockURLProtocol.gate?.signal()
        _ = await (first, second)

        guard case .loaded = viewModel.state else {
            return XCTFail("Expected loaded state, got \(viewModel.state)")
        }
        XCTAssertEqual(BlockingMockURLProtocol.requestCount, 1)
    }

    func testRefreshAfterFailureCanSucceed() async {
        BlockingMockURLProtocol.statusCode = 500
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))
        await viewModel.refresh()
        guard case .failed = viewModel.state else {
            return XCTFail("Expected failed state, got \(viewModel.state)")
        }

        BlockingMockURLProtocol.statusCode = 200
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        await viewModel.refresh()

        guard case .loaded = viewModel.state else {
            return XCTFail("Expected loaded state, got \(viewModel.state)")
        }
    }

    func testSummaryPercentUsesSelectedMetric() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35, rolling: 12, weekly: 8)
        let preferences = PreferencesStore(defaults: makeTestDefaults())
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), preferences: preferences)

        await viewModel.refresh()
        XCTAssertEqual(viewModel.summaryPercent, 35)

        preferences.menuBarMetric = .rolling
        XCTAssertEqual(viewModel.summaryPercent, 12)

        preferences.menuBarMetric = .weekly
        XCTAssertEqual(viewModel.summaryPercent, 8)
    }

    func testCrossingThresholdSendsNotification() async {
        let preferences = PreferencesStore(defaults: makeTestDefaults())
        preferences.notifyAt70 = true
        preferences.notifyAt85 = true
        preferences.notifyAt90 = true
        let (viewModel, notifier) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), preferences: preferences)

        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 60)
        await viewModel.refresh()
        XCTAssertTrue(notifier.sentNotifications.isEmpty)

        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 95)
        await viewModel.refresh()

        let titles = notifier.sentNotifications.map(\.title)
        XCTAssertEqual(notifier.sentNotifications.count, 3)
        XCTAssertTrue(titles.contains { $0.contains("70%") })
        XCTAssertTrue(titles.contains { $0.contains("85%") })
        XCTAssertTrue(titles.contains { $0.contains("90%") })
    }

    func testDisabledThresholdDoesNotNotify() async {
        let preferences = PreferencesStore(defaults: makeTestDefaults())
        preferences.notifyAt70 = false
        let (viewModel, notifier) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), preferences: preferences)

        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 60)
        await viewModel.refresh()
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 75)
        await viewModel.refresh()

        XCTAssertTrue(notifier.sentNotifications.isEmpty)
    }

    func testStayingAboveThresholdDoesNotRenotify() async {
        let preferences = PreferencesStore(defaults: makeTestDefaults())
        preferences.notifyAt70 = true
        let (viewModel, notifier) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), preferences: preferences)

        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 60)
        await viewModel.refresh()
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 75)
        await viewModel.refresh()
        XCTAssertEqual(notifier.sentNotifications.count, 1)

        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 80)
        await viewModel.refresh()
        XCTAssertEqual(notifier.sentNotifications.count, 1)
    }

    func testDroppingBelowThresholdDoesNotNotify() async {
        let preferences = PreferencesStore(defaults: makeTestDefaults())
        preferences.notifyAt70 = true
        let (viewModel, notifier) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), preferences: preferences)

        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 80)
        await viewModel.refresh()
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 60)
        await viewModel.refresh()

        XCTAssertTrue(notifier.sentNotifications.isEmpty)
    }

    func testRefreshRecordsHistorySnapshot() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35, rolling: 12, weekly: 8)
        let history = UsageHistoryStore(defaults: makeTestDefaults())
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), history: history)

        await viewModel.refresh()

        XCTAssertEqual(history.snapshots.count, 1)
        XCTAssertEqual(history.snapshots.first?.monthlyPercent, 35)
        XCTAssertEqual(history.snapshots.first?.rollingPercent, 12)
        XCTAssertEqual(history.snapshots.first?.weeklyPercent, 8)
    }

    func testIdenticalConsecutiveRefreshesRecordSingleSnapshot() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        let history = UsageHistoryStore(defaults: makeTestDefaults())
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), history: history)

        await viewModel.refresh()
        await viewModel.refresh()

        XCTAssertEqual(history.snapshots.count, 1)
    }

    func testDeleteAPIKeyClearsHistory() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        let history = UsageHistoryStore(defaults: makeTestDefaults())
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), history: history)
        await viewModel.refresh()
        XCTAssertEqual(history.snapshots.count, 1)

        viewModel.deleteAPIKey()

        XCTAssertTrue(history.snapshots.isEmpty)
    }

    func testFirstLoadDoesNotNotifyEvenIfAboveThreshold() async {
        let preferences = PreferencesStore(defaults: makeTestDefaults())
        preferences.notifyAt70 = true
        let (viewModel, notifier) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"), preferences: preferences)

        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 85)
        await viewModel.refresh()

        XCTAssertTrue(notifier.sentNotifications.isEmpty)
    }

    func testSubsequentRefreshDoesNotEnterLoadingState() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))
        await viewModel.refresh()
        guard case .loaded = viewModel.state else {
            return XCTFail("Expected loaded state, got \(viewModel.state)")
        }

        BlockingMockURLProtocol.gate = DispatchSemaphore(value: 0)
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 40)
        async let refresh: Void = viewModel.refresh()
        await waitUntil(BlockingMockURLProtocol.requestCount == 2)

        XCTAssertTrue(viewModel.isRefreshing)
        guard case .loaded = viewModel.state else {
            return XCTFail("Expected loaded during subsequent refresh, got \(viewModel.state)")
        }
        XCTAssertEqual(viewModel.summaryPercent, 35)
        XCTAssertNil(viewModel.summarySymbol)

        BlockingMockURLProtocol.gate?.signal()
        _ = await refresh

        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertEqual(viewModel.summaryPercent, 40)
        XCTAssertEqual(viewModel.latestUsage?.usage.monthly.percent, 40)
    }

    func testFailedRefreshAfterSuccessKeepsLatestUsage() async {
        BlockingMockURLProtocol.body = Self.payload(monthlyPercent: 35)
        let (viewModel, _) = makeViewModel(keychain: MockKeychain(storedValue: "test-key"))
        await viewModel.refresh()
        let updated = viewModel.lastUpdated
        XCTAssertNotNil(viewModel.latestUsage)

        BlockingMockURLProtocol.error = URLError(.notConnectedToInternet)
        await viewModel.refresh()

        guard case .offline = viewModel.state else {
            return XCTFail("Expected offline state, got \(viewModel.state)")
        }
        XCTAssertEqual(viewModel.latestUsage?.usage.monthly.percent, 35)
        XCTAssertEqual(viewModel.summaryPercent, 35)
        XCTAssertEqual(viewModel.lastUpdated, updated)
        XCTAssertNil(viewModel.summarySymbol)
    }

    private func waitForLoadedState(_ viewModel: UsageViewModel) async {
        for _ in 0..<100 {
            if case .loaded = viewModel.state { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private func waitUntil(_ condition: @autoclosure () -> Bool) async {
        for _ in 0..<200 {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
