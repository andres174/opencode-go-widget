import Foundation
import UserNotifications

public protocol NotificationScheduling: Sendable {
    func requestAuthorization() async
    func notify(title: String, body: String) async
}

public struct NotificationScheduler: NotificationScheduling {
    public init() {}

    public func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    public func notify(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
