import MapKit
import SwiftUI

@MainActor
final class MapScreenState: ObservableObject {
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
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    init() {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }

    var isMapDefaultState: Bool {
        previewPoint == nil && navigationPoint == nil
    }

    func recenterDefault() {
        cameraPosition = .region(defaultRegion)
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
        activeRoute = nil
        routeStatus = .loading
        dismissPreview()
    }

    func endNavigation() {
        navigationPoint = nil
        activeRoute = nil
        routeStatus = .idle
    }

    func recents(from points: [PointOfInterest]) -> [PointOfInterest] {
        recentPointIDs.compactMap { id in
            points.first(where: { $0.id == id })
        }
    }

    var routeSourceFallback: CLLocationCoordinate2D {
        defaultRegion.center
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
}

struct RouteCacheKey: Hashable {
    let destinationID: UUID
    let sourceLatitudeBucket: Int
    let sourceLongitudeBucket: Int

    init(destinationID: UUID, source: CLLocationCoordinate2D) {
        self.destinationID = destinationID
        self.sourceLatitudeBucket = Int((source.latitude * 1000).rounded())
        self.sourceLongitudeBucket = Int((source.longitude * 1000).rounded())
    }
}

struct CachedRoute {
    let route: MKRoute
    let createdAt: Date
}
