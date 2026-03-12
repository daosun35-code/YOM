import UserNotifications
import XCTest

final class NotificationOrchestratorTests: XCTestCase {
    func testScheduleNearbyReminderSchedulesImmediateNotificationAndStoresCooldown() async throws {
        let notificationCenter = TestNotificationCenterScheduler(authorizationStatus: .authorized)
        let archiveChecker = TestNotificationArchiveChecker(isArchived: false)
        let cooldownTracker = TestNotificationCooldownTracker()
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: notificationCenter,
            archiveChecker: archiveChecker,
            cooldownTracker: cooldownTracker
        )

        let memoryID = uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000201")
        let now = fixedDate

        let result = try await orchestrator.scheduleNearbyReminder(
            memoryId: memoryID,
            title: "Nearby memory",
            body: "You are close to a local story.",
            now: now,
            cooldownHours: 24
        )

        XCTAssertEqual(result, .scheduled)

        let request = await notificationCenter.singlePendingRequest()
        XCTAssertEqual(request?.identifier, "community-memory-nearby.\(memoryID.uuidString)")
        XCTAssertEqual(request?.content.title, "Nearby memory")
        XCTAssertEqual(request?.content.body, "You are close to a local story.")
        XCTAssertEqual(orchestrator.extractMemoryId(from: request?.content.userInfo ?? [:]), memoryID)
        let scheduledAt = request?.content.userInfo[DefaultNotificationOrchestrator.scheduledAtUserInfoKey] as? Double
        XCTAssertNotNil(scheduledAt)
        XCTAssertEqual(scheduledAt ?? 0, now.timeIntervalSince1970, accuracy: 0.001)

