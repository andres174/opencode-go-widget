import Foundation

public struct UsageResponse: Codable, Equatable, Sendable {
    public let usage: Usage

    public init(usage: Usage) {
        self.usage = usage
    }

    private enum CodingKeys: String, CodingKey {
        case usage
        case capitalizedUsage = "Usage"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        usage = try container.decodeIfPresent(Usage.self, forKey: .usage)
            ?? container.decode(Usage.self, forKey: .capitalizedUsage)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(usage, forKey: .usage)
    }
}

public struct Usage: Codable, Equatable, Sendable {
    public let rolling: UsageWindow
    public let weekly: UsageWindow
    public let monthly: UsageWindow

    public init(rolling: UsageWindow, weekly: UsageWindow, monthly: UsageWindow) {
        self.rolling = rolling
        self.weekly = weekly
        self.monthly = monthly
    }
}

public struct UsageWindow: Codable, Equatable, Sendable {
    public let percent: Double
    public let resetsAt: String?

    public init(percent: Double, resetsAt: String? = nil) {
        self.percent = percent
        self.resetsAt = resetsAt
    }

    public var validatedPercent: Double {
        min(max(percent, 0), 100)
    }
}
