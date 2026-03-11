import MapKit
import SwiftUI
import UIKit

struct MapTabRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var memoryRepository: LocalMemoryRepository
    @EnvironmentObject private var archiveCoordinator: MemoryArchiveCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @StateObject private var state = MapScreenState()
    @StateObject private var searchModel = MapSearchModel()
    @StateObject private var locationProvider = UserLocationProvider()
    @State private var activeAlert: MapFeedbackAlert?
    @State private var hasAppliedUITestOverrides = false
    @State private var previewSheetDetent: PresentationDetent = .height(280)
    @State private var measuredPreviewContentHeight: CGFloat = 280
    @State private var isSearchFieldFirstResponder = false
    @State private var isSearchCardVisible = false
    @State private var searchCardVisibilityTask: Task<Void, Never>?
    @State private var mapContainerWidth: CGFloat = 0
    @State private var unlockEvaluator: UnlockEvaluator?
    @State private var unlockedMemoryPoint: MemoryPoint?

    private var points: [PointOfInterest] { memoryRepository.allPOIs }

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
    private var forceUnlockedMemoryDetailForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_UNLOCKED_MEMORY_DETAIL")
    }
    private var clampedPreviewContentHeight: CGFloat {
        min(
            max(measuredPreviewContentHeight, DSControl.previewSheetCompactMinHeight),
            DSControl.previewSheetCompactMaxHeight
        )
    }
    private var previewSheetCompactDetent: PresentationDetent {
        .height(clampedPreviewContentHeight)
    }
    private var previewSheetDetents: Set<PresentationDetent> {
        [previewSheetCompactDetent, .large]
    }

    private enum MapFeedbackAlert: Identifiable {
        case searchNoResults(query: String)
        case locationPermissionDenied
        case archiveActionFailed(message: String)

        var id: String {
            switch self {
            case .searchNoResults(let query):
                return "search-no-results-\(query)"
            case .locationPermissionDenied:
                return "location-permission-denied"
            case .archiveActionFailed(let message):
                return "archive-action-failed-\(message)"
            }
        }
    }

    var body: some View {
        NavigationStack {
            mapContainer
                .toolbar(.hidden, for: .navigationBar)
                .sheet(item: $state.previewPoint) { point in
                    MapPreviewSheetView(
                        point: point,
                        language: languageStore.language,
                        isCompact: !forcePreviewExpandedForUITests && previewSheetDetent != .large,
                        showsPrimaryAction: state.navigationPoint?.id != point.id,
                        primaryActionTitle: state.navigationPoint == nil ? strings.goText : strings.changeDestination,
                        detailsTitle: strings.detailsText,
                        closeTitle: strings.closeText,
                        retrievalModeText: strings.retrievalModeStatic,
                        demoNotesTitle: strings.demoNotesTitle,
                        demoNotesBody: strings.demoNotesBody,
                        onPrimaryAction: {
                            handleNavigationAction()
                        },
                        onDetails: {
                            if previewSheetDetent != .large {
                                updatePreviewSheetDetent(.large, animated: true)
                            }
                        },
                        onClose: {
                            state.dismissPreview()
                        },
                        onContentHeightMeasured: { height in
                            if abs(measuredPreviewContentHeight - height) > 1 {
                                let wasAtCompact = previewSheetDetent != .large
                                measuredPreviewContentHeight = height
                                if wasAtCompact {
                                    let clampedHeight = min(
                                        max(height, DSControl.previewSheetCompactMinHeight),
                                        DSControl.previewSheetCompactMaxHeight
                                    )
                                    updatePreviewSheetDetent(.height(clampedHeight), animated: false)
                                }
                            }
                        }
                    )
                    .id(point.id)
                    .presentationDetents(previewSheetDetents, selection: $previewSheetDetent)
                    .presentationBackgroundInteraction(.enabled(upThrough: previewSheetCompactDetent))
                    .presentationContentInteraction(.resizes)
                    .presentationCornerRadius(DSRadius.r16 + DSSpacing.space8)
                    .presentationDragIndicator(.visible)
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
                    case .archiveActionFailed(let message):
                        return Alert(
                            title: Text(strings.archiveActionErrorTitle),
                            message: Text(message),
                            dismissButton: .default(Text(strings.closeText))
                        )
                    }
                }
                .sheet(item: $unlockedMemoryPoint) { memoryPoint in
                    NavigationStack {
                        MemoryDetailView(memoryPoint: memoryPoint) {
                            handleExperienceComplete(for: memoryPoint)
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button(strings.closeText) {
                                    dismissUnlockedMemoryDetail()
                                }
                            }
                        }
                    }
                }
        }
    }

    private var mapContainer: some View {
        GeometryReader { proxy in
            mapCanvas
                .onAppear {
                    updateMapContainerWidth(proxy.size.width)
                }
                .onChange(of: proxy.size.width) { _, newWidth in
                    updateMapContainerWidth(newWidth)
                }
        }
    }

    private var mapCanvas: some View {
        ZStack(alignment: .top) {
            mapBackgroundLayer
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier("map_interaction_surface")
        // BUG-002-FIX: presentationBackgroundInteraction(.enabled) passes taps through the scrim
        // to the canvas; add explicit tap-to-dismiss so "tap outside" still closes the preview.
        // Child views (Map annotation Buttons) take gesture priority, so pin taps are unaffected.
        .onTapGesture {
            if state.previewPoint != nil {
                withAnimation(shellAnimation) {
                    state.dismissPreview()
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let navPoint = state.navigationPoint {
                VStack(spacing: DSSpacing.space8) {
                    NavigationPillView(
                        point: navPoint,
                        language: languageStore.language,
                        onEndTap: {
                            handleEndNavigationAction()
                        }
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
                if state.isMapDefaultState && !state.isSearchPresented {
                    searchTriggerButton
                        .transition(.scale(scale: 0.92, anchor: .trailing).combined(with: .opacity))
                }

                if !state.isSearchPresented {
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
                    .transition(.scale(scale: 0.92, anchor: .trailing).combined(with: .opacity))
                }
            }
            .animation(shellAnimation, value: state.isSearchPresented)
            .padding(.trailing, DSSpacing.space12)
            .padding(.top, floatingControlsTopInset)
        }
        .overlay(alignment: .top) {
            if state.isMapDefaultState && state.isSearchPresented {
                VStack(alignment: .trailing, spacing: DSSpacing.space8) {
                    searchBar

                    if isSearchCardVisible {
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
                }
                .frame(width: searchPanelWidth)
                .padding(.top, floatingControlsTopInset)
                .transition(.opacity)
            }
        }
        .onChange(of: state.searchText) { _, newValue in
            searchModel.updateQuery(newValue)
        }
        .onChange(of: state.isSearchPresented) { _, isPresented in
            if isPresented == false {
                cancelSearchPresentationTasks()
                isSearchFieldFirstResponder = false
                isSearchCardVisible = false
            }
        }
        .onChange(of: state.isMapDefaultState) { _, isMapDefaultState in
            if isMapDefaultState == false {
                cancelSearchPresentationTasks()
                if state.isSearchPresented {
                    withAnimation(shellAnimation) {
                        state.isSearchPresented = false
                    }
                }
                isSearchFieldFirstResponder = false
                isSearchCardVisible = false
            }
        }
        .onDisappear {
            cancelSearchPresentationTasks()
        }
        .task(id: routeRefreshKey) {
            await refreshRouteIfNeeded()
        }
        .onAppear {
            syncLocationUpdates()
            applyUITestOverridesIfNeeded()
            configureUnlockEvaluatorIfNeeded()
            updateUnlockProgressIfNeeded()
        }
        .onChange(of: languageStore.hasCompletedOnboarding) { _, _ in
            syncLocationUpdates()
            applyUITestOverridesIfNeeded()
        }
        .onChange(of: state.navigationPoint?.id) { _, _ in
            configureUnlockEvaluatorIfNeeded()
            updateUnlockProgressIfNeeded()
        }
        .onChange(of: locationProvider.coordinateKey) { _, _ in
            updateUnlockProgressIfNeeded()
        }
        // SHEET-001: 任意关闭路径（Close、下滑、Go动作）和新 pin 切入均重置 detent/高度
        .onChange(of: state.previewPoint?.id) { _, _ in
            measuredPreviewContentHeight = 280
            updatePreviewSheetDetent(.height(280), animated: false)
        }
    }

    @ViewBuilder
    private var mapBackgroundLayer: some View {
        if forceStaticMapSnapshotForUITests {
            DSColor.surfaceSecondary
                .ignoresSafeArea(edges: [.top, .bottom])
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
            .ignoresSafeArea(edges: [.top, .bottom])
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
        let availableWidth = mapContainerWidth > 0
            ? mapContainerWidth - DSSpacing.space24
            : DSControl.searchPanelMaxWidth
        return max(DSControl.minTouchTarget, min(DSControl.searchPanelMaxWidth, availableWidth))
    }

    private var floatingControlsTopInset: CGFloat {
        guard state.navigationPoint != nil else { return DSSpacing.space8 }
        // STEP3-FIX: account for retry banner height so locateMe doesn't overlap it
        let base = DSSpacing.space8 + DSControl.floatingActionTopInsetWithBanner
        guard shouldShowQuickRouteRetry else { return base }
        return base + DSSpacing.space8 + DSControl.minTouchTarget
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

    private var searchTriggerButton: some View {
        Button {
            openSearchInterface()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(DSTypography.iconMedium.weight(.semibold))
                .foregroundStyle(DSColor.textPrimary)
                .frame(width: DSControl.minTouchTarget, height: DSControl.minTouchTarget)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
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
                .accessibilityHidden(true)

            NativeSearchTextField(
                text: $state.searchText,
                isFirstResponder: $isSearchFieldFirstResponder,
                placeholder: strings.searchPrompt,
                accessibilityLabel: strings.searchPrompt,
                accessibilityIdentifier: "map_search_field",
                onSubmit: {
                    Task { @MainActor in
                        await handleSearchSubmit()
                    }
                }
            )
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

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
        }
        .shadow(color: DSColor.borderSubtle.opacity(DSOpacity.overlayShadow), radius: DSRadius.r8, y: DSSpacing.space4)
        .accessibilityIdentifier("map_search_bar")
    }

    private func handleSearchSelection(_ point: PointOfInterest) {
        let title = point.title(in: languageStore.language)
        Task { @MainActor in
            state.searchText = title
            await resignSearchInputSession()
            withAnimation(shellAnimation) {
                state.selectPoint(point)
            }
        }
    }

    private func handleSearchCompletionSelection(_ completion: MKLocalSearchCompletion) {
        state.searchText = searchCompletionText(for: completion)
        Task { @MainActor in
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

    private func handleEndNavigationAction() {
        withAnimation(DSMotion.teardown(reduceMotion: reduceMotion || forceReduceMotionForUITests)) {
            state.endNavigation()
        }
    }

    private func updateMapContainerWidth(_ width: CGFloat) {
        guard width > 0 else { return }
        guard abs(mapContainerWidth - width) > 0.5 else { return }
        mapContainerWidth = width
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
        // Keep open action idempotent for rapid repeated triggers.
        guard state.isSearchPresented == false else {
            isSearchFieldFirstResponder = true
            return
        }
        cancelSearchPresentationTasks()
        isSearchFieldFirstResponder = true

        withAnimation(shellAnimation) {
            state.isSearchPresented = true
        }
        searchCardVisibilityTask = Task { @MainActor in
            // Mount card on next run loop tick to avoid first-frame contention.
            await Task.yield()
            guard Task.isCancelled == false else { return }
            guard state.isSearchPresented else { return }
            withAnimation(shellAnimation) {
                isSearchCardVisible = true
            }
        }
    }

    private func closeSearchInterface() {
        cancelSearchPresentationTasks()
        // Write state synchronously to avoid stale async close tasks racing with reopen.
        isSearchFieldFirstResponder = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        isSearchCardVisible = false
        withAnimation(shellAnimation) {
            state.isSearchPresented = false
        }
    }

    private func cancelSearchPresentationTasks() {
        searchCardVisibilityTask?.cancel()
        searchCardVisibilityTask = nil
    }

    @MainActor
    private func resignSearchInputSession() async {
        isSearchFieldFirstResponder = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        await Task.yield()
    }

    @MainActor
    private func handleSearchSubmit() async {
        let keyword = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard keyword.isEmpty == false else { return }

        if forceSearchNoResultsOnSubmitForUITests {
            await resignSearchInputSession()
            activeAlert = .searchNoResults(query: keyword)
            return
        }

        if let place = await searchModel.search(
            query: keyword,
            fallbackTitle: strings.searchResultFallbackTitle
        ) {
            await resignSearchInputSession()
            withAnimation(shellAnimation) {
                state.selectSearchPlace(place, query: keyword)
            }
        } else {
            await resignSearchInputSession()
            activeAlert = .searchNoResults(query: keyword)
        }
    }

    @MainActor
    private func retrySearch() {
        Task { @MainActor in
            await handleSearchSubmit()
        }
    }

    private var shellAnimation: Animation {
        DSMotion.routeTransition(reduceMotion: reduceMotion || forceReduceMotionForUITests)
    }

    private var previewSheetDetentAnimation: Animation {
        reduceMotion || forceReduceMotionForUITests
            ? .easeOut(duration: DSMotion.durationFast)
            : .smooth(duration: DSMotion.durationNormal, extraBounce: 0)
    }

    private func updatePreviewSheetDetent(_ detent: PresentationDetent, animated: Bool) {
        if animated {
            withAnimation(previewSheetDetentAnimation) {
                previewSheetDetent = detent
            }
            return
        }

        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            previewSheetDetent = detent
        }
    }

    private var routeRefreshKey: String {
        guard let navigationPoint = state.navigationPoint else {
            return "route:none:\(state.routeRetryNonce)"
        }
        return "route:\(navigationPoint.id.uuidString):\(locationProvider.coordinateKey):\(state.routeRetryNonce)"
    }

    @MainActor
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

        if let cached = state.routeCache[cacheKey], now.timeIntervalSince(cached.createdAt) <= 120 {
            state.activeRoute = cached.route
            state.routeStatus = .ready
            return
        }

        if state.lastRouteAttemptKey == cacheKey, now.timeIntervalSince(state.lastRouteAttemptAt) < 3 {
            return
        }

        state.lastRouteAttemptKey = cacheKey
        state.lastRouteAttemptAt = now

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = .walking

        do {
            let response = try await MKDirections(request: request).calculate()
            if let route = response.routes.first {
                state.activeRoute = route
                state.routeStatus = .ready
                state.routeCache[cacheKey] = CachedRoute(route: route, createdAt: now)
                if state.routeCache.count > 12 {
                    state.routeCache = Dictionary(
                        uniqueKeysWithValues: state.routeCache
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
        state.lastRouteAttemptKey = nil
        state.lastRouteAttemptAt = .distantPast
        state.routeRetryNonce += 1
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
    }

    private func configureUnlockEvaluatorIfNeeded() {
        guard let memoryPoint = activeNavigationMemoryPoint else {
            unlockEvaluator = nil
            return
        }

        let evaluator = UnlockEvaluator(target: memoryPoint)
        unlockEvaluator = evaluator

        if forceUnlockedMemoryDetailForUITests {
            evaluator.forceUnlock()
            presentUnlockedMemoryDetailIfNeeded(for: memoryPoint)
        }
    }

    private func updateUnlockProgressIfNeeded() {
        guard let memoryPoint = activeNavigationMemoryPoint,
              let evaluator = unlockEvaluator,
              let coordinate = locationProvider.coordinate else {
            return
        }

        evaluator.updateLocation(coordinate)
        if evaluator.isUnlocked {
            presentUnlockedMemoryDetailIfNeeded(for: memoryPoint)
        }
    }

    private func presentUnlockedMemoryDetailIfNeeded(for memoryPoint: MemoryPoint) {
        guard unlockedMemoryPoint?.id != memoryPoint.id else { return }
        unlockedMemoryPoint = memoryPoint
    }

    private func dismissUnlockedMemoryDetail() {
        unlockedMemoryPoint = nil
        withAnimation(shellAnimation) {
            state.endNavigation()
        }
        unlockEvaluator = nil
    }

    private func handleExperienceComplete(for memoryPoint: MemoryPoint) {
        do {
            _ = try archiveCoordinator.completeExperience(for: memoryPoint, source: .active)
            unlockedMemoryPoint = nil
            withAnimation(shellAnimation) {
                state.endNavigation()
                shellState.archiveRoutes = []
                shellState.selectedTab = .archive
            }
            unlockEvaluator = nil
        } catch {
            activeAlert = .archiveActionFailed(message: archiveErrorMessage(for: error))
        }
    }

    private func applyUITestOverridesIfNeeded() {
        guard languageStore.hasCompletedOnboarding, hasAppliedUITestOverrides == false else { return }
        hasAppliedUITestOverrides = true

        if launchArguments.contains("UITEST_SHOW_SEARCH_NO_RESULT_ALERT") {
            activeAlert = .searchNoResults(query: "forced")
        }

        if launchArguments.contains("UITEST_FORCE_CHANGING_DESTINATION"),
           points.count >= 2 {
            state.navigationPoint = points[0]
            state.routeStatus = .ready
            state.selectPoint(points[1])
            return
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

    private var activeNavigationMemoryPoint: MemoryPoint? {
        guard let navigationPoint = state.navigationPoint else { return nil }
        return memoryRepository.memoryPoint(by: navigationPoint.id)
    }

    private func archiveErrorMessage(for error: Error) -> String {
        guard let archiveError = error as? MemoryArchiveCoordinatorError else {
            return strings.archiveActionGenericFailureBody
        }

        switch archiveError {
        case .archiveUnavailable, .cardRenderFailed:
            return strings.archiveCompleteFailedBody
        case .missingGeneratedCard:
            return strings.archiveCardUnavailable
        case .photoLibraryDenied:
            return strings.archivePhotoAccessDeniedBody
        case .photoSaveFailed:
            return strings.archiveSaveFailedBody
        }
    }
}
