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
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastUpdated: Date?

    private let keychain: KeychainService
    private let client: UsageAPIClient
    private var refreshTask: Task<Void, Never>?

    init(keychain: KeychainService = KeychainService(), client: UsageAPIClient = UsageAPIClient()) {
        self.keychain = keychain
        self.client = client
    }

    deinit { refreshTask?.cancel() }

    func start() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(900))
            }
        }
    }

    func refresh() async {
        do {
            guard let apiKey = try keychain.read(), !apiKey.isEmpty else {
                state = .needsAPIKey
                return
            }
            state = .loading
            let usage = try await client.fetchUsage(apiKey: apiKey)
            state = .loaded(usage)
            lastUpdated = Date()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func saveAPIKey(_ apiKey: String) {
        do {
            try keychain.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
            Task { await refresh() }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func deleteAPIKey() {
        do {
            try keychain.delete()
            state = .needsAPIKey
            lastUpdated = nil
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    var summaryPercent: Double? {
        guard case .loaded(let response) = state else { return nil }
        return response.usage.monthly.percent
    }
}
