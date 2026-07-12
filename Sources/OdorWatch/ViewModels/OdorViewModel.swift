import SwiftUI

@MainActor
final class OdorViewModel: ObservableObject {
    @Published var events: [OdorEvent] = []
    @Published var preferences = OdorPreferences()
    @Published var selectedRoomId: UUID?

    private let storage: StorageServiceProtocol
    private let patternEngine: PatternEngineProtocol
    private let notifications: NotificationServiceProtocol

    init(
        storage: StorageServiceProtocol = StorageService.shared,
        patternEngine: PatternEngineProtocol = PatternEngine(),
        notifications: NotificationServiceProtocol = NotificationService.shared
    ) {
        self.storage = storage
        self.patternEngine = patternEngine
        self.notifications = notifications
        events = storage.loadEvents()
        preferences = storage.loadPreferences()
        notifications.requestPermission()
    }

    // MARK: - Events

    func logOdor(type: OdorType, intensity: Int, roomId: UUID, notes: String?, isEmergency: Bool) {
        let event = OdorEvent(
            type: type, intensity: intensity, roomId: roomId,
            detectedAt: Date(), notes: notes, isEmergency: isEmergency
        )
        events.insert(event, at: 0)
        storage.saveEvents(events)

        let profile = patternEngine.analyzeRoom(events, for: roomId)
        let assessment = patternEngine.isAnomalous(event, against: profile)

        if assessment.isAnomalous {
            handleAnomalyAlert(for: event, assessment: assessment)
        } else if isEmergency {
            notifications.sendEmergencyAlert(for: event, roomName: roomName(for: event.roomId))
        }
    }

    func resolveEvent(_ eventId: UUID) {
        guard let idx = events.firstIndex(where: { $0.id == eventId }) else { return }
        events[idx].resolvedAt = Date()
        storage.saveEvents(events)
    }

    func deleteEvent(_ eventId: UUID) {
        events.removeAll { $0.id == eventId }
        storage.saveEvents(events)
    }

    func eventsForRoom(_ roomId: UUID) -> [OdorEvent] {
        events.filter { $0.roomId == roomId }
    }

    func recentEvents(limit: Int = 20) -> [OdorEvent] {
        Array(events.prefix(limit))
    }

    var unresolvedCount: Int {
        events.filter { $0.resolvedAt == nil }.count
    }

    var emergencyCount: Int {
        events.filter { $0.isEmergency && $0.resolvedAt == nil }.count
    }

    // MARK: - Preferences

    func savePreferences() {
        storage.savePreferences(preferences)
    }

    func allRooms() -> [Room] { preferences.rooms }

    func roomName(for id: UUID) -> String {
        preferences.rooms.first { $0.id == id }?.name ?? "未知房间"
    }

    // MARK: - Alerts

    private func handleAnomalyAlert(for event: OdorEvent, assessment: AnomalyAssessment) {
        guard let rule = preferences.alertRules.first(where: { $0.odorTypes.contains(event.type) }) else { return }
        guard notifications.canAlert(for: event.type, cooldownMinutes: rule.cooldownMinutes) else { return }

        notifications.markAlertSent(for: event.type)
        notifications.sendAlert(
            for: event,
            assessment: assessment,
            roomName: roomName(for: event.roomId)
        )
    }
}
