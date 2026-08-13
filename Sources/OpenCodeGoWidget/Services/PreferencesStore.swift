import Combine
import Foundation

public enum UsageMetric: String, CaseIterable, Identifiable {
    case rolling
    case weekly
    case monthly

    public var id: String { rawValue }

    public var title: String {
        rawValue.capitalized
    }
}

@MainActor
public final class PreferencesStore: ObservableObject {
    static let intervalOptions = [5, 15, 30, 60]
    static let defaultIntervalMinutes = 15

    @Published var refreshIntervalMinutes: Int {
        didSet { defaults.set(refreshIntervalMinutes, forKey: Keys.refreshInterval) }
    }
    @Published var menuBarMetric: UsageMetric {
        didSet { defaults.set(menuBarMetric.rawValue, forKey: Keys.menuBarMetric) }
    }
    @Published var notifyAt70: Bool {
        didSet { defaults.set(notifyAt70, forKey: Keys.notifyAt70) }
    }
    @Published var notifyAt85: Bool {
        didSet { defaults.set(notifyAt85, forKey: Keys.notifyAt85) }
    }
    @Published var notifyAt90: Bool {
        didSet { defaults.set(notifyAt90, forKey: Keys.notifyAt90) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let refreshInterval = "refreshIntervalMinutes"
        static let menuBarMetric = "menuBarMetric"
        static let notifyAt70 = "notifyAt70"
        static let notifyAt85 = "notifyAt85"
        static let notifyAt90 = "notifyAt90"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedInterval = defaults.object(forKey: Keys.refreshInterval) as? Int ?? Self.defaultIntervalMinutes
        refreshIntervalMinutes = min(max(storedInterval, 1), 1440)

        menuBarMetric = UsageMetric(rawValue: defaults.string(forKey: Keys.menuBarMetric) ?? "") ?? .monthly

        if defaults.object(forKey: Keys.notifyAt70) == nil {
            notifyAt70 = false
            notifyAt85 = false
            notifyAt90 = false
        } else {
            notifyAt70 = defaults.bool(forKey: Keys.notifyAt70)
            notifyAt85 = defaults.bool(forKey: Keys.notifyAt85)
            notifyAt90 = defaults.bool(forKey: Keys.notifyAt90)
        }
    }
}
