import CoreLocation
import UIKit
import UserNotifications

enum PassiveReminderError: Error, Equatable {
    case backgroundRefreshUnavailable
    case notificationPermissionDenied
    case locationPermissionDenied
    case currentLocationUnavailable
    case geofenceRegistrationFailed
}

struct PassiveNavigationRequest: Identifiable, Equatable {
    let memoryId: UUID
    let source: ExplorationSource

    var id: UUID { memoryId }
}

protocol BackgroundRefreshStatusProviding {
    func currentStatus() -> UIBackgroundRefreshStatus
}

struct SystemBackgroundRefreshStatusProvider: BackgroundRefreshStatusProviding {
    func currentStatus() -> UIBackgroundRefreshStatus {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["UITEST_FORCE_PASSIVE_READY"] == "1" {
            return .available
        }
        if environment["UITEST_SIMULATE_BG_REFRESH_UNAVAILABLE"] == "1" {
            return .denied
        }
#endif
        return UIApplication.shared.backgroundRefreshStatus
    }
}

protocol PassiveNotificationAuthorizing {
    func ensureAuthorization() async -> Bool
}

struct SystemPassiveNotificationAuthorizer: PassiveNotificationAuthorizing {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func ensureAuthorization() async -> Bool {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["UITEST_FORCE_PASSIVE_READY"] == "1" ||
            environment["UITEST_FORCE_NOTIFICATION_AUTHORIZED"] == "1" {
            return true
        }
        if environment["UITEST_FORCE_NOTIFICATION_DENIED"] == "1" {
            return false
        }
#endif

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}

@MainActor
protocol PassiveLocationCoordinating: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestAlwaysAuthorization() async -> CLAuthorizationStatus
    func requestCurrentLocation() async -> CLLocationCoordinate2D?
}

@MainActor
final class SystemPassiveLocationCoordinator: NSObject, PassiveLocationCoordinating {
    private let manager = CLLocationManager()
    private let launchArguments = ProcessInfo.processInfo.arguments
    private let launchEnvironment = ProcessInfo.processInfo.environment

    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationStatus: CLAuthorizationStatus {
#if DEBUG
        if launchEnvironment["UITEST_FORCE_PASSIVE_READY"] == "1" ||
            launchArguments.contains("UITEST_FORCE_LOCATION_AUTHORIZED") {
            return .authorizedAlways
        }
        if launchArguments.contains("UITEST_FORCE_LOCATION_DENIED") ||
            launchEnvironment["UITEST_FORCE_LOCATION_DENIED"] == "1" {
            return .denied
        }
#endif
        return manager.authorizationStatus
    }

    func requestAlwaysAuthorization() async -> CLAuthorizationStatus {
        switch authorizationStatus {
        case .authorizedAlways, .denied, .restricted:
            return authorizationStatus
        case .authorizedWhenInUse, .notDetermined:
            manager.requestAlwaysAuthorization()
            return await withCheckedContinuation { continuation in
                authorizationContinuation?.resume(returning: authorizationStatus)
                authorizationContinuation = continuation
            }
        @unknown default:
            return .denied
        }
    }

    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
#if DEBUG
        if launchEnvironment["UITEST_FORCE_PASSIVE_READY"] == "1" ||
            launchArguments.contains("UITEST_FORCE_LOCATION_AUTHORIZED") {
            return CLLocationCoordinate2D(latitude: 40.7144, longitude: -73.9989)
        }
#endif

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        default:
            return nil
        }

        if let coordinate = manager.location?.coordinate {
            return coordinate
        }

        return await withTaskGroup(of: CLLocationCoordinate2D?.self) { group in
            group.addTask { @MainActor [weak self] in
                guard let self else { return nil }
                return await withCheckedContinuation { continuation in
                    self.locationContinuation?.resume(returning: nil)
                    self.locationContinuation = continuation
                    self.manager.requestLocation()
                }
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                return nil
            }

            let coordinate = await group.next() ?? nil
            group.cancelAll()
            return coordinate
        }
    }
}

