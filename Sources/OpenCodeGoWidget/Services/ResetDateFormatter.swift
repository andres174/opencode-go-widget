import Foundation

public struct ResetDateFormatter: Sendable {
    private let locale: Locale
    private let timeZone: TimeZone

    public init(locale: Locale = .current, timeZone: TimeZone = .current) {
        self.locale = locale
        self.timeZone = timeZone
    }

    public func friendlyResetText(resetsAt: String?, relativeTo now: Date) -> String? {
        guard let resetsAt, let resetDate = ISO8601DateFormatter().date(from: resetsAt) else {
            return nil
        }

        let interval = resetDate.timeIntervalSince(now)

        if interval >= -60, interval < 60 {
            return "Resets now"
        }

        if interval < -60 {
            return "Resets on \(dateFormatter.string(from: resetDate))"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(resetDate, inSameDayAs: tomorrow) {
            return "Resets tomorrow"
        }

        let minutes = Int(interval / 60)
        if interval < 3600 {
            return "Resets in \(max(minutes, 1)) minutes"
        }

        let hours = Int((interval / 3600).rounded())
        if interval < 86_400 {
            return "Resets in \(hours) hours"
        }

        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: resetDate)
        ).day ?? 0
        if days < 7 {
            return "Resets in \(days) days"
        }

        return "Resets on \(dateFormatter.string(from: resetDate))"
    }

    public func exactResetText(resetsAt: String?) -> String? {
        guard let resetsAt, let resetDate = ISO8601DateFormatter().date(from: resetsAt) else {
            return nil
        }
        return exactFormatter.string(from: resetDate)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var exactFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
