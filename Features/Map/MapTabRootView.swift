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
    @Published var routeStatus: RouteStatus = .idle
    @Published var retrievalPoint: PointOfInterest?
    @Published var previewDetailPoint: PointOfInterest?
    @Published var isNavigationDetailPresented = false
    @Published var searchText = ""
    @Published var isSearchPresented = false
    @Published private(set) var recentPointIDs: [UUID] = []
    @Published private(set) var recentSearchQueries: [String] = []
    private var pendingRetrievalPointFromPreviewDetail: PointOfInterest?

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
        previewPoint = nil
        previewDetailPoint = point
    }

    func endNavigation() {
        navigationPoint = nil
        activeRoute = nil
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

    func openRetrievalFromPreviewDetail() {
        guard let point = previewDetailPoint else { return }
        pendingRetrievalPointFromPreviewDetail = point
        previewDetailPoint = nil
    }

    func presentPendingRetrievalIfNeeded() {
        guard let point = pendingRetrievalPointFromPreviewDetail else { return }
        pendingRetrievalPointFromPreviewDetail = nil
        retrievalPoint = point
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
    @State private var previewSheetDetent: PresentationDetent = .height(280)
    @State private var previewSheetContentHeight: CGFloat = 280
    @FocusState private var isSearchFieldFocused: Bool
    @Namespace private var searchTransitionNamespace

    private let points = PointOfInterest.samples

    private var strings: AppStrings { AppStrings(language: languageStore.language) }
    private var launchArguments: [String] { ProcessInfo.processInfo.arguments }
    private var forceRouteFailureForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_ROUTE_FAILURE")
    }
    private var forceReduceMotionForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_REDUCE_MOTION")
    }
    private var forceStaticMapSnapshotForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_STATIC_MAP_SNAPSHOT")
    }
    private var forceSearchNoResultsOnSubmitForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_SEARCH_NO_RESULTS_ON_SUBMIT")
    }
    private var forcePreviewPointForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_PREVIEW_POINT")
    }
    private var forcePreviewExpandedForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_PREVIEW_EXPANDED")
    }
    private var previewSheetCompactDetent: PresentationDetent {
        .height(previewSheetContentHeight)
    }
    private var previewSheetDetents: Set<PresentationDetent> {
        [previewSheetCompactDetent, .large]
    }
    private var searchFocusDelayNanoseconds: UInt64 {
        let shouldReduceMotion = reduceMotion || forceReduceMotionForUITests
        let delay = (shouldReduceMotion ? DSMotion.durationFast : DSMotion.durationNormal) + 0.05
        return UInt64(delay * 1_000_000_000)
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
                .toolbar(.hidden, for: .navigationBar)
                .sheet(item: $state.previewPoint) { point in
                    MapPreviewSheetView(
                        point: point,
                        language: languageStore.language,
                        isChangingDestination: state.navigationPoint != nil,
                        isCompact: !forcePreviewExpandedForUITests && previewSheetDetent == previewSheetCompactDetent,
                        primaryActionTitle: state.navigationPoint == nil ? strings.goText : strings.changeDestination,
                        changeDestinationHint: strings.changeDestinationHint,
                        detailsTitle: strings.detailsText,
                        closeTitle: strings.closeText,
                        onPrimaryAction: {
                            handleNavigationAction()
                        },
                        onDetails: {
                            state.showDetails()
                        },
                        onClose: {
                            withAnimation(shellAnimation) {
                                state.dismissPreview()
                            }
                        }
                    )
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: SheetContentHeightKey.self, value: proxy.size.height)
                        }
                    )
                    .onPreferenceChange(SheetContentHeightKey.self) { newHeight in
                        if newHeight > 0 {
                            previewSheetContentHeight = newHeight
                        }
                    }
                    .presentationDetents(previewSheetDetents, selection: $previewSheetDetent)
                    .presentationBackgroundInteraction(.enabled(upThrough: previewSheetCompactDetent))
                    .presentationContentInteraction(.scrolls)
                    .presentationCornerRadius(DSRadius.r16 + DSSpacing.space8)
                    .presentationDragIndicator(.visible)
                }
                .sheet(item: $state.previewDetailPoint, onDismiss: {
                    state.presentPendingRetrievalIfNeeded()
                }) { point in
                    MapPreviewDetailSheet(
                        point: point,
                        language: languageStore.language,
                        onOpenRetrieval: {
                            state.openRetrievalFromPreviewDetail()
                        }
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $state.isNavigationDetailPresented) {
                    NavigationDetailSheet(
                        point: state.navigationPoint,
                        route: state.activeRoute,
                        routeStatus: state.routeStatus,
                        language: languageStore.language,
                        onRetry: { retryRoute() },
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

    private var mapContainer: some View {
        mapCanvas
    }

    private var mapCanvas: some View {
        ZStack(alignment: .top) {
            mapBackgroundLayer
        }
        .contentShape(Rectangle())
        .gesture(mapPreviewDismissGesture, including: .gesture)
        .accessibilityIdentifier("map_interaction_surface")
        .safeAreaInset(edge: .top) {
            if let navPoint = state.navigationPoint {
                VStack(spacing: DSSpacing.space8) {
                    NavigationPillView(
                        point: navPoint,
                        language: languageStore.language,
                        onOpenDetail: { state.openNavigationDetail() }
                    )

                    if shouldShowQuickRouteRetry {
                        routeQuickRetryBanner
                    }
                }
                .padding(.horizontal, DSSpacing.space12)
                .padding(.top, DSSpacing.space4)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: DSSpacing.space8) {
                if state.isMapDefaultState {
                    searchControls
                }

                Button {
                    handleLocateMeAction()
                } label: {
                    Image(systemName: "location.fill")
                        .font(DSTypography.iconMedium.weight(.semibold))
                        .frame(width: DSControl.minTouchTarget, height: DSControl.minTouchTarget)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("map_locate_me")
                .accessibilityLabel(strings.locateMe)
            }
            .padding(.trailing, DSSpacing.space12)
            .padding(.top, floatingControlsTopInset)
        }
        .onChange(of: state.searchText) { _, newValue in
            searchModel.updateQuery(newValue)
        }
        .onChange(of: state.isSearchPresented) { _, isPresented in
            if isPresented == false {
                isSearchFieldFocused = false
            }
        }
        .onChange(of: state.isMapDefaultState) { _, isMapDefaultState in
            if isMapDefaultState == false {
                withAnimation(shellAnimation) {
                    state.isSearchPresented = false
                }
                isSearchFieldFocused = false
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
        .onChange(of: state.previewPoint?.id) { _, pointID in
            guard pointID != nil else { return }
            previewSheetDetent = previewSheetCompactDetent
        }
    }

    private var mapPreviewDismissGesture: some Gesture {
        TapGesture().onEnded {
            handleMapBackgroundTap()
        }
    }

    @ViewBuilder
    private var mapBackgroundLayer: some View {
        if forceStaticMapSnapshotForUITests {
            DSColor.surfaceSecondary
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: DSSpacing.space4) {
                        Text(strings.mapTitle)
                            .dsTextStyle(.headline, weight: .semibold)
                        Text(strings.searchInputHint)
                            .dsTextStyle(.caption)
                    }
                    .foregroundStyle(DSColor.textSecondary)
                    .padding(.top, DSControl.navigationBannerHeight + DSSpacing.space16)
                    .padding(.leading, DSSpacing.space12)
                }
        } else {
            Map(position: $state.cameraPosition) {
                if let route = state.activeRoute {
                    MapPolyline(route.polyline)
                        .stroke(
                            DSColor.accentPrimary,
                            style: StrokeStyle(lineWidth: DSBorder.routeLine, lineCap: .round, lineJoin: .round)
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
                                .font(DSTypography.iconLarge.weight(.semibold))
                                .foregroundStyle(state.previewPoint?.id == point.id ? DSColor.statusError : DSColor.accentPrimary)
                                .padding(DSSpacing.space4)
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
                            .font(DSTypography.iconLarge.weight(.semibold))
                            .foregroundStyle(DSColor.accentPrimary)
                            .padding(DSSpacing.space4)
                            .background(.thinMaterial, in: Circle())
                            .accessibilityLabel(searchedPlace.annotationTitle)
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
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

    private var searchPanelWidth: CGFloat {
        min(DSControl.searchPanelMaxWidth, UIScreen.main.bounds.width - DSSpacing.space24)
    }

    private var floatingControlsTopInset: CGFloat {
        if state.navigationPoint == nil {
            return DSSpacing.space8
        }
        return DSSpacing.space8 + DSControl.floatingActionTopInsetWithBanner
    }

    private var shouldShowQuickRouteRetry: Bool {
        guard state.navigationPoint != nil else { return false }
        switch state.routeStatus {
        case .failed, .unavailable:
            return true
        case .idle, .loading, .ready:
            return false
        }
    }

    private var quickRouteRetryMessage: String {
        switch state.routeStatus {
        case .unavailable:
            return strings.routeUnavailable
        case .failed:
            return strings.routeFailedRetry
        case .idle, .loading, .ready:
            return ""
        }
    }

    private var routeQuickRetryBanner: some View {
        Button {
            retryRoute()
        } label: {
            HStack(spacing: DSSpacing.space8) {
                Text(quickRouteRetryMessage)
                    .dsTextStyle(.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(strings.retryText)
                    .dsTextStyle(.caption, weight: .semibold)
                    .foregroundStyle(DSColor.textPrimary)
                    .padding(.horizontal, DSSpacing.space8)
                    .padding(.vertical, DSSpacing.space4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.leading, DSSpacing.space12)
            .padding(.trailing, DSSpacing.space8)
            .frame(minHeight: DSControl.minTouchTarget)
            .background(.thinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map_route_retry_quick")
    }

    @ViewBuilder
    private var searchControls: some View {
        if state.isSearchPresented {
            VStack(alignment: .trailing, spacing: DSSpacing.space8) {
                searchBar

                SearchOverlayCard(
                    language: languageStore.language,
                    completions: searchModel.completions,
                    recommendations: filteredRecommendedPoints,
                    recents: state.recents(from: points),
                    completionText: { completion in
                        searchCompletionText(for: completion)
                    },
                    onSelectCompletion: handleSearchCompletionSelection,
                    onSelect: handleSearchSelection
                )
                .frame(width: searchPanelWidth, alignment: .trailing)
                .accessibilityIdentifier("map_search_card")
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            .transition(.opacity)
        } else {
            searchTriggerButton
                .transition(.scale(scale: 0.92, anchor: .trailing).combined(with: .opacity))
        }
    }

    private var searchTriggerButton: some View {
        Button {
            openSearchInterface()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(DSTypography.iconMedium.weight(.semibold))
                .foregroundStyle(DSColor.textPrimary)
                .matchedGeometryEffect(id: "map_search_icon", in: searchTransitionNamespace)
                .frame(width: DSControl.minTouchTarget, height: DSControl.minTouchTarget)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .matchedGeometryEffect(id: "map_search_surface", in: searchTransitionNamespace)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map_open_search")
        .accessibilityLabel(strings.searchPrompt)
    }

    private var searchBar: some View {
        HStack(spacing: DSSpacing.space8) {
            Image(systemName: "magnifyingglass")
                .font(DSTypography.iconMedium.weight(.semibold))
                .foregroundStyle(DSColor.textSecondary)
                .matchedGeometryEffect(id: "map_search_icon", in: searchTransitionNamespace)
                .accessibilityHidden(true)

            TextField(strings.searchPrompt, text: $state.searchText)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                .accessibilityLabel(strings.searchPrompt)
                .onSubmit {
                    Task {
                        await handleSearchSubmit()
                    }
                }
                .accessibilityIdentifier("map_search_field")

            if state.searchText.isEmpty == false {
                Button {
                    state.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .dsTextStyle(.body)
                        .foregroundStyle(DSColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.clearText)
            }

            Button {
                closeSearchInterface()
            } label: {
                Image(systemName: "xmark")
                    .dsTextStyle(.body, weight: .semibold)
                    .foregroundStyle(DSColor.textSecondary)
                    .frame(width: DSControl.minTouchTarget, height: DSControl.minTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("map_close_search")
            .accessibilityLabel(strings.closeText)
        }
        .padding(.leading, DSSpacing.space12)
        .padding(.trailing, DSSpacing.space4)
        .frame(width: searchPanelWidth, height: DSControl.minTouchTarget, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous)
                .fill(.ultraThinMaterial)
                .matchedGeometryEffect(id: "map_search_surface", in: searchTransitionNamespace)
        }
        .shadow(color: DSColor.borderSubtle.opacity(DSOpacity.overlayShadow), radius: DSRadius.r8, y: DSSpacing.space4)
        .accessibilityIdentifier("map_search_bar")
    }

    private func handleSearchSelection(_ point: PointOfInterest) {
        state.searchText = point.title(in: languageStore.language)
        withAnimation(shellAnimation) {
            state.selectPoint(point)
        }
    }

    private func handleSearchCompletionSelection(_ completion: MKLocalSearchCompletion) {
        state.searchText = searchCompletionText(for: completion)
        Task {
            await handleSearchSubmit()
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

    private func openSearchInterface() {
        guard state.isMapDefaultState else { return }
        withAnimation(shellAnimation) {
            state.isSearchPresented = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: searchFocusDelayNanoseconds)
            guard state.isSearchPresented else { return }
            isSearchFieldFocused = true
        }
    }

    private func closeSearchInterface() {
        isSearchFieldFocused = false
        withAnimation(shellAnimation) {
            state.isSearchPresented = false
        }
    }

    private func handleMapBackgroundTap() {
        guard state.previewPoint != nil else { return }
        withAnimation(shellAnimation) {
            state.dismissPreview()
        }
    }

    private func handleSearchSubmit() async {
        let keyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return }

        if forceSearchNoResultsOnSubmitForUITests {
            activeAlert = .searchNoResults(query: keyword)
            return
        }

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

    private var shellAnimation: Animation {
        DSMotion.routeTransition(reduceMotion: reduceMotion || forceReduceMotionForUITests)
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
            state.routeStatus = .idle
            return
        }

        state.routeStatus = .loading
        let sourceCoordinate = locationProvider.coordinate ?? state.routeSourceFallback
        let cacheKey = RouteCacheKey(destinationID: destination.id, source: sourceCoordinate)
        let now = Date()

        if forceRouteFailureForUITests {
            // Keep loading visible briefly so UI tests can validate retry-chain transitions.
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            state.activeRoute = nil
            state.routeStatus = .failed
            return
        }

        if let cached = routeCache[cacheKey], now.timeIntervalSince(cached.createdAt) <= 120 {
            state.activeRoute = cached.route
            state.routeStatus = .ready
            return
        }

        if lastRouteAttemptKey == cacheKey, now.timeIntervalSince(lastRouteAttemptAt) < 3 {
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

    private func retryRoute() {
        guard state.navigationPoint != nil else { return }
        state.activeRoute = nil
        state.routeStatus = .loading
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
            return
        }

        if forcePreviewPointForUITests,
           let point = points.first {
            state.selectPoint(point)
        }
    }
}

private struct MapPreviewSheetView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let point: PointOfInterest
    let language: AppLanguage
    let isChangingDestination: Bool
    let isCompact: Bool
    let primaryActionTitle: String
    let changeDestinationHint: String
    let detailsTitle: String
    let closeTitle: String
    let onPrimaryAction: () -> Void
    let onDetails: () -> Void
    let onClose: () -> Void

    private var summaryLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 4 : 2
    }

    private var usesVerticalActions: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.space16) {
                VStack(alignment: .leading, spacing: DSSpacing.space12) {
                    Text(point.title(in: language))
                        .dsTextStyle(.title, weight: .semibold)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)

                    HStack(spacing: DSSpacing.space8) {
                        PreviewMetadataChip(systemName: "calendar", text: String(point.year))
                        PreviewMetadataChip(systemName: "location.fill", text: point.distanceText(in: language))
                    }
                }

                Text(point.summary(in: language))
                    .dsTextStyle(.body)
                    .foregroundStyle(DSColor.textPrimary)
                    .lineLimit(summaryLineLimit)

                Divider()

                actionSection

                if isChangingDestination {
                    Text(changeDestinationHint)
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }
            }
            .padding(.horizontal, DSSpacing.space24)
            .padding(.top, DSSpacing.space16)
            .padding(.bottom, DSSpacing.space24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: DSSpacing.space12) {
            primaryActionButton
            if !isCompact {
                if usesVerticalActions {
                    VStack(spacing: DSSpacing.space8) {
                        secondaryActionButton
                        closeActionButton
                    }
                } else {
                    HStack(spacing: DSSpacing.space12) {
                        secondaryActionButton
                        closeActionButton
                    }
                }
            }
        }
    }

    private var primaryActionButton: some View {
        Button(primaryActionTitle) {
            onPrimaryAction()
        }
        .dsPrimaryCTAStyle()
        .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityIdentifier("map_preview_primary_action")
    }

    private var secondaryActionButton: some View {
        Button {
            onDetails()
        } label: {
            Text(detailsTitle)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map_preview_secondary_details")
    }

    private var closeActionButton: some View {
        Button {
            onClose()
        } label: {
            Text(closeTitle)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("map_preview_close_action")
    }
}

private struct PreviewMetadataChip: View {
    let systemName: String
    let text: String

    var body: some View {
        HStack(spacing: DSSpacing.space4) {
            Image(systemName: systemName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DSColor.textSecondary)
                .accessibilityHidden(true)

            Text(text)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, DSSpacing.space8)
        .padding(.vertical, DSSpacing.space4)
        .background(
            Capsule(style: .continuous)
                .fill(DSColor.surfaceSecondary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(DSColor.borderSubtle.opacity(DSOpacity.subtleBorder), lineWidth: DSBorder.bw1)
        )
    }
}

private struct NavigationPillView: View {
    let point: PointOfInterest
    let language: AppLanguage
    let onOpenDetail: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        Button {
            onOpenDetail()
        } label: {
            HStack(spacing: DSSpacing.space8) {
                Image(systemName: "location.north.line.fill")
                    .foregroundStyle(DSColor.textPrimary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DSSpacing.space4) {
                    Text(strings.navigationActive)
                        .dsTextStyle(.caption, weight: .semibold)
                        .foregroundStyle(DSColor.textSecondary)
                    Text(point.title(in: language))
                        .dsTextStyle(.body)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, DSSpacing.space12)
            .padding(.vertical, DSSpacing.space12)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(strings.navigationActive), \(point.title(in: language))")
        .accessibilityHint(strings.openNavigationDetailsHint)
        .accessibilityIdentifier("map_top_navigation_pill_container")
    }
}

private struct MapPreviewDetailSheet: View {
    let point: PointOfInterest
    let language: AppLanguage
    let onOpenRetrieval: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(point.title(in: language))
                        .dsTextStyle(.body, weight: .semibold)
                        .foregroundStyle(DSColor.textPrimary)
                    Text(point.summary(in: language))
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }

                Section {
                    Button(strings.archiveOpenRetrievalText) {
                        onOpenRetrieval()
                    }
                    .accessibilityIdentifier("map_preview_detail_open_retrieval")
                    .accessibilityHint(strings.archiveOpenRetrievalHint)
                }
            }
            .accessibilityIdentifier("map_preview_detail_sheet")
            .navigationTitle(strings.detailsText)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct NavigationDetailSheet: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isEndNavigationDialogPresented = false

    let point: PointOfInterest?
    let route: MKRoute?
    let routeStatus: MapScreenState.RouteStatus
    let language: AppLanguage
    let onRetry: () -> Void
    let onEnd: () -> Void

    private var strings: AppStrings { AppStrings(language: language) }
    private let missingRouteValuePlaceholder = "--"
    private var pointTitleLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 3 : 2
    }
    private var pointSummaryLineLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 3 : 2
    }

    var body: some View {
        NavigationStack {
            List {
                Section(strings.navigationActive) {
                    navigationTaskInfoSection
                }

                if let routeIssueMessage {
                    Section(strings.navigationTaskStatusLabel) {
                        Text(routeIssueMessage)
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)

                        Button(strings.retryText) {
                            onRetry()
                        }
                        .accessibilityIdentifier("map_route_retry")
                    }
                }

                if point != nil {
                    Section {
                        placeSummarySection
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

    private var navigationTaskInfoSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space12) {
            Text(strings.navigationTaskInfoTitle)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            NavigationTaskInfoRow(
                title: strings.navigationTaskETALabel,
                value: routeETAText,
                systemName: "clock",
                valueIdentifier: "map_navigation_task_eta_value"
            )
            .accessibilityIdentifier("map_navigation_task_eta_row")

            NavigationTaskInfoRow(
                title: strings.navigationTaskDistanceLabel,
                value: routeDistanceText,
                systemName: "ruler",
                valueIdentifier: "map_navigation_task_distance_value"
            )
            .accessibilityIdentifier("map_navigation_task_distance_row")

            NavigationTaskInfoRow(
                title: strings.navigationTaskStatusLabel,
                value: routeStatusText,
                systemName: "dot.radiowaves.left.and.right",
                valueIdentifier: "map_navigation_task_status_value"
            )
            .accessibilityIdentifier("map_navigation_task_status_row")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("map_navigation_task_info_section")
    }

    private var routeDistanceText: String {
        guard let route else { return missingRouteValuePlaceholder }
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .short
        measurementFormatter.unitOptions = .naturalScale
        measurementFormatter.locale = language.locale
        return measurementFormatter.string(
            from: Measurement(value: route.distance, unit: UnitLength.meters)
        )
    }

    private var routeETAText: String {
        guard let route else { return missingRouteValuePlaceholder }
        let etaFormatter = DateComponentsFormatter()
        etaFormatter.unitsStyle = .short
        etaFormatter.allowedUnits = route.expectedTravelTime >= 3600 ? [.hour, .minute] : [.minute]
        return etaFormatter.string(from: route.expectedTravelTime) ?? missingRouteValuePlaceholder
    }

    private var routeStatusText: String {
        switch routeStatus {
        case .idle:
            strings.navigationTaskStatusPending
        case .loading:
            strings.routeLoading
        case .ready:
            strings.navigationTaskStatusReady
        case .unavailable:
            strings.routeUnavailable
        case .failed:
            strings.routeFailedRetry
        }
    }

    private var routeIssueMessage: String? {
        switch routeStatus {
        case .failed:
            strings.routeFailedRetry
        case .unavailable:
            strings.routeUnavailable
        case .idle, .loading, .ready:
            nil
        }
    }

    @ViewBuilder
    private var placeSummarySection: some View {
        if let point {
            Text(point.title(in: language))
                .dsTextStyle(.body, weight: .semibold)
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(pointTitleLineLimit)
                .accessibilityIdentifier("map_navigation_detail_point_title")
            Text(point.summary(in: language))
                .dsTextStyle(.caption)
                .foregroundStyle(DSColor.textSecondary)
                .lineLimit(pointSummaryLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("map_navigation_detail_point_summary")
        }
    }
}

private struct NavigationTaskInfoRow: View {
    let title: String
    let value: String
    let systemName: String
    let valueIdentifier: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.space8) {
            Label {
                Text(title)
                    .dsTextStyle(.caption, weight: .semibold)
                    .foregroundStyle(DSColor.textSecondary)
            } icon: {
                Image(systemName: systemName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DSColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .accessibilityIdentifier(valueIdentifier)
        }
    }
}

private struct SearchOverlayCard: View {
    let language: AppLanguage
    let completions: [MKLocalSearchCompletion]
    let recommendations: [PointOfInterest]
    let recents: [PointOfInterest]
    let completionText: (MKLocalSearchCompletion) -> String
    let onSelectCompletion: (MKLocalSearchCompletion) -> Void
    let onSelect: (PointOfInterest) -> Void

    private var strings: AppStrings { AppStrings(language: language) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.space16) {
                if completions.isEmpty {
                    Text(strings.searchInputHint)
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)

                    if recommendations.isEmpty == false {
                        section(title: strings.searchRecommendations, items: recommendations)
                    }

                    recentsSection
                } else {
                    completionSection
                }
            }
            .padding(DSSpacing.space12)
        }
        .frame(maxWidth: .infinity, maxHeight: DSControl.overlayPanelMaxHeight, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous))
        .shadow(color: DSColor.borderSubtle.opacity(DSOpacity.overlayShadow), radius: DSRadius.r8, y: DSSpacing.space4)
    }

    @ViewBuilder
    private func section(title: String, items: [PointOfInterest]) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.space8) {
            Text(title)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            ForEach(items) { point in
                Button {
                    onSelect(point)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: DSSpacing.space4) {
                            Text(point.title(in: language))
                                .dsTextStyle(.body)
                                .foregroundStyle(DSColor.textPrimary)
                            Text("\(point.year) · \(point.distanceText(in: language))")
                                .dsTextStyle(.caption)
                                .foregroundStyle(DSColor.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, DSSpacing.space4)
                    .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(point.accessibilityLabel(in: language))
                .accessibilityHint(strings.detailsText)
            }
        }
    }

    private var completionSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space8) {
            Text(strings.searchPrompt)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            ForEach(Array(completions.enumerated()), id: \.offset) { _, completion in
                Button {
                    onSelectCompletion(completion)
                } label: {
                    HStack(alignment: .top, spacing: DSSpacing.space8) {
                        VStack(alignment: .leading, spacing: DSSpacing.space4) {
                            Text(completion.title)
                                .dsTextStyle(.body)
                                .foregroundStyle(DSColor.textPrimary)
                            if completion.subtitle.isEmpty == false {
                                Text(completion.subtitle)
                                    .dsTextStyle(.caption)
                                    .foregroundStyle(DSColor.textSecondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, DSSpacing.space4)
                    .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(completionText(completion))
            }
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.space8) {
            Text(strings.searchRecents)
                .dsTextStyle(.caption, weight: .semibold)
                .foregroundStyle(DSColor.textSecondary)

            if recents.isEmpty {
                Text(strings.searchNoRecents)
                    .dsTextStyle(.caption)
                    .foregroundStyle(DSColor.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
            } else {
                ForEach(recents) { point in
                    Button {
                        onSelect(point)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: DSSpacing.space4) {
                                Text(point.title(in: language))
                                    .dsTextStyle(.body)
                                    .foregroundStyle(DSColor.textPrimary)
                                Text("\(point.year) · \(point.distanceText(in: language))")
                                    .dsTextStyle(.caption)
                                    .foregroundStyle(DSColor.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "clock.arrow.circlepath")
                                .dsTextStyle(.caption)
                                .foregroundStyle(DSColor.textSecondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, DSSpacing.space4)
                        .frame(maxWidth: .infinity, minHeight: DSControl.minTouchTarget, alignment: .leading)
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

private struct SheetContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > value { value = next }
    }
}