extension SystemPassiveLocationCoordinator: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationContinuation?.resume(returning: status)
            authorizationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor in
            locationContinuation?.resume(returning: coordinate)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let _ = error
        Task { @MainActor in
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }
}

@MainActor
final class PassiveExperienceCoordinator: NSObject, ObservableObject {
    private enum Keys {
        static let passiveEnabled = "passive.reminders.enabled"
    }

    @Published private(set) var isPassiveEnabled: Bool
    @Published private(set) var monitoredMemoryIDs: [UUID] = []
    @Published private(set) var pendingNavigationRequest: PassiveNavigationRequest?

    private let geofenceMonitor: any GeofenceMonitorProtocol
    private let notificationOrchestrator: any NotificationOrchestratorProtocol
    private let backgroundRefreshStatusProvider: any BackgroundRefreshStatusProviding
    private let notificationAuthorizer: any PassiveNotificationAuthorizing
    private let locationCoordinator: any PassiveLocationCoordinating
    private let memoryLookup: (UUID) -> MemoryPoint?
    private let allMemories: () -> [MemoryPoint]
    private let preferredLanguage: () -> AppLanguage
    private let defaults: UserDefaults
    private let launchEnvironment = ProcessInfo.processInfo.environment

    private var eventTask: Task<Void, Never>?

    private var isUITestPassiveReadyOverrideEnabled: Bool {
#if DEBUG
        launchEnvironment["UITEST_FORCE_PASSIVE_READY"] == "1"
#else
        false
#endif
    }

    init(
        geofenceMonitor: any GeofenceMonitorProtocol = DefaultGeofenceMonitor(),
        notificationOrchestrator: any NotificationOrchestratorProtocol = DefaultNotificationOrchestrator(),
        backgroundRefreshStatusProvider: any BackgroundRefreshStatusProviding = SystemBackgroundRefreshStatusProvider(),
        notificationAuthorizer: any PassiveNotificationAuthorizing = SystemPassiveNotificationAuthorizer(),
        locationCoordinator: (any PassiveLocationCoordinating)? = nil,
        memoryLookup: @escaping (UUID) -> MemoryPoint?,
        allMemories: @escaping () -> [MemoryPoint],
        preferredLanguage: @escaping () -> AppLanguage,
        defaults: UserDefaults = .standard
    ) {
        self.geofenceMonitor = geofenceMonitor
        self.notificationOrchestrator = notificationOrchestrator
        self.backgroundRefreshStatusProvider = backgroundRefreshStatusProvider
        self.notificationAuthorizer = notificationAuthorizer
        self.locationCoordinator = locationCoordinator ?? SystemPassiveLocationCoordinator()
        self.memoryLookup = memoryLookup
        self.allMemories = allMemories
        self.preferredLanguage = preferredLanguage
        self.defaults = defaults
        self.isPassiveEnabled = defaults.bool(forKey: Keys.passiveEnabled)
        super.init()

#if DEBUG
        if launchEnvironment["UITEST_PRESET_PASSIVE_ENABLED"] == "1" {
            isPassiveEnabled = true
            monitoredMemoryIDs = Array(allMemories().prefix(20).map(\.id))
            defaults.set(true, forKey: Keys.passiveEnabled)
        }
#endif

        UNUserNotificationCenter.current().delegate = self
        seedUITestNotificationTapIfNeeded()

        if isPassiveEnabled {
            ensureEventStreamStarted()
        }
    }

