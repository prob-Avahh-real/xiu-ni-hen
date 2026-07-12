import Foundation

protocol StorageServiceProtocol {
    func saveEvents(_ events: [OdorEvent])
    func loadEvents() -> [OdorEvent]
    func savePreferences(_ prefs: OdorPreferences)
    func loadPreferences() -> OdorPreferences
}

protocol PatternEngineProtocol {
    func analyzeRoom(_ events: [OdorEvent], for roomId: UUID) -> RoomOdorProfile
    func isAnomalous(_ event: OdorEvent, against profile: RoomOdorProfile) -> AnomalyAssessment
}

protocol NotificationServiceProtocol {
    func requestPermission()
    func sendAlert(for event: OdorEvent, assessment: AnomalyAssessment, roomName: String)
    func sendEmergencyAlert(for event: OdorEvent, roomName: String)
    func canAlert(for type: OdorType, cooldownMinutes: Int) -> Bool
    func markAlertSent(for type: OdorType)
}
