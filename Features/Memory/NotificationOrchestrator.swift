import Foundation

enum NotificationScheduleResult: Equatable {
    case scheduled
    case skippedCooldown
    case skippedArchived
}

enum NotificationOrchestratorError: Error, Equatable {
    case invalidCooldownHours(Int)
    case permissionDenied
    case schedulingFailed
    case notImplemented
}

protocol NotificationOrchestratorProtocol {
    func scheduleNearbyReminder(memoryId: UUID, title: String, body: String, now: Date, cooldownHours: Int) async throws
        -> NotificationScheduleResult
    func extractMemoryId(from userInfo: [AnyHashable: Any]) -> UUID?
}

/// AI-01 scaffold only. Scheduling and cooldown logic lands in AI-06.
final class DefaultNotificationOrchestrator: NotificationOrchestratorProtocol {
    static let memoryIdUserInfoKey = "memoryId"

    func scheduleNearbyReminder(memoryId: UUID, title: String, body: String, now: Date, cooldownHours: Int) async throws
        -> NotificationScheduleResult {
        let _ = (memoryId, title, body, now, cooldownHours)
        throw NotificationOrchestratorError.notImplemented
    }

    func extractMemoryId(from userInfo: [AnyHashable: Any]) -> UUID? {
        if let uuid = userInfo[Self.memoryIdUserInfoKey] as? UUID {
            return uuid
        }

        if let rawValue = userInfo[Self.memoryIdUserInfoKey] as? String {
            return UUID(uuidString: rawValue)
        }

        return nil
    }
}
