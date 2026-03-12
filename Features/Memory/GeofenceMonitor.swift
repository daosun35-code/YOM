import CoreLocation
import Foundation

enum GeofenceEventKind: String, Equatable {
    case enter
    case exit
}

struct GeofenceEvent: Equatable {
    let memoryId: UUID
    let kind: GeofenceEventKind
    let occurredAt: Date
}

enum GeofenceMonitorError: Error, Equatable {
    case permissionDenied
    case maxConditionsExceeded(limit: Int)
    case systemFailure
    case notImplemented
}

protocol GeofenceMonitorProtocol {
    func refreshMonitors(currentLocation: CLLocationCoordinate2D, candidates: [MemoryPoint], maxConditions: Int, now: Date)
        async throws -> [UUID]
    func startEventStream() -> AsyncStream<GeofenceEvent>
    func stop()
}

struct GeofenceMonitoredCondition: Equatable {
    let memoryId: UUID
    let identifier: String
    let center: CLLocationCoordinate2D
    let radius: CLLocationDistance

    static func == (lhs: GeofenceMonitoredCondition, rhs: GeofenceMonitoredCondition) -> Bool {
        lhs.memoryId == rhs.memoryId &&
            lhs.identifier == rhs.identifier &&
            lhs.center.latitude == rhs.center.latitude &&
            lhs.center.longitude == rhs.center.longitude &&
            lhs.radius == rhs.radius
    }
}

struct GeofenceDriverEvent: Equatable {
    let identifier: String
    let state: CLMonitor.Event.State
    let occurredAt: Date
}

protocol GeofenceCandidateSelecting {
    func selectMonitoredConditions(
        currentLocation: CLLocationCoordinate2D,
        candidates: [MemoryPoint],
        limit: Int
    ) -> [GeofenceMonitoredCondition]
}

struct GeofenceCandidateSelector: GeofenceCandidateSelecting {
    let reminderRadiusM: CLLocationDistance

    init(reminderRadiusM: CLLocationDistance = 200) {
        self.reminderRadiusM = reminderRadiusM
    }

    func selectMonitoredConditions(
        currentLocation: CLLocationCoordinate2D,
        candidates: [MemoryPoint],
        limit: Int
    ) -> [GeofenceMonitoredCondition] {
        guard limit > 0 else { return [] }

        let origin = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let uniqueCandidates = Array(Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) }).values)

        return uniqueCandidates
            .sorted { lhs, rhs in
                let lhsDistance = distance(from: origin, to: lhs.coordinate)
                let rhsDistance = distance(from: origin, to: rhs.coordinate)

                if lhsDistance == rhsDistance {
                    return lhs.id.uuidString < rhs.id.uuidString
                }

                return lhsDistance < rhsDistance
            }
            .prefix(limit)
            .map { candidate in
                GeofenceMonitoredCondition(
                    memoryId: candidate.id,
                    identifier: candidate.id.uuidString,
                    center: candidate.coordinate,
                    radius: reminderRadiusM
                )
            }
    }

    private func distance(from origin: CLLocation, to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return origin.distance(from: target)
    }
}

protocol GeofenceMonitorDriving: AnyObject {
    func syncConditions(named monitorName: String, conditions: [GeofenceMonitoredCondition]) async throws
    func startEventStream(named monitorName: String) async -> AsyncThrowingStream<GeofenceDriverEvent, Error>
    func stop(named monitorName: String) async
}

protocol GeofenceAuthorizationProviding {
    func isAuthorizedForMonitoring() -> Bool
}

struct SystemGeofenceAuthorizationProvider: GeofenceAuthorizationProviding {
    func isAuthorizedForMonitoring() -> Bool {
        guard CLLocationManager.locationServicesEnabled() else {
            return false
        }

        return CLLocationManager().authorizationStatus == .authorizedAlways
    }
}

final class DefaultGeofenceMonitor: GeofenceMonitorProtocol {
    private static let governanceLimit = 20
    private static let defaultMonitorName = "CommunityMemoryGeofenceMonitor"

    private let monitorName: String
    private let governanceLimit: Int
    private let selector: any GeofenceCandidateSelecting
    private let driver: any GeofenceMonitorDriving
    private let authorizationProvider: any GeofenceAuthorizationProviding

    private let stateLock = NSLock()
    private var eventContinuations: [UUID: AsyncStream<GeofenceEvent>.Continuation] = [:]
    private var bridgeTask: Task<Void, Never>?

    init(
        monitorName: String = DefaultGeofenceMonitor.defaultMonitorName,
        governanceLimit: Int = DefaultGeofenceMonitor.governanceLimit,
        selector: any GeofenceCandidateSelecting = GeofenceCandidateSelector(),
        driver: any GeofenceMonitorDriving = SystemCLMonitorDriver(),
        authorizationProvider: any GeofenceAuthorizationProviding = SystemGeofenceAuthorizationProvider()
    ) {
        self.monitorName = monitorName
        self.governanceLimit = governanceLimit
        self.selector = selector
        self.driver = driver
        self.authorizationProvider = authorizationProvider
    }

    func refreshMonitors(
        currentLocation: CLLocationCoordinate2D,
        candidates: [MemoryPoint],
        maxConditions: Int,
        now: Date
    ) async throws -> [UUID] {
        let _ = now

        guard authorizationProvider.isAuthorizedForMonitoring() else {
            throw GeofenceMonitorError.permissionDenied
        }

        guard maxConditions <= governanceLimit else {
            throw GeofenceMonitorError.maxConditionsExceeded(limit: governanceLimit)
        }

        let selectedConditions = selector.selectMonitoredConditions(
            currentLocation: currentLocation,
            candidates: candidates,
            limit: maxConditions
        )

        do {
            try await driver.syncConditions(named: monitorName, conditions: selectedConditions)
        } catch let error as GeofenceMonitorError {
            throw error
        } catch {
            throw GeofenceMonitorError.systemFailure
        }

        return selectedConditions.map(\.memoryId)
    }

