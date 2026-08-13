import Combine
import Foundation
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(UsageResponse)
        case needsAPIKey
        case failed(String)
        case offline(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastUpdated: Date?

    private let keychain: any KeychainStoring
    private let client: UsageAPIClient
    private let preferences: PreferencesStore
    private let notifier: any NotificationScheduling
    let history: UsageHistoryStore
    private var refreshTask: Task<Void, Never>?
    private var pendingRefresh: Task<Void, Never>?
    private var isRefreshing = false
    private var previousUsage: UsageResponse?
    private var cancellables = Set<AnyCancellable>()

    init(
        keychain: any KeychainStoring = KeychainService(),
        client: UsageAPIClient = UsageAPIClient(),
        preferences: PreferencesStore = PreferencesStore(),
        notifier: any NotificationScheduling = NotificationScheduler(),
        history: UsageHistoryStore = UsageHistoryStore()
    ) {
        self.keychain = keychain
        self.client = client
        self.preferences = preferences
        self.notifier = notifier
        self.history = history

        preferences.$refreshIntervalMinutes
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.start() }
            }
            .store(in: &cancellables)
    }

    deinit {
        refreshTask?.cancel()
        pendingRefresh?.cancel()
    }

    func start() {
        stop()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                let interval = self?.preferences.refreshIntervalMinutes ?? PreferencesStore.defaultIntervalMinutes
                try? await Task.sleep(for: .seconds(interval * 60))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        pendingRefresh?.cancel()
        pendingRefresh = nil
    }

    func requestNotifications() {
        Task { [notifier] in
            await notifier.requestAuthorization()
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        do {
            guard let apiKey = try keychain.read(), !apiKey.isEmpty else {
                state = .needsAPIKey
                return
            }
            isRefreshing = true
            state = .loading
            defer { isRefreshing = false }
            let usage = try await client.fetchUsage(apiKey: apiKey)
            await sendThresholdNotifications(previous: previousUsage, current: usage)
            previousUsage = usage
            recordSnapshot(usage)
            state = .loaded(usage)
            lastUpdated = Date()
        } catch let error as URLError {
            state = .offline(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func saveAPIKey(_ apiKey: String) {
        do {
            try keychain.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
            scheduleRefresh()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func deleteAPIKey() {
        do {
            try keychain.delete()
            pendingRefresh?.cancel()
            pendingRefresh = nil
            previousUsage = nil
            history.clear()
            state = .needsAPIKey
            lastUpdated = nil
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func recordSnapshot(_ usage: UsageResponse) {
        history.append(UsageSnapshot(
            date: Date(),
            rollingPercent: usage.usage.rolling.validatedPercent,
            weeklyPercent: usage.usage.weekly.validatedPercent,
            monthlyPercent: usage.usage.monthly.validatedPercent
        ))
    }

    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        pendingRefresh = Task { [weak self] in
            await self?.refresh()
        }
    }

    private func sendThresholdNotifications(previous: UsageResponse?, current: UsageResponse) async {
        guard let previous else { return }
        let thresholds: [(threshold: Int, enabled: Bool)] = [
            (70, preferences.notifyAt70),
            (85, preferences.notifyAt85),
            (90, preferences.notifyAt90),
        ]
        for entry in thresholds where entry.enabled {
            let oldPercent = previous.usage.monthly.validatedPercent
            let newPercent = current.usage.monthly.validatedPercent
            if oldPercent < Double(entry.threshold), newPercent >= Double(entry.threshold) {
                await notifier.notify(
                    title: "OpenCode Go usage: \(entry.threshold)% reached",
                    body: "Monthly usage is now \(Int(newPercent.rounded()))%."
                )
            }
        }
    }

    var summaryPercent: Double? {
        guard case .loaded(let response) = state else { return nil }
        return usageWindow(of: response).validatedPercent
    }

    var summarySymbol: String? {
        switch state {
        case .loading: return "hourglass"
        case .failed, .offline: return "exclamationmark.triangle"
        case .idle, .loaded, .needsAPIKey: return nil
        }
    }

    private func usageWindow(of response: UsageResponse) -> UsageWindow {
        switch preferences.menuBarMetric {
        case .rolling: return response.usage.rolling
        case .weekly: return response.usage.weekly
        case .monthly: return response.usage.monthly
        }
    }
}
