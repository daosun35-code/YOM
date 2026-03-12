import CoreLocation
import XCTest

final class GeofenceMonitorTests: XCTestCase {
    func testRefreshMonitorsSelectsNearestCandidatesWithinLimit() async throws {
        let driver = TestGeofenceMonitorDriver()
        let monitor = DefaultGeofenceMonitor(
            monitorName: "geofence-selection",
            driver: driver,
            authorizationProvider: TestGeofenceAuthorizationProvider(isAuthorized: true)
        )

        let selectedIDs = try await monitor.refreshMonitors(
            currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            candidates: [
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000001"), latitude: 37.7750, longitude: -122.4194),
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000002"), latitude: 37.7760, longitude: -122.4194),
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000003"), latitude: 37.7790, longitude: -122.4194)
            ],
            maxConditions: 2,
            now: fixedDate
        )

        XCTAssertEqual(
            selectedIDs,
            [
                uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000001"),
                uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000002")
            ]
        )

        let recordedConditions = driver.recordedSyncSnapshots()
        XCTAssertEqual(recordedConditions.count, 1)
        XCTAssertEqual(recordedConditions[0].map(\.memoryId), selectedIDs)
        XCTAssertEqual(recordedConditions[0].map(\.identifier), selectedIDs.map(\.uuidString))
        XCTAssertEqual(recordedConditions[0].map(\.radius), [200, 200])
    }

    func testRefreshMonitorsRotatesTrackedConditionsAcrossCalls() async throws {
        let driver = TestGeofenceMonitorDriver()
        let monitor = DefaultGeofenceMonitor(
            monitorName: "geofence-rotation",
            driver: driver,
            authorizationProvider: TestGeofenceAuthorizationProvider(isAuthorized: true)
        )

        _ = try await monitor.refreshMonitors(
            currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            candidates: [
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000001"), latitude: 37.7750, longitude: -122.4194),
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000002"), latitude: 37.7760, longitude: -122.4194)
            ],
            maxConditions: 2,
            now: fixedDate
        )

        _ = try await monitor.refreshMonitors(
            currentLocation: CLLocationCoordinate2D(latitude: 37.7810, longitude: -122.4194),
            candidates: [
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000002"), latitude: 37.7805, longitude: -122.4194),
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000003"), latitude: 37.7812, longitude: -122.4194),
                makeMemoryPoint(id: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000001"), latitude: 37.7700, longitude: -122.4194)
            ],
            maxConditions: 2,
            now: fixedDate.addingTimeInterval(60)
        )

        let recordedConditions = driver.recordedSyncSnapshots()
        XCTAssertEqual(recordedConditions.count, 2)
        XCTAssertEqual(
            recordedConditions[1].map(\.memoryId),
            [
                uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000003"),
                uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000002")
            ]
        )
    }

    func testRefreshMonitorsRejectsRequestedLimitAboveGovernanceThreshold() async {
        let driver = TestGeofenceMonitorDriver()
        let monitor = DefaultGeofenceMonitor(
            monitorName: "geofence-limit",
            driver: driver,
            authorizationProvider: TestGeofenceAuthorizationProvider(isAuthorized: true)
        )

        await XCTAssertThrowsErrorAsync(
            try await monitor.refreshMonitors(
                currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                candidates: [],
                maxConditions: 21,
                now: fixedDate
            )
        ) { error in
            XCTAssertEqual(error as? GeofenceMonitorError, .maxConditionsExceeded(limit: 20))
        }

        XCTAssertTrue(driver.recordedSyncSnapshots().isEmpty)
    }

    func testRefreshMonitorsThrowsPermissionDeniedWhenMonitoringIsUnauthorized() async {
        let driver = TestGeofenceMonitorDriver()
        let monitor = DefaultGeofenceMonitor(
            monitorName: "geofence-auth",
            driver: driver,
            authorizationProvider: TestGeofenceAuthorizationProvider(isAuthorized: false)
        )

        await XCTAssertThrowsErrorAsync(
            try await monitor.refreshMonitors(
                currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                candidates: [],
                maxConditions: 2,
                now: fixedDate
            )
        ) { error in
            XCTAssertEqual(error as? GeofenceMonitorError, .permissionDenied)
        }
    }

    func testStartEventStreamTranslatesSatisfiedAndUnsatisfiedEvents() async {
        let driver = TestGeofenceMonitorDriver()
        let monitor = DefaultGeofenceMonitor(
            monitorName: "geofence-events",
            driver: driver,
            authorizationProvider: TestGeofenceAuthorizationProvider(isAuthorized: true)
        )

        let memoryID = uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000099")
        let stream = monitor.startEventStream()
        let collector = Task { await self.collectEvents(from: stream, expectedCount: 2) }

        await driver.waitUntilStreamStarts()
        driver.emit(
            GeofenceDriverEvent(
                identifier: memoryID.uuidString,
                state: .satisfied,
                occurredAt: fixedDate
            )
        )
        driver.emit(
            GeofenceDriverEvent(
                identifier: memoryID.uuidString,
                state: .unknown,
                occurredAt: fixedDate.addingTimeInterval(5)
            )
        )
        driver.emit(
            GeofenceDriverEvent(
                identifier: memoryID.uuidString,
                state: .unsatisfied,
                occurredAt: fixedDate.addingTimeInterval(10)
            )
        )

        let events = await collector.value
        XCTAssertEqual(
            events,
            [
                GeofenceEvent(memoryId: memoryID, kind: .enter, occurredAt: fixedDate),
                GeofenceEvent(memoryId: memoryID, kind: .exit, occurredAt: fixedDate.addingTimeInterval(10))
            ]
        )

        monitor.stop()
        await driver.waitUntilStopCount(is: 1)
    }

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_742_000_000)
    }

    private func collectEvents(from stream: AsyncStream<GeofenceEvent>, expectedCount: Int) async -> [GeofenceEvent] {
        var iterator = stream.makeAsyncIterator()
        var events: [GeofenceEvent] = []

        while events.count < expectedCount, let event = await iterator.next() {
            events.append(event)
        }

        return events
    }

    private func makeMemoryPoint(id: UUID, latitude: Double, longitude: Double) -> MemoryPoint {
        let pointOfInterest = PointOfInterest(
            id: id,
            year: 1935,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            distanceMeters: 100,
            nameByLanguage: [.en: "Market Street Corner"],
            summaryByLanguage: [.en: "A neighborhood landmark remembered through local stories."]
        )

        return MemoryPoint(
            poi: pointOfInterest,
            storyByLanguage: [.en: "Residents used this corner as a meeting point during periods of migration and mutual aid."],
            unlockRadiusM: 80,
            tags: ["Neighborhood"],
            media: []
        )
    }

    private func uuid(_ rawValue: String) -> UUID {
        UUID(uuidString: rawValue) ?? UUID()
    }
}