    func startEventStream() -> AsyncStream<GeofenceEvent> {
        ensureEventBridgeStarted()

        let streamID = UUID()
        return AsyncStream { continuation in
            stateLock.withLock {
                eventContinuations[streamID] = continuation
            }

            continuation.onTermination = { [weak self] _ in
                self?.removeContinuation(id: streamID)
            }
        }
    }

    func stop() {
        let taskToCancel = stateLock.withLock { () -> Task<Void, Never>? in
            let currentTask = bridgeTask
            bridgeTask = nil
            return currentTask
        }

        taskToCancel?.cancel()
        finishAllContinuations()

        Task { [driver, monitorName] in
            await driver.stop(named: monitorName)
        }
    }

    private func ensureEventBridgeStarted() {
        let shouldStart = stateLock.withLock { () -> Bool in
            guard bridgeTask == nil else { return false }
            bridgeTask = Task { [weak self] in
                await self?.bridgeDriverEvents()
            }
            return true
        }

        if shouldStart == false {
            return
        }
    }

    private func bridgeDriverEvents() async {
        let driverStream = await driver.startEventStream(named: monitorName)

        do {
            for try await driverEvent in driverStream {
                guard let translatedEvent = translate(driverEvent) else {
                    continue
                }
                yield(translatedEvent)
            }
        } catch {
            finishAllContinuations()
        }
    }

    private func translate(_ driverEvent: GeofenceDriverEvent) -> GeofenceEvent? {
        guard let memoryId = UUID(uuidString: driverEvent.identifier) else {
            return nil
        }

        let kind: GeofenceEventKind
        switch driverEvent.state {
        case .satisfied:
            kind = .enter
        case .unsatisfied:
            kind = .exit
        case .unknown, .unmonitored:
            return nil
        @unknown default:
            return nil
        }

        return GeofenceEvent(memoryId: memoryId, kind: kind, occurredAt: driverEvent.occurredAt)
    }

    private func yield(_ event: GeofenceEvent) {
        let continuations = stateLock.withLock { Array(eventContinuations.values) }
        continuations.forEach { $0.yield(event) }
    }

    private func finishAllContinuations() {
        let continuations = stateLock.withLock { () -> [AsyncStream<GeofenceEvent>.Continuation] in
            let activeContinuations = Array(eventContinuations.values)
            eventContinuations.removeAll()
            return activeContinuations
        }

        continuations.forEach { $0.finish() }
    }

    private func removeContinuation(id: UUID) {
        _ = stateLock.withLock {
            eventContinuations.removeValue(forKey: id)
        }
    }
}

actor SystemCLMonitorDriver: GeofenceMonitorDriving {
    private var monitorsByName: [String: CLMonitor] = [:]

    func syncConditions(named monitorName: String, conditions: [GeofenceMonitoredCondition]) async throws {
        let monitor = await monitor(named: monitorName)
        let existingIdentifiers = Set(await monitor.identifiers)
        let targetConditions = Dictionary(uniqueKeysWithValues: conditions.map { ($0.identifier, $0) })

        for identifier in existingIdentifiers.subtracting(targetConditions.keys) {
            await monitor.remove(identifier)
        }

        for condition in conditions {
            let requiresUpdate: Bool
            if let record = await monitor.record(for: condition.identifier),
               let existingCondition = record.condition as? CLMonitor.CircularGeographicCondition,
               existingCondition.center.latitude == condition.center.latitude,
               existingCondition.center.longitude == condition.center.longitude,
               existingCondition.radius == condition.radius {
                requiresUpdate = false
            } else {
                requiresUpdate = true
            }

            guard requiresUpdate else {
                continue
            }

            if existingIdentifiers.contains(condition.identifier) {
                await monitor.remove(condition.identifier)
            }

            let circularCondition = CLMonitor.CircularGeographicCondition(
                center: condition.center,
                radius: condition.radius
            )
            await monitor.add(circularCondition, identifier: condition.identifier)
        }
    }

    func startEventStream(named monitorName: String) async -> AsyncThrowingStream<GeofenceDriverEvent, Error> {
        let monitor = await monitor(named: monitorName)
        let events = await monitor.events

        return AsyncThrowingStream { continuation in
            let readerTask = Task {
                do {
                    for try await event in events {
                        continuation.yield(
                            GeofenceDriverEvent(
                                identifier: event.identifier,
                                state: event.state,
                                occurredAt: event.date
                            )
                        )
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: GeofenceMonitorError.systemFailure)
                }
            }

            continuation.onTermination = { _ in
                readerTask.cancel()
            }
        }
    }

    func stop(named monitorName: String) async {
        monitorsByName.removeValue(forKey: monitorName)
    }

    private func monitor(named monitorName: String) async -> CLMonitor {
        if let existingMonitor = monitorsByName[monitorName] {
            return existingMonitor
        }

        let monitor = await CLMonitor(monitorName)
        monitorsByName[monitorName] = monitor
        return monitor
    }
}

private extension NSLock {
    func withLock<T>(_ work: () -> T) -> T {
        lock()
        defer { unlock() }
        return work()
    }
}
