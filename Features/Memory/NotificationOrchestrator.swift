import Foundation
import OSLog
import UserNotifications

enum NotificationScheduleResult: Equatable {
    case scheduled
    case skippedCooldown
    case skippedArchived
}

enum NotificationOrchestratorError: Error, Equatable {
    case invalidCooldownHours(Int)
    case permissionDenied
    case schedulingFailed
}

protocol NotificationOrchestratorProtocol {
    func scheduleNearbyReminder(memoryId: UUID, title: String, body: String, now: Date, cooldownHours: Int) async throws
        -> NotificationScheduleResult
    func extractMemoryId(from userInfo: [AnyHashable: Any]) -> UUID?
}

protocol NotificationArchiveChecking: Sendable {
    func isArchived(memoryId: UUID) async throws -> Bool
}

struct NoOpNotificationArchiveChecker: NotificationArchiveChecking {
    func isArchived(memoryId: UUID) async throws -> Bool {
        let _ = memoryId
        return false
    }
}

final class ExplorationStoreArchiveChecker: NotificationArchiveChecking, @unchecked Sendable {
    private let store: any ExplorationStoreProtocol

    init(store: any ExplorationStoreProtocol) {
        self.store = store
    }

    func isArchived(memoryId: UUID) async throws -> Bool {
        try await MainActor.run {
            try store.isArchived(memoryPointId: memoryId)
        }
    }
}

protocol NotificationCenterScheduling: Sendable {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
}

final class SystemNotificationCenterScheduler: NotificationCenterScheduling, @unchecked Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }
}

protocol NotificationCooldownTracking: Sendable {
    func lastScheduledAt(for memoryId: UUID) async -> Date?
    func setLastScheduledAt(_ date: Date, for memoryId: UUID) async
}

final class UserDefaultsNotificationCooldownTracker: NotificationCooldownTracking, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let stateLock = NSLock()

    init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "community-memory.notificationCooldown"
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }

    func lastScheduledAt(for memoryId: UUID) async -> Date? {
        stateLock.withLock {
            guard let timestamp = userDefaults.object(forKey: storageKey(for: memoryId)) as? Double else {
                return nil
            }
            return Date(timeIntervalSince1970: timestamp)
        }
    }

    func setLastScheduledAt(_ date: Date, for memoryId: UUID) async {
        stateLock.withLock {
            userDefaults.set(date.timeIntervalSince1970, forKey: storageKey(for: memoryId))
        }
    }

    private func storageKey(for memoryId: UUID) -> String {
        "\(keyPrefix).\(memoryId.uuidString)"
    }
}

struct NotificationPayloadBuilder: Sendable {
    static let memoryIdUserInfoKey = "memoryId"
    static let scheduledAtUserInfoKey = "scheduledAt"
    static let requestIdentifierPrefix = "community-memory-nearby"

