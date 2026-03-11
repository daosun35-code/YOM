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

/// AI-01 scaffold only. CLMonitor integration lands in AI-05.
final class DefaultGeofenceMonitor: GeofenceMonitorProtocol {
    func refreshMonitors(currentLocation: CLLocationCoordinate2D, candidates: [MemoryPoint], maxConditions: Int, now: Date)
        async throws -> [UUID] {
        let _ = (currentLocation, candidates, maxConditions, now)
        throw GeofenceMonitorError.notImplemented
    }

    func startEventStream() -> AsyncStream<GeofenceEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func stop() {}
}
