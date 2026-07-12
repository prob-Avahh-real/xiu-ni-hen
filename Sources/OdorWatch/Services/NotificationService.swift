import Foundation
import UserNotifications

final class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()
    private var lastAlertTime: [OdorType: Date] = [:]

    private var notificationCenter: UNUserNotificationCenter? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return nil }
        return UNUserNotificationCenter.current()
    }

    func requestPermission() {
        notificationCenter?.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func canAlert(for type: OdorType, cooldownMinutes: Int) -> Bool {
        guard let last = lastAlertTime[type] else { return true }
        return Date().timeIntervalSince(last) >= TimeInterval(cooldownMinutes * 60)
    }

    func markAlertSent(for type: OdorType) {
        lastAlertTime[type] = Date()
    }

    func sendAlert(for event: OdorEvent, assessment: AnomalyAssessment, roomName: String) {
        guard let center = notificationCenter else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(assessment.severity.rawValue) \(roomName)"
        content.body = "检测到「\(event.type.rawValue)」· 强度 \(event.intensity)/5\n\(assessment.reason)\n💡 \(assessment.suggestion)"
        content.sound = event.type.dangerLevel >= 4 ? .defaultCritical : .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        center.add(request)
    }

    func sendEmergencyAlert(for event: OdorEvent, roomName: String) {
        guard let center = notificationCenter else { return }
        let content = UNMutableNotificationContent()
        content.title = "🚨 紧急气味警报！"
        content.body = "\(roomName) 检测到高危气味「\(event.type.rawValue)」，请立即采取行动！"
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: "emergency_\(event.id)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}
