import MapKit
import SwiftUI

@MainActor
final class MapScreenState: ObservableObject {
    private static let defaultCenter = CLLocationCoordinate2D(latitude: 40.7144, longitude: -73.9989)
    private static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
    private static let userFocusSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)

    enum RouteStatus {
        case idle
        case loading
        case ready
        case unavailable
        case failed
    }

    @Published var cameraPosition: MapCameraPosition
    @Published var previewPoint: PointOfInterest?
    @Published var searchedPlace: SearchPlace?
    @Published var navigationPoint: PointOfInterest?
    @Published var navigationSource: ExplorationSource = .active
    @Published var activeRoute: MKRoute?
    @Published var routeStatus: RouteStatus = .idle

    @Published var routeRetryNonce: Int = 0
    var routeCache: [RouteCacheKey: CachedRoute] = [:]
    var lastRouteAttemptKey: RouteCacheKey?
    var lastRouteAttemptAt = Date.distantPast

    @Published var searchText = ""
    @Published var isSearchPresented = false
    @Published private(set) var recentPointIDs: [UUID] = []
    @Published private(set) var recentSearchQueries: [String] = []

    private let defaultRegion = MKCoordinateRegion(
        center: MapScreenState.defaultCenter,
        span: MapScreenState.defaultSpan
    )

    init() {
        cameraPosition = .region(MKCoordinateRegion(center: Self.defaultCenter, span: Self.defaultSpan))
    }

    var isMapDefaultState: Bool {
        previewPoint == nil && navigationPoint == nil
    }

    func recenterDefault() {
        cameraPosition = .region(defaultRegion)
    }

    func centerOnUserLocation(_ coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: Self.userFocusSpan
            )
        )
    }

    func followUserLocation(followsHeading: Bool, fallbackCoordinate: CLLocationCoordinate2D?) {
        let fallbackPosition: MapCameraPosition
        if let fallbackCoordinate {
            fallbackPosition = .region(
                MKCoordinateRegion(
                    center: fallbackCoordinate,
                    span: Self.userFocusSpan
                )
            )
        } else {
            fallbackPosition = .region(defaultRegion)
        }

        cameraPosition = .userLocation(
            followsHeading: followsHeading,
            fallback: fallbackPosition
        )
    }

    func selectPoint(_ point: PointOfInterest) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: point.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        )
        searchedPlace = nil
        isSearchPresented = false
        recordRecent(point)
        let needsDismissFirst = previewPoint != nil && previewPoint?.id != point.id
        if needsDismissFirst {
            previewPoint = nil
            Task { @MainActor in self.previewPoint = point }
        } else {
            previewPoint = point
        }
    }

    func selectSearchPlace(_ place: SearchPlace, query: String) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
        previewPoint = nil
        searchedPlace = place
        isSearchPresented = false
        recordSearchQuery(query)
    }

    func dismissPreview() {
        previewPoint = nil
    }

    func startOrChangeNavigation() {
        guard let point = previewPoint else { return }
        if navigationPoint?.id == point.id {
            dismissPreview()
            return
        }
        navigationPoint = point
        navigationSource = .active
        activeRoute = nil
        routeStatus = .loading
        dismissPreview()
    }

    func startPassiveNavigation(to point: PointOfInterest) {
        navigationPoint = point
        navigationSource = .passive
        activeRoute = nil
        routeStatus = .loading
        previewPoint = nil
    }

    func endNavigation() {
        navigationPoint = nil
        navigationSource = .active
        activeRoute = nil
        routeStatus = .idle
    }

    func focusOnRoute(
        _ route: MKRoute,
        actualSource: CLLocationCoordinate2D?,
        destination: CLLocationCoordinate2D
    ) {
        var mapRect = route.polyline.boundingMapRect

        if let source = actualSource, CLLocationCoordinate2DIsValid(source) {
            mapRect = mapRect.union(Self.pointRect(for: source))
        }

        mapRect = mapRect.union(Self.pointRect(for: destination))
        cameraPosition = .rect(Self.paddedMapRect(for: mapRect, referenceCoordinate: actualSource ?? destination))
    }

    func recents(from points: [PointOfInterest]) -> [PointOfInterest] {
        recentPointIDs.compactMap { id in
            points.first(where: { $0.id == id })
        }
    }

    private func recordRecent(_ point: PointOfInterest) {
        recentPointIDs.removeAll { $0 == point.id }
        recentPointIDs.insert(point.id, at: 0)
        recentPointIDs = Array(recentPointIDs.prefix(5))
    }

    private func recordSearchQuery(_ query: String) {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return }
        recentSearchQueries.removeAll { $0.caseInsensitiveCompare(keyword) == .orderedSame }
        recentSearchQueries.insert(keyword, at: 0)
        recentSearchQueries = Array(recentSearchQueries.prefix(5))
    }

    private static func pointRect(for coordinate: CLLocationCoordinate2D) -> MKMapRect {
        let point = MKMapPoint(coordinate)
        return MKMapRect(x: point.x, y: point.y, width: 1, height: 1)
    }

    private static func paddedMapRect(for mapRect: MKMapRect, referenceCoordinate: CLLocationCoordinate2D) -> MKMapRect {
        guard mapRect.isNull == false else { return mapRect }

        let referenceLatitude = CLLocationCoordinate2DIsValid(referenceCoordinate) ? referenceCoordinate.latitude : defaultCenter.latitude
        let pointsPerMeter = MKMapPointsPerMeterAtLatitude(referenceLatitude)
        let minimumPadding = max(pointsPerMeter * 180, 1)
        let horizontalPadding = max(mapRect.size.width * 0.18, minimumPadding)
        let verticalPadding = max(mapRect.size.height * 0.18, minimumPadding)

        return mapRect.insetBy(dx: -horizontalPadding, dy: -verticalPadding)
    }
}

struct RouteCacheKey: Hashable {
    let destinationID: UUID
    let sourceLatitudeBucket: Int
    let sourceLongitudeBucket: Int

    init(destinationID: UUID, source: CLLocationCoordinate2D) {
        self.destinationID = destinationID
        self.sourceLatitudeBucket = Int((source.latitude * 10000).rounded())
        self.sourceLongitudeBucket = Int((source.longitude * 10000).rounded())
    }
}

struct CachedRoute {
    let route: MKRoute
    let sourceCoordinate: CLLocationCoordinate2D?
    let createdAt: Date
}