        let lastScheduledAt = await cooldownTracker.lastScheduledAt(for: memoryID)
        XCTAssertEqual(lastScheduledAt, now)
    }

    func testScheduleNearbyReminderSkipsArchivedMemoryBeforeScheduling() async throws {
        let notificationCenter = TestNotificationCenterScheduler(authorizationStatus: .authorized)
        let archiveChecker = TestNotificationArchiveChecker(isArchived: true)
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: notificationCenter,
            archiveChecker: archiveChecker,
            cooldownTracker: TestNotificationCooldownTracker()
        )

        let result = try await orchestrator.scheduleNearbyReminder(
            memoryId: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000202"),
            title: "Nearby memory",
            body: "Body",
            now: fixedDate,
            cooldownHours: 24
        )

        XCTAssertEqual(result, .skippedArchived)
        let addCount = await notificationCenter.addCount()
        XCTAssertEqual(addCount, 0)
    }

    func testScheduleNearbyReminderSkipsWhenCooldownTrackerShowsRecentReminder() async throws {
        let memoryID = uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000203")
        let notificationCenter = TestNotificationCenterScheduler(authorizationStatus: .authorized)
        let cooldownTracker = TestNotificationCooldownTracker()
        await cooldownTracker.setLastScheduledAt(fixedDate.addingTimeInterval(-23 * 3600), for: memoryID)
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: notificationCenter,
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: cooldownTracker
        )

        let result = try await orchestrator.scheduleNearbyReminder(
            memoryId: memoryID,
            title: "Nearby memory",
            body: "Body",
            now: fixedDate,
            cooldownHours: 24
        )

        XCTAssertEqual(result, .skippedCooldown)
        let addCount = await notificationCenter.addCount()
        XCTAssertEqual(addCount, 0)
    }

    func testScheduleNearbyReminderSkipsDuplicatePendingRequestWithinCooldown() async throws {
        let memoryID = uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000204")
        let notificationCenter = TestNotificationCenterScheduler(
            authorizationStatus: .authorized,
            initialPendingRequests: [makeRequest(memoryId: memoryID, scheduledAt: fixedDate.addingTimeInterval(-600))]
        )
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: notificationCenter,
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: TestNotificationCooldownTracker()
        )

        let result = try await orchestrator.scheduleNearbyReminder(
            memoryId: memoryID,
            title: "Nearby memory",
            body: "Body",
            now: fixedDate,
            cooldownHours: 24
        )

        XCTAssertEqual(result, .skippedCooldown)
        let addCount = await notificationCenter.addCount()
        let pendingCount = await notificationCenter.pendingRequestCount()
        XCTAssertEqual(addCount, 0)
        XCTAssertEqual(pendingCount, 1)
    }

    func testScheduleNearbyReminderReschedulesAfterCooldownWindowExpires() async throws {
        let memoryID = uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000205")
        let notificationCenter = TestNotificationCenterScheduler(
            authorizationStatus: .authorized,
            initialPendingRequests: [makeRequest(memoryId: memoryID, scheduledAt: fixedDate.addingTimeInterval(-25 * 3600))]
        )
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: notificationCenter,
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: TestNotificationCooldownTracker()
        )

        let result = try await orchestrator.scheduleNearbyReminder(
            memoryId: memoryID,
            title: "Nearby memory",
            body: "Body",
            now: fixedDate,
            cooldownHours: 24
        )

        XCTAssertEqual(result, .scheduled)
        let addCount = await notificationCenter.addCount()
        let pendingCount = await notificationCenter.pendingRequestCount()
        XCTAssertEqual(addCount, 1)
        XCTAssertEqual(pendingCount, 1)

        let request = await notificationCenter.singlePendingRequest()
        let scheduledAt = request?.content.userInfo[DefaultNotificationOrchestrator.scheduledAtUserInfoKey] as? Double
        XCTAssertNotNil(scheduledAt)
        XCTAssertEqual(scheduledAt ?? 0, fixedDate.timeIntervalSince1970, accuracy: 0.001)
    }

    func testScheduleNearbyReminderThrowsPermissionDeniedWhenNotificationsAreUnavailable() async {
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: TestNotificationCenterScheduler(authorizationStatus: .denied),
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: TestNotificationCooldownTracker()
        )

        await XCTAssertThrowsErrorAsync(
            try await orchestrator.scheduleNearbyReminder(
                memoryId: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000206"),
                title: "Nearby memory",
                body: "Body",
                now: fixedDate,
                cooldownHours: 24
            )
        ) { error in
            XCTAssertEqual(error as? NotificationOrchestratorError, .permissionDenied)
        }
    }

    func testScheduleNearbyReminderThrowsInvalidCooldownWhenLessThanOneHour() async {
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: TestNotificationCenterScheduler(authorizationStatus: .authorized),
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: TestNotificationCooldownTracker()
        )

        await XCTAssertThrowsErrorAsync(
            try await orchestrator.scheduleNearbyReminder(
                memoryId: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000207"),
                title: "Nearby memory",
                body: "Body",
                now: fixedDate,
                cooldownHours: 0
            )
        ) { error in
            XCTAssertEqual(error as? NotificationOrchestratorError, .invalidCooldownHours(0))
        }
    }

    func testExtractMemoryIdSupportsUUIDAndStringPayloads() {
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: TestNotificationCenterScheduler(authorizationStatus: .authorized),
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: TestNotificationCooldownTracker()
        )
        let memoryID = uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000208")

        XCTAssertEqual(
            orchestrator.extractMemoryId(from: [DefaultNotificationOrchestrator.memoryIdUserInfoKey: memoryID]),
            memoryID
        )
        XCTAssertEqual(
            orchestrator.extractMemoryId(from: [DefaultNotificationOrchestrator.memoryIdUserInfoKey: memoryID.uuidString]),
            memoryID
        )
        XCTAssertNil(orchestrator.extractMemoryId(from: [DefaultNotificationOrchestrator.memoryIdUserInfoKey: "invalid"]))
    }

    func testScheduleNearbyReminderFailsWhenExecutionBudgetIsExceeded() async {
        let notificationCenter = TestNotificationCenterScheduler(
            authorizationStatus: .authorized,
            authorizationDelay: 0.15
        )
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: notificationCenter,
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: TestNotificationCooldownTracker(),
            executionBudgetSeconds: 0.05
        )

        await XCTAssertThrowsErrorAsync(
            try await orchestrator.scheduleNearbyReminder(
                memoryId: uuid("AAAAAAAA-BBBB-CCCC-DDDD-000000000209"),
                title: "Nearby memory",
                body: "Body",
                now: fixedDate,
                cooldownHours: 24
            )
        ) { error in
            XCTAssertEqual(error as? NotificationOrchestratorError, .schedulingFailed)
        }

        let addCount = await notificationCenter.addCount()
        XCTAssertEqual(addCount, 0)
    }

    func testScheduleNearbyReminderCompletesTwentySamplesWellWithinBudget() async throws {
        let notificationCenter = TestNotificationCenterScheduler(authorizationStatus: .authorized)
        let orchestrator = DefaultNotificationOrchestrator(
            notificationCenter: notificationCenter,
            archiveChecker: TestNotificationArchiveChecker(isArchived: false),
            cooldownTracker: TestNotificationCooldownTracker(),
            executionBudgetSeconds: 10
        )

        let clock = ContinuousClock()
        var durations: [Duration] = []

        for index in 0 ..< 20 {
            let start = clock.now
            let result = try await orchestrator.scheduleNearbyReminder(
                memoryId: uuid(String(format: "AAAAAAAA-BBBB-CCCC-DDDD-%012d", index + 300)),
                title: "Nearby memory",
                body: "Body",
                now: fixedDate.addingTimeInterval(TimeInterval(index)),
                cooldownHours: 24
            )
            durations.append(start.duration(to: clock.now))
            XCTAssertEqual(result, .scheduled)
        }

        let sortedDurations = durations.sorted()
        let p95Duration = sortedDurations[Int(Double(sortedDurations.count - 1) * 0.95)]
        XCTAssertLessThan(p95Duration.components.seconds, 1)
    }

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_742_000_000)
    }

    private func makeRequest(memoryId: UUID, scheduledAt: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Nearby memory"
        content.body = "Body"
        content.userInfo = [
            DefaultNotificationOrchestrator.memoryIdUserInfoKey: memoryId.uuidString,
            DefaultNotificationOrchestrator.scheduledAtUserInfoKey: scheduledAt.timeIntervalSince1970
        ]
        return UNNotificationRequest(
            identifier: "community-memory-nearby.\(memoryId.uuidString)",
            content: content,
            trigger: nil
        )
    }

    private func uuid(_ rawValue: String) -> UUID {
        UUID(uuidString: rawValue) ?? UUID()
    }
}

