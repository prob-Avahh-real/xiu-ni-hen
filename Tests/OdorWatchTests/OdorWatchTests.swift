import XCTest
@testable import OdorWatch

final class OdorWatchTests: XCTestCase {

    func testOdorTypeAllCases() {
        let all = OdorType.allCases
        XCTAssertEqual(all.count, 10)
        XCTAssertTrue(all.contains(.smoke))
        XCTAssertTrue(all.contains(.gas))
        XCTAssertTrue(all.contains(.mold))
        XCTAssertTrue(all.contains(.unknown))
    }

    func testOdorTypeIcons() {
        XCTAssertEqual(OdorType.smoke.icon, "🔥")
        XCTAssertEqual(OdorType.gas.icon, "⚠️")
        XCTAssertEqual(OdorType.unknown.icon, "❓")
    }

    func testOdorEventCreation() {
        let roomId = UUID()
        let event = OdorEvent(
            type: .smoke,
            intensity: 3,
            roomId: roomId,
            detectedAt: Date(),
            notes: "疑似烧焦",
            isEmergency: false
        )
        XCTAssertEqual(event.type, .smoke)
        XCTAssertEqual(event.intensity, 3)
        XCTAssertEqual(event.roomId, roomId)
        XCTAssertNil(event.resolvedAt)
    }

    func testPatternEngineFirstOccurrenceIsAnomalous() {
        let engine = PatternEngine()
        let roomId = UUID()
        let event = OdorEvent(
            type: .smoke,
            intensity: 3,
            roomId: roomId,
            detectedAt: Date(),
            notes: nil,
            isEmergency: false
        )
        let profile = engine.analyzeRoom([event], for: roomId)
        let assessment = engine.isAnomalous(event, against: profile)
        XCTAssertTrue(assessment.isAnomalous)
    }

    func testStorageServiceRoundTrip() {
        let service = StorageService.shared
        let roomId = UUID()
        let events = [
            OdorEvent(
                type: .smoke,
                intensity: 3,
                roomId: roomId,
                detectedAt: Date(),
                notes: "测试",
                isEmergency: false
            )
        ]
        service.saveEvents(events)
        let loaded = service.loadEvents()
        XCTAssertEqual(loaded.count, events.count)
        XCTAssertEqual(loaded.first?.type, .smoke)
    }

    func testAirQualityLevel() {
        let quality = AirQuality(voc: 30, pm25: 10, co2: 500)
        XCTAssertEqual(quality.level, .good)
    }

    func testQuietHoursCodable() throws {
        let prefs = OdorPreferences()
        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(OdorPreferences.self, from: data)
        XCTAssertEqual(decoded.notificationQuietHours, prefs.notificationQuietHours)
    }
}
