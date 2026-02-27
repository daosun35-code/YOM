import MapKit
import SwiftUI
import UIKit

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
    @Published var isRouteLoading = false
    @Published var routeStatus: RouteStatus = .idle
    @Published var retrievalPoint: PointOfInterest?
    @Published var isNavigationDetailPresented = false
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
        previewPoint = point
        isSearchPresented = false
        recordRecent(point)
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
        navigationPoint = point
        activeRoute = nil
        routeStatus = .loading
        previewPoint = nil
    }

    func showDetails() {
        guard let point = previewPoint else { return }
        retrievalPoint = point
        previewPoint = nil
    }

    func endNavigation() {
        navigationPoint = nil
        activeRoute = nil
        isRouteLoading = false
        routeStatus = .idle
        isNavigationDetailPresented = false
    }

    func openNavigationDetail() {
        guard navigationPoint != nil else { return }
        isNavigationDetailPresented = true
    }

    func closeRetrieval() {
        retrievalPoint = nil
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

    var routeSourceFallback: CLLocationCoordinate2D {
        defaultRegion.center
    }
}

struct MapTabRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @StateObject private var state = MapScreenState()
    @StateObject private var searchModel = MapSearchModel()
    @StateObject private var locationProvider = UserLocationProvider()
    @State private var routeCache: [RouteCacheKey: CachedRoute] = [:]
    @State private var lastRouteAttemptKey: RouteCacheKey?
    @State private var lastRouteAttemptAt = Date.distantPast
    @State private var routeRetryNonce = 0
    @State private var activeAlert: MapFeedbackAlert?
    @State private var hasAppliedUITestOverrides = false

    private let points = PointOfInterest.samples

    private var strings: AppStrings { AppStrings(language: languageStore.language) }
    private var launchArguments: [String] { ProcessInfo.processInfo.arguments }
    private var forceRouteFailureForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_ROUTE_FAILURE")
    }

    private enum MapFeedbackAlert: Identifiable {
        case searchNoResults(query: String)
        case locationPermissionDenied

        var id: String {
            switch self {
            case .searchNoResults(let query):
                return "search-no-results-\(query)"
            case .locationPermissionDenied:
                return "location-permission-denied"
            }
        }
    }

    var body: some View {
        NavigationStack(path: $shellState.mapPath) {
            mapContainer
                .navigationTitle(strings.mapTitle)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $state.previewPoint) { point in
                    MapPreviewSheetView(
                        point: point,
                        language: languageStore.language,
                        isChangingDestination: state.navigationPoint != nil,
                        primaryActionTitle: state.navigationPoint == nil ? strings.goText : strings.changeDestination,
                        changeDestinationHint: strings.changeDestinationHint,
                        detailsTitle: strings.detailsText,
                        onPrimaryAction: {
                            handleNavigationAction()
                        },
                        onDetails: {
                            state.showDetails()
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $state.isNavigationDetailPresented) {
                    NavigationDetailSheet(
                        point: state.navigationPoint,
                        language: languageStore.language,
                        onEnd: { state.endNavigation() }
                    )
                    .presentationDetents([.medium])
                }
                .fullScreenCover(item: $state.retrievalPoint) { point in
                    NavigationStack {
                        RetrievalView(point: point, showsCloseButton: true, onClose: {
                            state.closeRetrieval()
                        })
                    }
                    .environmentObject(languageStore)
                }
                .alert(item: $activeAlert) { alert in
                    switch alert {
                    case .searchNoResults(_):
                        return Alert(
                            title: Text(strings.searchNoResultsTitle),
                            message: Text(strings.searchNoResultsBody),
                            primaryButton: .default(Text(strings.retryText), action: {
                                retrySearch()
                            }),
                            secondaryButton: .cancel(Text(strings.notNowText))
                        )
                    case .locationPermissionDenied:
                        return Alert(
                            title: Text(strings.locationPermissionTitle),
                            message: Text(strings.locationPermissionBody),
                            primaryButton: .default(Text(strings.openSettingsText), action: {
                                openAppSettings()
                            }),
                            secondaryButton: .cancel(Text(strings.notNowText))
                        )
                    }
                }
        }
    }

    @ViewBuilder
    private var mapContainer: some View {
        if state.isMapDefaultState {
            mapCanvas
                .searchable(
                    text: $state.searchText,
                    isPresented: $state.isSearchPresented,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: Text(strings.searchPrompt)
                )
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .searchSuggestions {
                    if searchModel.completions.isEmpty {
                        Text(strings.searchInputHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if state.recentSearchQueries.isEmpty == false {
                            Text(strings.searchRecents)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ForEach(state.recentSearchQueries, id: \.self) { query in
                            Text(query)
                                .searchCompletion(query)
                        }

                        Text(strings.searchRecommendations)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(recommendedPoints) { point in
                            Text(point.title(in: languageStore.language))
                                .searchCompletion(point.title(in: languageStore.language))
                        }
                    } else {
                        ForEach(Array(searchModel.completions.enumerated()), id: \.offset) { _, completion in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                if completion.subtitle.isEmpty == false {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .searchCompletion(searchCompletionText(for: completion))
                        }
                    }
                }
                .onSubmit(of: .search) {
                    Task {
                        await handleSearchSubmit()
                    }
                }
        } else {
            mapCanvas
        }
    }

    private var mapCanvas: some View {
        ZStack(alignment: .top) {
            Map(position: $state.cameraPosition) {
                if let route = state.activeRoute {
                    MapPolyline(route.polyline)
                        .stroke(
                            .blue,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                }

                ForEach(points) { point in
                    Annotation(point.title(in: languageStore.language), coordinate: point.coordinate) {
                        Button {
                            withAnimation(shellAnimation) {
                                state.selectPoint(point)
                            }
                        } label: {
                            Image(systemName: state.previewPoint?.id == point.id ? "mappin.circle.fill" : "mappin.circle")
                                .font(.system(size: 28))
                                .foregroundStyle(state.previewPoint?.id == point.id ? Color.red : Color.accentColor)
                                .padding(4)
                                .background(.thinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("map_point_\(point.year)")
                        .accessibilityLabel(point.accessibilityLabel(in: languageStore.language))
                        .accessibilityAddTraits(.isButton)
                    }
                }

                if let searchedPlace = state.searchedPlace {
                    Annotation(searchedPlace.annotationTitle, coordinate: searchedPlace.coordinate) {
                        Image(systemName: "mappin.and.ellipse.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.tint)
                            .padding(4)
                            .background(.thinMaterial, in: Circle())
                            .accessibilityLabel(searchedPlace.annotationTitle)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)

            if state.navigationPoint != nil {
                routeOverlay
                    .padding(.top, 12)
            }

            if state.isMapDefaultState && state.isSearchPresented {
                SearchOverlayCard(
                    language: languageStore.language,
                    recommendations: filteredRecommendedPoints,
                    recents: state.recents(from: points),
                    onSelect: handleSearchSelection
                )
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .top) {
            if let navPoint = state.navigationPoint {
                NavigationPillView(
                    point: navPoint,
                    language: languageStore.language,
                    onOpenDetail: { state.openNavigationDetail() },
                    onEnd: { state.endNavigation() }
                )
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                handleLocateMeAction()
            } label: {
                if state.navigationPoint == nil {
                    ViewThatFits(in: .horizontal) {
                        Label(strings.locateMe, systemImage: "location.fill")
                            .font(.subheadline.weight(.semibold))
                            .labelStyle(.titleAndIcon)
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(.ultraThinMaterial, in: Capsule())

                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("map_locate_me")
            .padding(.trailing, 12)
            .padding(.top, state.navigationPoint == nil ? 12 : 68)
            .accessibilityLabel(strings.locateMe)
        }
        .onChange(of: state.searchText) { _, newValue in
            searchModel.updateQuery(newValue)
            if newValue.isEmpty == false && state.isSearchPresented == false {
                state.isSearchPresented = true
            }
        }
        .task(id: routeRefreshKey) {
            await refreshRouteIfNeeded()
        }
        .onAppear {
            syncLocationUpdates()
            applyUITestOverridesIfNeeded()
        }
        .onChange(of: languageStore.hasCompletedOnboarding) { _, _ in
            syncLocationUpdates()
            applyUITestOverridesIfNeeded()
        }
        .animation(shellAnimation, value: state.isSearchPresented)
    }

    private var recommendedPoints: [PointOfInterest] {
        points
    }

    private var filteredRecommendedPoints: [PointOfInterest] {
        let keyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return recommendedPoints }
        return recommendedPoints.filter { point in
            point.title(in: languageStore.language).localizedCaseInsensitiveContains(keyword)
        }
    }

    private func handleSearchSelection(_ point: PointOfInterest) {
        state.searchText = point.title(in: languageStore.language)
        withAnimation(shellAnimation) {
            state.selectPoint(point)
        }
    }

    private func handleNavigationAction() {
        switch locationProvider.requestAuthorizationForUserIntent() {
        case .authorized:
            withAnimation(shellAnimation) {
                state.startOrChangeNavigation()
            }
        case .notDetermined:
            break
        case .deniedOrRestricted:
            activeAlert = .locationPermissionDenied
        }
    }

    private func handleLocateMeAction() {
        switch locationProvider.requestAuthorizationForUserIntent() {
        case .authorized:
            guard let coordinate = locationProvider.coordinate else { return }
            withAnimation(shellAnimation) {
                state.cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
            }
        case .notDetermined:
            break
        case .deniedOrRestricted:
            activeAlert = .locationPermissionDenied
        }
    }

    private func syncLocationUpdates() {
        guard languageStore.hasCompletedOnboarding else { return }
        locationProvider.startIfAuthorized()
    }

    private func searchCompletionText(for completion: MKLocalSearchCompletion) -> String {
        completion.subtitle.isEmpty ? completion.title : "\(completion.title), \(completion.subtitle)"
    }

    private func handleSearchSubmit() async {
        let keyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return }

        if let place = await searchModel.search(
            query: keyword,
            fallbackTitle: strings.searchResultFallbackTitle
        ) {
            withAnimation(shellAnimation) {
                state.selectSearchPlace(place, query: keyword)
            }
        } else {
            activeAlert = .searchNoResults(query: keyword)
        }
    }

    private func retrySearch() {
        Task {
            await handleSearchSubmit()
        }
    }

    private var routeOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.thinMaterial)
            .frame(height: 72)
            .overlay {
                HStack(spacing: 12) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.title3)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.navigationActive)
                            .font(.subheadline.weight(.semibold))
                        if let point = state.navigationPoint {
                            Text(point.title(in: languageStore.language))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        if let route = state.activeRoute {
                            Text(routeMetricsText(for: route))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            routeStatusFeedback
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
            }
            .padding(.horizontal, 12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(strings.navigationActive)
    }

    private var shellAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.88)
    }

    private var routeRefreshKey: String {
        guard let navigationPoint = state.navigationPoint else {
            return "route:none:\(routeRetryNonce)"
        }
        return "route:\(navigationPoint.id.uuidString):\(locationProvider.coordinateKey):\(routeRetryNonce)"
    }

    private func refreshRouteIfNeeded() async {
        guard let destination = state.navigationPoint else {
            state.activeRoute = nil
            state.isRouteLoading = false
            state.routeStatus = .idle
            return
        }

        state.isRouteLoading = true
        state.routeStatus = .loading
        let sourceCoordinate = locationProvider.coordinate ?? state.routeSourceFallback
        let cacheKey = RouteCacheKey(destinationID: destination.id, source: sourceCoordinate)
        let now = Date()

        if forceRouteFailureForUITests {
            // Keep loading visible briefly so UI tests can validate retry-chain transitions.
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            state.activeRoute = nil
            state.routeStatus = .failed
            state.isRouteLoading = false
            return
        }

        if let cached = routeCache[cacheKey], now.timeIntervalSince(cached.createdAt) <= 120 {
            state.activeRoute = cached.route
            state.isRouteLoading = false
            state.routeStatus = .ready
            return
        }

        if lastRouteAttemptKey == cacheKey, now.timeIntervalSince(lastRouteAttemptAt) < 3 {
            state.isRouteLoading = false
            return
        }

        lastRouteAttemptKey = cacheKey
        lastRouteAttemptAt = now

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .walking

        do {
            let response = try await MKDirections(request: request).calculate()
            if let route = response.routes.first {
                state.activeRoute = route
                state.routeStatus = .ready
                routeCache[cacheKey] = CachedRoute(route: route, createdAt: now)
                if routeCache.count > 12 {
                    routeCache = Dictionary(
                        uniqueKeysWithValues: routeCache
                            .sorted { $0.value.createdAt > $1.value.createdAt }
                            .prefix(12)
                            .map { ($0.key, $0.value) }
                    )
                }
            } else {
                state.activeRoute = nil
                state.routeStatus = .unavailable
            }
        } catch {
            state.activeRoute = nil
            state.routeStatus = .failed
        }

        state.isRouteLoading = false
    }

    private func routeMetricsText(for route: MKRoute) -> String {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .short
        measurementFormatter.unitOptions = .naturalScale
        measurementFormatter.locale = languageStore.language.locale

        let distanceText = measurementFormatter.string(
            from: Measurement(value: route.distance, unit: UnitLength.meters)
        )

        let etaFormatter = DateComponentsFormatter()
        etaFormatter.unitsStyle = .short
        etaFormatter.allowedUnits = route.expectedTravelTime >= 3600 ? [.hour, .minute] : [.minute]

        let etaText = etaFormatter.string(from: route.expectedTravelTime) ?? ""
        guard etaText.isEmpty == false else { return distanceText }
        return "\(distanceText) · \(etaText)"
    }

    @ViewBuilder
    private var routeStatusFeedback: some View {
        switch state.routeStatus {
        case .loading:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text(strings.routeLoading)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        case .unavailable:
            routeIssueFeedbackText(strings.routeUnavailable)
        case .failed:
            routeIssueFeedbackText(strings.routeFailedRetry)
        case .idle, .ready:
            EmptyView()
        }
    }

    private func routeIssueFeedbackText(_ message: String) -> some View {
        HStack(spacing: 8) {
            Text(message)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Button(strings.retryText) {
                retryRoute()
            }
            .buttonStyle(.plain)
            .font(.caption2.weight(.semibold))
            .accessibilityIdentifier("map_route_retry")
        }
    }

    private func retryRoute() {
        lastRouteAttemptKey = nil
        lastRouteAttemptAt = .distantPast
        routeRetryNonce += 1
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }

    private func applyUITestOverridesIfNeeded() {
        guard languageStore.hasCompletedOnboarding, hasAppliedUITestOverrides == false else { return }
        hasAppliedUITestOverrides = true

        if launchArguments.contains("UITEST_SHOW_SEARCH_NO_RESULT_ALERT") {
            activeAlert = .searchNoResults(query: "forced")
        }

        if launchArguments.contains("UITEST_FORCE_NAVIGATION_ACTIVE"),
           let point = points.first {
            state.navigationPoint = point
            state.previewPoint = nil
            state.routeStatus = .ready
        }
    }
}

private struct MapPreviewSheetView: View {
    let point: PointOfInterest
    let language: AppLanguage
    let isChangingDestination: Bool
    let primaryActionTitle: String
    let changeDestinationHint: String
    let detailsTitle: String
    let onPrimaryAction: () -> Void
    let onDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(point.title(in: language))
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("\(point.year) · \(point.distanceText(in: language))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(point.summary(in: language))
                .font(.body)

            HStack(spacing: 12) {
                Button(primaryActionTitle) {
                    onPrimaryAction()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 44)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("map_preview_primary_action")

                Button(detailsTitle) {
                    onDetails()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 44)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }

            if isChangingDestination {
                Text(changeDestinationHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }
}

private struct NavigationPillView: View {
    @State private var isEndNavigationDialogPresented = false

    let point: PointOfInterest
    let language: AppLanguage
    let onOpenDetail: () -> Void
    let onEnd: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onOpenDetail()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.north.line.fill")
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(strings.navigationActive)
                            .font(.caption.weight(.semibold))
                        Text(point.title(in: language))
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(strings.navigationActive), \(point.title(in: language))")
            .accessibilityHint(strings.openNavigationDetailsHint)

            Button(strings.endNavigation) {
                isEndNavigationDialogPresented = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("map_end_navigation")
            .confirmationDialog(
                strings.endNavigationConfirmTitle,
                isPresented: $isEndNavigationDialogPresented,
                titleVisibility: .visible
            ) {
                Button(strings.endNavigationConfirmAction, role: .destructive) {
                    onEnd()
                }
                .accessibilityIdentifier("map_confirm_end_navigation")

                Button(strings.notNowText, role: .cancel) {}
            } message: {
                Text(strings.endNavigationConfirmBody)
            }
        }
    }
}

private struct NavigationDetailSheet: View {
    @State private var isEndNavigationDialogPresented = false

    let point: PointOfInterest?
    let language: AppLanguage
    let onEnd: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        NavigationStack {
            List {
                Section(strings.navigationActive) {
                    if let point {
                        Text(point.title(in: language))
                        Text(point.summary(in: language))
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        isEndNavigationDialogPresented = true
                    } label: {
                        Text(strings.endNavigation)
                    }
                    .accessibilityIdentifier("map_end_navigation_in_sheet")
                }
            }
            .navigationTitle(strings.navigationActive)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                strings.endNavigationConfirmTitle,
                isPresented: $isEndNavigationDialogPresented,
                titleVisibility: .visible
            ) {
                Button(strings.endNavigationConfirmAction, role: .destructive) {
                    onEnd()
                }
                .accessibilityIdentifier("map_confirm_end_navigation_in_sheet")

                Button(strings.notNowText, role: .cancel) {}
            } message: {
                Text(strings.endNavigationConfirmBody)
            }
        }
    }
}

private struct SearchOverlayCard: View {
    let language: AppLanguage
    let recommendations: [PointOfInterest]
    let recents: [PointOfInterest]
    let onSelect: (PointOfInterest) -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if recommendations.isEmpty == false {
                    section(title: strings.searchRecommendations, items: recommendations)
                }

                recentsSection
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: 280, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }

    @ViewBuilder
    private func section(title: String, items: [PointOfInterest]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(items) { point in
                Button {
                    onSelect(point)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.title(in: language))
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text("\(point.year) · \(point.distanceText(in: language))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(point.accessibilityLabel(in: language))
                .accessibilityHint(strings.detailsText)
            }
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(strings.searchRecents)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if recents.isEmpty {
                Text(strings.searchNoRecents)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            } else {
                ForEach(recents) { point in
                    Button {
                        onSelect(point)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(point.title(in: language))
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text("\(point.year) · \(point.distanceText(in: language))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(point.accessibilityLabel(in: language))
                }
            }
        }
    }
}

@MainActor
private final class MapSearchModel: NSObject, ObservableObject {
    @Published private(set) var completions: [MKLocalSearchCompletion] = []

    private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String) {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else {
            completions = []
            completer.queryFragment = ""
            return
        }

        completer.queryFragment = keyword
    }

    func search(query: String, fallbackTitle: String) async -> SearchPlace? {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return nil }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = keyword
        request.resultTypes = [.address, .pointOfInterest]

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else { return nil }
            return SearchPlace(mapItem: item, fallbackTitle: fallbackTitle)
        } catch {
            return nil
        }
    }
}

@MainActor
private final class UserLocationProvider: NSObject, ObservableObject {
    enum PermissionState {
        case authorized
        case notDetermined
        case deniedOrRestricted
    }

    @Published private(set) var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private let launchArguments = ProcessInfo.processInfo.arguments

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    var coordinateKey: String {
        guard let coordinate else { return "unknown" }
        return String(format: "%.3f,%.3f", coordinate.latitude, coordinate.longitude)
    }

    func startIfAuthorized() {
        guard permissionState == .authorized else {
            return
        }

        if launchArguments.contains("UITEST_FORCE_LOCATION_AUTHORIZED") {
            if coordinate == nil {
                coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            }
            return
        }

        manager.startUpdatingLocation()
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

private struct RouteCacheKey: Hashable {
    let destinationID: UUID
    let sourceLatitudeBucket: Int
    let sourceLongitudeBucket: Int

    init(destinationID: UUID, source: CLLocationCoordinate2D) {
        self.destinationID = destinationID
        self.sourceLatitudeBucket = Int((source.latitude * 1000).rounded())
        self.sourceLongitudeBucket = Int((source.longitude * 1000).rounded())
    }
}

private struct CachedRoute {
    let route: MKRoute
    let createdAt: Date
}

extension UserLocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.coordinate = latest.coordinate
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.coordinate = nil
        }
    }
}

extension MapSearchModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.completions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.completions = []
        }
    }
}

struct SearchPlace {
    let annotationTitle: String
    let coordinate: CLLocationCoordinate2D

    init?(mapItem: MKMapItem, fallbackTitle: String) {
        guard CLLocationCoordinate2DIsValid(mapItem.placemark.coordinate) else {
            return nil
        }

        let title = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let placemarkTitle = mapItem.placemark.title?
            .replacingOccurrences(of: "\n", with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let resolvedTitle: String
        if title.isEmpty == false {
            resolvedTitle = title
        } else if placemarkTitle.isEmpty == false {
            resolvedTitle = placemarkTitle
        } else {
            resolvedTitle = fallbackTitle
        }

        self.annotationTitle = resolvedTitle
        self.coordinate = mapItem.placemark.coordinate
    }
}
