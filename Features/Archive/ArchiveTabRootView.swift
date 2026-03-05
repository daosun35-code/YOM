import Foundation
import SwiftUI

struct ArchiveTabRootView: View {
    private enum ArchiveSubmenu: Hashable {
        case explored
        case favorites
    }

    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var selectedSubmenu: ArchiveSubmenu = .explored

    private let points = PointOfInterest.samples
    private let favoriteYears: Set<Int> = [1935, 1962]
    // PERF-001: computed→let，避免每次 body 执行重建字典
    private let pointsByID = Dictionary(uniqueKeysWithValues: PointOfInterest.samples.map { ($0.id, $0) })
    private var exploredPoints: [PointOfInterest] { points }
    private var favoritePoints: [PointOfInterest] {
        points.filter { favoriteYears.contains($0.year) }
    }
    private var visiblePoints: [PointOfInterest] {
        switch selectedSubmenu {
        case .explored:
            return exploredPoints
        case .favorites:
            return favoritePoints
        }
    }
    private var visibleSectionTitle: String {
        switch selectedSubmenu {
        case .explored:
            return strings.archiveExploredSectionTitle
        case .favorites:
            return strings.archiveFavoritesSectionTitle
        }
    }
    private var visibleSectionHeader: String {
        strings.archiveSectionTitle(base: visibleSectionTitle, count: visiblePoints.count)
    }

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        NavigationStack(path: $shellState.archivePath) {
            List {
                Section(visibleSectionHeader) {
                    if visiblePoints.isEmpty {
                        ContentUnavailableView(
                            strings.archiveEmptyStateTitle,
                            systemImage: "star.slash",
                            description: Text(strings.archiveEmptyStateBody)
                        )
                        .listRowInsets(
                            EdgeInsets(
                                top: DSSpacing.space8,
                                leading: DSSpacing.space16,
                                bottom: DSSpacing.space8,
                                trailing: DSSpacing.space16
                            )
                        )
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(visiblePoints) { point in
                            Button {
                                shellState.archivePath.append(ArchiveRoute.retrieval(point.id))
                            } label: {
                                VStack(alignment: .leading, spacing: DSSpacing.space12) {
                                    HStack(spacing: DSSpacing.space12) {
                                        RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous)
                                            .fill(DSColor.surfaceSecondary)
                                            .frame(width: DSControl.listThumbnailSize, height: DSControl.listThumbnailSize)
                                            .overlay {
                                                Text("\(point.year)")
                                                    .dsTextStyle(.caption, weight: .semibold)
                                            }
                                            .accessibilityHidden(true)

                                        VStack(alignment: .leading, spacing: DSSpacing.space4) {
                                            Text(point.title(in: languageStore.language))
                                                .dsTextStyle(.body, weight: .medium)
                                                .foregroundStyle(DSColor.textPrimary)
                                            Text(point.summary(in: languageStore.language))
                                                .dsTextStyle(.caption)
                                                .foregroundStyle(DSColor.textSecondary)
                                                .lineLimit(2)
                                            if favoriteYears.contains(point.year) {
                                                Label(strings.archiveFavoriteTag, systemImage: "star.fill")
                                                    .dsTextStyle(.caption, weight: .semibold)
                                                    .foregroundStyle(DSColor.statusWarning)
                                            }
                                        }

                                        Spacer(minLength: DSSpacing.space8)
                                        Image(systemName: "chevron.right")
                                            .dsTextStyle(.caption, weight: .semibold)
                                            .foregroundStyle(DSColor.textSecondary)
                                            .accessibilityHidden(true)
                                    }
                                    .frame(minHeight: DSControl.listItemMinHeight)

                                    HStack(spacing: DSSpacing.space8) {
                                        Text(strings.archiveOpenRetrievalText)
                                            .dsTextStyle(.caption, weight: .semibold)
                                        Image(systemName: "arrow.right.circle.fill")
                                            .dsTextStyle(.caption)
                                            .accessibilityHidden(true)
                                    }
                                    .foregroundStyle(DSColor.accentPrimary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .padding(DSSpacing.space12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .dsSurfaceCard()
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(
                                EdgeInsets(
                                    top: DSSpacing.space8,
                                    leading: DSSpacing.space16,
                                    bottom: DSSpacing.space8,
                                    trailing: DSSpacing.space16
                                )
                            )
                            .listRowSeparator(.hidden)
                            .accessibilityIdentifier("archive_item_\(point.year)")
                            .accessibilityLabel(point.accessibilityLabel(in: languageStore.language))
                            .accessibilityHint(strings.archiveOpenRetrievalHint)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .animation(.easeInOut(duration: DSMotion.durationFast), value: selectedSubmenu)
            .safeAreaInset(edge: .top, spacing: 0) {
                archiveSubmenuBar
            }
            .navigationTitle(strings.archiveTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ArchiveRoute.self) { route in
                switch route {
                case .retrieval(let pointID):
                    if let point = pointsByID[pointID] {
                        RetrievalView(point: point, showsCloseButton: false, onClose: nil)
                    } else {
                        ContentUnavailableView(
                            strings.archiveTitle,
                            systemImage: "exclamationmark.triangle",
                            description: Text(strings.archiveItemUnavailable)
                        )
                    }
                }
            }
        }
    }

    private var archiveSubmenuBar: some View {
        Picker(strings.archiveSubmenuTitle, selection: $selectedSubmenu) {
            Text(strings.archiveSubmenuExplored)
                .tag(ArchiveSubmenu.explored)
            Text(strings.archiveSubmenuFavorites)
                .tag(ArchiveSubmenu.favorites)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("archive_submenu_picker")
        .accessibilityValue(
            selectedSubmenu == .explored
                ? strings.archiveSubmenuExplored
                : strings.archiveSubmenuFavorites
        )
        .padding(.horizontal, DSSpacing.space16)
        .padding(.top, DSSpacing.space8)
        .padding(.bottom, DSSpacing.space8)
        .background(DSColor.surfacePrimary)
    }
}
