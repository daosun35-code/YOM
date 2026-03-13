import CoreLocation

@MainActor
final class UserLocationProvider: NSObject, ObservableObject {
    enum PermissionState {
        case authorized
        case notDetermined
        case deniedOrRestricted
    }

    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var headingDegrees: CLLocationDirection?

    private let manager = CLLocationManager()
    private let launchArguments = ProcessInfo.processInfo.arguments

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 5
    }

    var coordinateKey: String {
        guard let coordinate else { return "unknown" }
        return String(format: "%.4f,%.4f", coordinate.latitude, coordinate.longitude)
    }

    func startIfAuthorized() {
        guard permissionState == .authorized else {
            return
        }

        if launchArguments.contains("UITEST_FORCE_LOCATION_AUTHORIZED") {
            if coordinate == nil {
                coordinate = CLLocationCoordinate2D(latitude: 40.7144, longitude: -73.9989)
            }
            return
        }

        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    @discardableResult
    func requestAuthorizationForUserIntent() -> PermissionState {
        switch permissionState {
        case .authorized:
            startIfAuthorized()
            return .authorized
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return .notDetermined
        case .deniedOrRestricted:
            return .deniedOrRestricted
        }
    }

    private var permissionState: PermissionState {
        if launchArguments.contains("UITEST_FORCE_LOCATION_DENIED") {
            return .deniedOrRestricted
        }
        if launchArguments.contains("UITEST_FORCE_LOCATION_AUTHORIZED") {
            return .authorized
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .deniedOrRestricted
        @unknown default:
            return .deniedOrRestricted
        }
    }
}

extension UserLocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
                if CLLocationManager.headingAvailable() {
                    manager.startUpdatingHeading()
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.coordinate = latest.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let resolvedHeading = Self.resolvedHeading(from: newHeading)
        Task { @MainActor in
            self.headingDegrees = resolvedHeading
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _ = error
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        false
    }

    nonisolated private static func resolvedHeading(from heading: CLHeading) -> CLLocationDirection? {
        if heading.trueHeading >= 0 {
            return heading.trueHeading
        }

        if heading.magneticHeading >= 0 {
            return heading.magneticHeading
        }

        return nil
    }
}