    func setPassiveEnabled(_ isEnabled: Bool) async -> Result<Void, PassiveReminderError> {
        if isEnabled == isPassiveEnabled {
            return .success(())
        }

        if isEnabled == false {
            disablePassiveMode()
            return .success(())
        }

        guard backgroundRefreshStatusProvider.currentStatus() == .available else {
            disablePassiveMode()
            return .failure(.backgroundRefreshUnavailable)
        }

        guard await notificationAuthorizer.ensureAuthorization() else {
            disablePassiveMode()
            return .failure(.notificationPermissionDenied)
        }

        let authorizationStatus = await locationCoordinator.requestAlwaysAuthorization()
        guard authorizationStatus == .authorizedAlways else {
            disablePassiveMode()
            return .failure(.locationPermissionDenied)
        }

        guard let currentLocation = await locationCoordinator.requestCurrentLocation() else {
            disablePassiveMode()
            return .failure(.currentLocationUnavailable)
        }

        if isUITestPassiveReadyOverrideEnabled {
            monitoredMemoryIDs = Array(allMemories().prefix(20).map(\.id))
            isPassiveEnabled = true
            defaults.set(true, forKey: Keys.passiveEnabled)
            ensureEventStreamStarted()
            return .success(())
        }

        do {
            monitoredMemoryIDs = try await geofenceMonitor.refreshMonitors(
                currentLocation: currentLocation,
                candidates: allMemories(),
                maxConditions: 20,
                now: Date()
            )
            isPassiveEnabled = true
            defaults.set(true, forKey: Keys.passiveEnabled)
            ensureEventStreamStarted()
            return .success(())
        } catch {
            disablePassiveMode()
            return .failure(mapGeofenceError(error))
        }
    }

    func refreshMonitors(using currentLocation: CLLocationCoordinate2D) async {
        guard isPassiveEnabled else { return }

        if isUITestPassiveReadyOverrideEnabled {
            monitoredMemoryIDs = Array(allMemories().prefix(20).map(\.id))
            return
        }

        do {
            monitoredMemoryIDs = try await geofenceMonitor.refreshMonitors(
                currentLocation: currentLocation,
                candidates: allMemories(),
                maxConditions: 20,
                now: Date()
            )
        } catch {
            if mapGeofenceError(error) == .locationPermissionDenied {
                disablePassiveMode()
            }
        }
    }

    func consumePendingNavigationRequest() {
        pendingNavigationRequest = nil
    }

    private func disablePassiveMode() {
        eventTask?.cancel()
        eventTask = nil
        geofenceMonitor.stop()
        monitoredMemoryIDs = []
        isPassiveEnabled = false
        defaults.set(false, forKey: Keys.passiveEnabled)
    }

    private func ensureEventStreamStarted() {
        guard eventTask == nil else { return }

        eventTask = Task { [weak self] in
            guard let self else { return }
            let stream = self.geofenceMonitor.startEventStream()
            for await event in stream {
                guard Task.isCancelled == false else { return }
                await self.handleGeofenceEvent(event)
            }
        }
    }

    private func handleGeofenceEvent(_ event: GeofenceEvent) async {
        guard isPassiveEnabled, event.kind == .enter, let memoryPoint = memoryLookup(event.memoryId) else {
            return
        }

        let language = preferredLanguage()
        _ = try? await notificationOrchestrator.scheduleNearbyReminder(
            memoryId: memoryPoint.id,
            title: memoryPoint.title(in: language),
            body: memoryPoint.summary(in: language),
            now: event.occurredAt,
            cooldownHours: 24
        )
    }

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let memoryId = notificationOrchestrator.extractMemoryId(from: userInfo) else { return }
        pendingNavigationRequest = PassiveNavigationRequest(memoryId: memoryId, source: .passive)
    }

    private func seedUITestNotificationTapIfNeeded() {
#if DEBUG
        guard let rawMemoryID = launchEnvironment["UITEST_TRIGGER_PASSIVE_NOTIFICATION_MEMORY_ID"],
              let memoryID = UUID(uuidString: rawMemoryID)
        else {
            return
        }

        pendingNavigationRequest = PassiveNavigationRequest(memoryId: memoryID, source: .passive)
#endif
    }

    private func mapGeofenceError(_ error: Error) -> PassiveReminderError {
        guard let geofenceError = error as? GeofenceMonitorError else {
            return .geofenceRegistrationFailed
        }

        switch geofenceError {
        case .permissionDenied:
            return .locationPermissionDenied
        case .maxConditionsExceeded, .systemFailure, .notImplemented:
            return .geofenceRegistrationFailed
        }
    }
}

extension PassiveExperienceCoordinator: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let _ = center
        let _ = notification
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let _ = center
        Task { @MainActor in
            self.handleNotificationTap(userInfo: response.notification.request.content.userInfo)
            completionHandler()
        }
    }
}