    func makeRequest(memoryId: UUID, title: String, body: String, scheduledAt: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = [
            Self.memoryIdUserInfoKey: memoryId.uuidString,
            Self.scheduledAtUserInfoKey: scheduledAt.timeIntervalSince1970
        ]

        return UNNotificationRequest(
            identifier: requestIdentifier(for: memoryId),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
    }

    func requestIdentifier(for memoryId: UUID) -> String {
        "\(Self.requestIdentifierPrefix).\(memoryId.uuidString)"
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

    func extractScheduledAt(from userInfo: [AnyHashable: Any]) -> Date? {
        if let date = userInfo[Self.scheduledAtUserInfoKey] as? Date {
            return date
        }

        if let timestamp = userInfo[Self.scheduledAtUserInfoKey] as? Double {
            return Date(timeIntervalSince1970: timestamp)
        }

        if let number = userInfo[Self.scheduledAtUserInfoKey] as? NSNumber {
            return Date(timeIntervalSince1970: number.doubleValue)
        }

        if let rawValue = userInfo[Self.scheduledAtUserInfoKey] as? String,
           let timestamp = Double(rawValue) {
            return Date(timeIntervalSince1970: timestamp)
        }

        return nil
    }
}

struct NotificationCooldownPolicy: Sendable {
    private let tracker: any NotificationCooldownTracking
    private let payloadBuilder: NotificationPayloadBuilder

    init(
        tracker: any NotificationCooldownTracking,
        payloadBuilder: NotificationPayloadBuilder = NotificationPayloadBuilder()
    ) {
        self.tracker = tracker
        self.payloadBuilder = payloadBuilder
    }

    func shouldSkipScheduling(
        memoryId: UUID,
        now: Date,
        cooldownHours: Int,
        pendingRequests: [UNNotificationRequest]
    ) async -> Bool {
        let cutoff = now.addingTimeInterval(-Double(cooldownHours) * 3600)
        let trackedDate = await tracker.lastScheduledAt(for: memoryId)
        let pendingDate = pendingRequests
            .compactMap { pendingRequest -> Date? in
                let matchesRequest = pendingRequest.identifier == payloadBuilder.requestIdentifier(for: memoryId)
                    || payloadBuilder.extractMemoryId(from: pendingRequest.content.userInfo) == memoryId
                guard matchesRequest else {
                    return nil
                }

                return payloadBuilder.extractScheduledAt(from: pendingRequest.content.userInfo) ?? now
            }
            .max()

        guard let lastReminderAt = [trackedDate, pendingDate].compactMap({ $0 }).max() else {
            return false
        }

        return lastReminderAt > cutoff
    }

    func markScheduled(memoryId: UUID, at date: Date) async {
        await tracker.setLastScheduledAt(date, for: memoryId)
    }
}

final class DefaultNotificationOrchestrator: NotificationOrchestratorProtocol {
    static let memoryIdUserInfoKey = NotificationPayloadBuilder.memoryIdUserInfoKey
    static let scheduledAtUserInfoKey = NotificationPayloadBuilder.scheduledAtUserInfoKey

    private let notificationCenter: any NotificationCenterScheduling
    private let archiveChecker: any NotificationArchiveChecking
    private let payloadBuilder: NotificationPayloadBuilder
    private let cooldownPolicy: NotificationCooldownPolicy
    private let executionBudgetSeconds: TimeInterval
    private let logger: Logger

    init(
        notificationCenter: any NotificationCenterScheduling = SystemNotificationCenterScheduler(),
        archiveChecker: any NotificationArchiveChecking = NoOpNotificationArchiveChecker(),
        cooldownTracker: any NotificationCooldownTracking = UserDefaultsNotificationCooldownTracker(),
        payloadBuilder: NotificationPayloadBuilder = NotificationPayloadBuilder(),
        executionBudgetSeconds: TimeInterval = 10,
        logger: Logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "YOM",
            category: "NotificationOrchestrator"
        )
    ) {
        self.notificationCenter = notificationCenter
        self.archiveChecker = archiveChecker
        self.payloadBuilder = payloadBuilder
        self.cooldownPolicy = NotificationCooldownPolicy(tracker: cooldownTracker, payloadBuilder: payloadBuilder)
        self.executionBudgetSeconds = executionBudgetSeconds
        self.logger = logger
    }

    func scheduleNearbyReminder(memoryId: UUID, title: String, body: String, now: Date, cooldownHours: Int) async throws
        -> NotificationScheduleResult {
        guard cooldownHours >= 1 else {
            throw NotificationOrchestratorError.invalidCooldownHours(cooldownHours)
        }

        do {
            return try await withTimeout(seconds: executionBudgetSeconds) {
                let authorizationStatus = await self.notificationCenter.authorizationStatus()
                try Task.checkCancellation()
                guard authorizationStatus.allowsNearbyReminderScheduling else {
                    throw NotificationOrchestratorError.permissionDenied
                }

                if try await self.archiveChecker.isArchived(memoryId: memoryId) {
                    return .skippedArchived
                }
                try Task.checkCancellation()

                let pendingRequests = await self.notificationCenter.pendingRequests()
                try Task.checkCancellation()
                if await self.cooldownPolicy.shouldSkipScheduling(
                    memoryId: memoryId,
                    now: now,
                    cooldownHours: cooldownHours,
                    pendingRequests: pendingRequests
                ) {
                    return .skippedCooldown
                }
                try Task.checkCancellation()

                let request = self.payloadBuilder.makeRequest(
                    memoryId: memoryId,
                    title: title,
                    body: body,
                    scheduledAt: now
                )

                do {
                    try await self.notificationCenter.add(request)
                } catch {
                    throw NotificationOrchestratorError.schedulingFailed
                }

                await self.cooldownPolicy.markScheduled(memoryId: memoryId, at: now)
                try Task.checkCancellation()
                return .scheduled
            }
        } catch NotificationExecutionTimeoutError.exceededBudget {
            logger.error("[BgBudget] exceeded \(self.executionBudgetSeconds, privacy: .public)s, notification skipped")
            throw NotificationOrchestratorError.schedulingFailed
        }
    }

    func extractMemoryId(from userInfo: [AnyHashable: Any]) -> UUID? {
        payloadBuilder.extractMemoryId(from: userInfo)
    }
}

private enum NotificationExecutionTimeoutError: Error {
    case exceededBudget
}

private func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let timeoutNanoseconds = UInt64((seconds * 1_000_000_000).rounded())

    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: timeoutNanoseconds)
            throw NotificationExecutionTimeoutError.exceededBudget
        }

        let result = try await group.next() ?? {
            throw NotificationExecutionTimeoutError.exceededBudget
        }()
        group.cancelAll()
        return result
    }
}

private extension UNAuthorizationStatus {
    var allowsNearbyReminderScheduling: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
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