private struct TestGeofenceAuthorizationProvider: GeofenceAuthorizationProviding {
    let isAuthorized: Bool

    func isAuthorizedForMonitoring() -> Bool {
        isAuthorized
    }
}

private final class TestGeofenceMonitorDriver: GeofenceMonitorDriving {
    private let lock = NSLock()
    private var syncSnapshots: [[GeofenceMonitoredCondition]] = []
    private var eventContinuation: AsyncThrowingStream<GeofenceDriverEvent, Error>.Continuation?
    private var stopCount = 0

    func syncConditions(named monitorName: String, conditions: [GeofenceMonitoredCondition]) async throws {
        let _ = monitorName
        lock.withLock {
            syncSnapshots.append(conditions)
        }
    }

    func startEventStream(named monitorName: String) async -> AsyncThrowingStream<GeofenceDriverEvent, Error> {
        let _ = monitorName

        return AsyncThrowingStream { continuation in
            lock.withLock {
                eventContinuation = continuation
            }
        }
    }

    func stop(named monitorName: String) async {
        let _ = monitorName

        let continuation = lock.withLock { () -> AsyncThrowingStream<GeofenceDriverEvent, Error>.Continuation? in
            stopCount += 1
            let currentContinuation = eventContinuation
            eventContinuation = nil
            return currentContinuation
        }

        continuation?.finish()
    }

    func emit(_ event: GeofenceDriverEvent) {
        let continuation = lock.withLock { eventContinuation }
        continuation?.yield(event)
    }

    func recordedSyncSnapshots() -> [[GeofenceMonitoredCondition]] {
        lock.withLock { syncSnapshots }
    }

    func waitUntilStreamStarts() async {
        while lock.withLock({ eventContinuation == nil }) {
            await Task.yield()
        }
    }

    func waitUntilStopCount(is expectedCount: Int) async {
        while lock.withLock({ stopCount < expectedCount }) {
            await Task.yield()
        }
    }
}

private extension NSLock {
    func withLock<T>(_ work: () -> T) -> T {
        lock()
        defer { unlock() }
        return work()
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure () async throws -> some Any,
    _ errorHandler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown")
    } catch {
        errorHandler(error)
    }
}
