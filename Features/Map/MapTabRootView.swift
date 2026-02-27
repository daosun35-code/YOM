import MapKit
import SwiftUI

@MainActor
final class MapScreenState: ObservableObject {
    @Published var cameraPosition: MapCameraPosition
    @Published var previewPoint: PointOfInterest?
    @Published var navigationPoint: PointOfInterest?
    @Published var retrievalPoint: PointOfInterest?
    @Published var isNavigationDetailPresented = false
    @Published var searchText = ""
    @Published var isSearchPresented = false
    @Published private(set) var recentPointIDs: [UUID] = []

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
        previewPoint = point
        isSearchPresented = false
        recordRecent(point)
    }

    func dismissPreview() {
        previewPoint = nil
    }

    func startOrChangeNavigation() {
        guard let point = previewPoint else { return }
        navigationPoint = point
        previewPoint = nil
    }

    func showDetails() {
        guard let point = previewPoint else { return }
        retrievalPoint = point
        previewPoint = nil
    }

    func endNavigation() {
        navigationPoint = nil
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
}

struct MapTabRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var state = MapScreenState()

    private let points = PointOfInterest.samples

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

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
                        detailsTitle: strings.detailsText,
                        onPrimaryAction: {
                            withAnimation(shellAnimation) {
                                state.startOrChangeNavigation()
                            }
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
                .searchSuggestions {
                    ForEach(recommendedPoints) { point in
                        Text(point.title(in: languageStore.language))
                            .searchCompletion(point.title(in: languageStore.language))
                    }
                }
        } else {
            mapCanvas
        }
    }

    private var mapCanvas: some View {
        ZStack(alignment: .top) {
            Map(position: $state.cameraPosition) {
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
                        .accessibilityLabel(point.accessibilityLabel(in: languageStore.language))
                        .accessibilityAddTraits(.isButton)
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
            VStack(spacing: 8) {
                Button {
                    withAnimation(shellAnimation) {
                        state.recenterDefault()
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                .padding(.top, 12)
                .accessibilityLabel(strings.locateMe)
                .accessibilityAddTraits(.isButton)
            }
        }
        .onChange(of: state.searchText) { _, newValue in
            if newValue.isEmpty == false && state.isSearchPresented == false {
                state.isSearchPresented = true
            }
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
}

private struct MapPreviewSheetView: View {
    let point: PointOfInterest
    let language: AppLanguage
    let isChangingDestination: Bool
    let primaryActionTitle: String
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
                .frame(maxWidth: .infinity, minHeight: 44)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Button(detailsTitle) {
                    onDetails()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, minHeight: 44)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }

            if isChangingDestination {
                Text(primaryActionTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }
}

private struct NavigationPillView: View {
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
            .accessibilityHint("Open navigation details")

            Button(strings.endNavigation) {
                onEnd()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .frame(minWidth: 44, minHeight: 44)
        }
    }
}

private struct NavigationDetailSheet: View {
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
                        onEnd()
                    } label: {
                        Text(strings.endNavigation)
                    }
                }
            }
            .navigationTitle(strings.navigationActive)
            .navigationBarTitleDisplayMode(.inline)
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
