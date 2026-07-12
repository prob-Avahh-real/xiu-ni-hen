import Foundation

final class StorageService: StorageServiceProtocol {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let eventsKey = "odor_events"
    private let prefsKey = "odor_preferences"

    func saveEvents(_ events: [OdorEvent]) {
        guard let data = try? encoder.encode(events) else { return }
        defaults.set(data, forKey: eventsKey)
    }

    func loadEvents() -> [OdorEvent] {
        guard let data = defaults.data(forKey: eventsKey),
              let events = try? decoder.decode([OdorEvent].self, from: data)
        else { return [] }
        return events
    }

    func savePreferences(_ prefs: OdorPreferences) {
        guard let data = try? encoder.encode(prefs) else { return }
        defaults.set(data, forKey: prefsKey)
    }

    func loadPreferences() -> OdorPreferences {
        guard let data = defaults.data(forKey: prefsKey),
              let p = try? decoder.decode(OdorPreferences.self, from: data)
        else { return OdorPreferences() }
        return p
    }
}