private final class TestNotificationArchiveChecker: NotificationArchiveChecking, @unchecked Sendable {
    private let archived: Bool

    init(isArchived: Bool) {
        self.archived = isArchived
    }

    func isArchived(memoryId: UUID) async throws -> Bool {
        let _ = memoryId
        return archived
    }
}

private final class TestNotificationCooldownTracker: NotificationCooldownTracking, @unchecked Sendable {
    private let stateLock = NSLock()
    private var scheduledDates: [UUID: Date] = [:]

    func lastScheduledAt(for memoryId: UUID) async -> Date? {
        stateLock.withLock { scheduledDates[memoryId] }
    }

    func setLastScheduledAt(_ date: Date, for memoryId: UUID) async {
        stateLock.withLock {
            scheduledDates[memoryId] = date
        }
    }
}

private final class TestNotificationCenterScheduler: NotificationCenterScheduling, @unchecked Sendable {
    private let stateLock = NSLock()
    private let authorizationStatusValue: UNAuthorizationStatus
    private let authorizationDelay: TimeInterval
    private var pendingRequestsStorage: [String: UNNotificationRequest]
    private var addOperations = 0

    init(
        authorizationStatus: UNAuthorizationStatus,
        initialPendingRequests: [UNNotificationRequest] = [],
        authorizationDelay: TimeInterval = 0
    ) {
        self.authorizationStatusValue = authorizationStatus
        self.authorizationDelay = authorizationDelay
        self.pendingRequestsStorage = Dictionary(
            uniqueKeysWithValues: initialPendingRequests.map { ($0.identifier, $0) }
        )
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        if authorizationDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64((authorizationDelay * 1_000_000_000).rounded()))
        }
        return authorizationStatusValue
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        stateLock.withLock {
            pendingRequestsStorage.values.sorted { $0.identifier < $1.identifier }
        }
    }

    func add(_ request: UNNotificationRequest) async throws {
        stateLock.withLock {
            addOperations += 1
            pendingRequestsStorage[request.identifier] = request
        }
    }

    func addCount() async -> Int {
        stateLock.withLock { addOperations }
    }

    func pendingRequestCount() async -> Int {
        stateLock.withLock { pendingRequestsStorage.count }
    }

    func singlePendingRequest() async -> UNNotificationRequest? {
        stateLock.withLock { pendingRequestsStorage.values.first }
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
