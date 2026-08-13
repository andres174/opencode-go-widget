import Combine
import Foundation

public struct UsageSnapshot: Codable, Equatable, Identifiable, Sendable {
    public let date: Date
    public let rollingPercent: Double
    public let weeklyPercent: Double
    public let monthlyPercent: Double

    public var id: Date { date }

    public init(date: Date, rollingPercent: Double, weeklyPercent: Double, monthlyPercent: Double) {
        self.date = date
        self.rollingPercent = rollingPercent
        self.weeklyPercent = weeklyPercent
        self.monthlyPercent = monthlyPercent
    }
}

@MainActor
public final class UsageHistoryStore: ObservableObject {
    @Published private(set) var snapshots: [UsageSnapshot] = []

    private let defaults: UserDefaults
    private let limit: Int
    private let storageKey: String

    public init(defaults: UserDefaults = .standard, limit: Int = 720, storageKey: String = "usageHistory") {
        self.defaults = defaults
        self.limit = limit
        self.storageKey = storageKey
        load()
    }

    public func append(_ snapshot: UsageSnapshot) {
        if let last = snapshots.last,
           last.rollingPercent == snapshot.rollingPercent,
           last.weeklyPercent == snapshot.weeklyPercent,
           last.monthlyPercent == snapshot.monthlyPercent {
            return
        }
        snapshots.append(snapshot)
        if snapshots.count > limit {
            snapshots.removeFirst(snapshots.count - limit)
        }
        save()
    }

    public func clear() {
        snapshots = []
        defaults.removeObject(forKey: storageKey)
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        snapshots = (try? decoder.decode([UsageSnapshot].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshots) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
