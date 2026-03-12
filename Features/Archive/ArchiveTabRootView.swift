import Foundation
import SwiftUI
import UIKit

struct ArchiveTabRootView: View {
    private enum ArchiveSubmenu: Hashable {
        case explored
        case favorites
    }

    private enum ArchiveActionAlert: Identifiable {
        case saveSucceeded
        case actionFailed(String)

        var id: String {
            switch self {
            case .saveSucceeded:
                return "save-succeeded"
            case .actionFailed(let message):
                return "action-failed-\(message)"
            }
        }
    }

    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var memoryRepository: LocalMemoryRepository
    @EnvironmentObject private var archiveCoordinator: MemoryArchiveCoordinator
    @State private var selectedSubmenu: ArchiveSubmenu = .explored
    @State private var actionAlert: ArchiveActionAlert?

    private let favoriteYears: Set<Int> = [1920, 1962]
    private var archiveEntries: [ArchivedMemoryEntry] {
        archiveCoordinator.archiveEntries(memoryPointLookup: memoryRepository.memoryPoint(by:))
    }
    private var exploredEntries: [ArchivedMemoryEntry] { archiveEntries }
    private var favoriteEntries: [ArchivedMemoryEntry] {
        archiveEntries.filter { favoriteYears.contains($0.memoryPoint.year) }
    }
    private var visibleEntries: [ArchivedMemoryEntry] {
        switch selectedSubmenu {
        case .explored:
            return exploredEntries
        case .favorites:
            return favoriteEntries
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
        strings.archiveSectionTitle(base: visibleSectionTitle, count: visibleEntries.count)
    }

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        NavigationStack(path: $shellState.archiveRoutes) {
            List {
                Section(visibleSectionHeader) {
                    if visibleEntries.isEmpty {
                        ContentUnavailableView(
                            selectedSubmenu == .explored
                                ? strings.archiveEmptyExploredTitle
                                : strings.archiveEmptyFavoritesTitle,
                            systemImage: selectedSubmenu == .explored ? "tray" : "star.slash",
                            description: Text(
                                selectedSubmenu == .explored
                                    ? strings.archiveEmptyExploredBody
                                    : strings.archiveEmptyFavoritesBody
                            )
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
                        ForEach(visibleEntries) { entry in
                            archiveEntryRow(entry)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: DSSpacing.space8,
                                        leading: DSSpacing.space16,
                                        bottom: DSSpacing.space8,
                                        trailing: DSSpacing.space16
                                    )
                                )
                                .listRowSeparator(.hidden)
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
                    if let memoryPoint = memoryRepository.memoryPoint(by: pointID) {
                        RetrievalView(memoryPoint: memoryPoint, showsCloseButton: false, onClose: nil)
                    } else {
                        ContentUnavailableView(
                            strings.archiveTitle,
                            systemImage: "exclamationmark.triangle",
                            description: Text(strings.archiveItemUnavailable)
                        )
                    }
                }
            }
            .alert(item: $actionAlert) { alert in
                switch alert {
                case .saveSucceeded:
                    return Alert(
                        title: Text(strings.archiveSaveSuccessTitle),
                        message: Text(strings.archiveSaveSuccessBody),
                        dismissButton: .default(Text(strings.closeText))
                    )
                case .actionFailed(let message):
                    return Alert(
                        title: Text(strings.archiveActionErrorTitle),
                        message: Text(message),
                        dismissButton: .default(Text(strings.closeText))
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func archiveEntryRow(_ entry: ArchivedMemoryEntry) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.space12) {
            Button {
                shellState.archiveRoutes.append(ArchiveRoute.retrieval(entry.memoryPoint.id))
            } label: {
                VStack(alignment: .leading, spacing: DSSpacing.space12) {
                    HStack(spacing: DSSpacing.space12) {
                        cardPreview(for: entry)

                        VStack(alignment: .leading, spacing: DSSpacing.space4) {
                            Text(entry.memoryPoint.title(in: languageStore.language))
                                .dsTextStyle(.body, weight: .medium)
                                .foregroundStyle(DSColor.textPrimary)
                            Text(entry.memoryPoint.summary(in: languageStore.language))
                                .dsTextStyle(.caption)
                                .foregroundStyle(DSColor.textSecondary)
                                .lineLimit(2)
                            Text(
                                strings.archiveArchivedOn(
                                    entry.record.exploredAt.formatted(.dateTime.year().month(.abbreviated).day())
                                )
                            )
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)

                            if favoriteYears.contains(entry.memoryPoint.year) {
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
            .accessibilityIdentifier("archive_item_\(entry.memoryPoint.year)")
            .accessibilityLabel(entry.memoryPoint.poi.accessibilityLabel(in: languageStore.language))
            .accessibilityHint(strings.archiveOpenRetrievalHint)

            if let cardURL = entry.cardURL {
                HStack(spacing: DSSpacing.space8) {
                    ShareLink(item: cardURL) {
                        archiveActionChip(
                            title: strings.archiveShareCard,
                            systemName: "square.and.arrow.up"
                        )
                    }
                    .accessibilityIdentifier("archive_share_card_\(entry.memoryPoint.year)")
                    .accessibilityLabel(strings.archiveShareCard)

                    Button {
                        Task { await saveCardToPhotos(for: entry) }
                    } label: {
                        archiveActionChip(
                            title: strings.archiveSaveCard,
                            systemName: "square.and.arrow.down"
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("archive_save_card_\(entry.memoryPoint.year)")
                    .accessibilityLabel(strings.archiveSaveCard)

                    Spacer(minLength: 0)
                }
                .padding(.leading, DSSpacing.space4)
            }
        }
    }

    @ViewBuilder
    private func cardPreview(for entry: ArchivedMemoryEntry) -> some View {
        if let cardURL = entry.cardURL,
           let uiImage = UIImage(contentsOfFile: cardURL.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: DSControl.listThumbnailSize, height: DSControl.listThumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous)
                        .stroke(DSColor.borderSubtle.opacity(DSOpacity.subtleBorder), lineWidth: DSBorder.bw1)
                )
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: DSRadius.r12, style: .continuous)
                .fill(DSColor.surfaceSecondary)
                .frame(width: DSControl.listThumbnailSize, height: DSControl.listThumbnailSize)
                .overlay {
                    Text("\(entry.memoryPoint.year)")
                        .dsTextStyle(.caption, weight: .semibold)
                }
                .accessibilityHidden(true)
        }
    }

    private func archiveActionChip(title: String, systemName: String) -> some View {
        Label(title, systemImage: systemName)
            .dsTextStyle(.caption, weight: .semibold)
            .foregroundStyle(DSColor.textPrimary)
            .padding(.horizontal, DSSpacing.space12)
            .padding(.vertical, DSSpacing.space8)
            .background(
                Capsule(style: .continuous)
                    .fill(DSColor.surfaceSecondary)
            )
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

    private func saveCardToPhotos(for entry: ArchivedMemoryEntry) async {
        do {
            try await archiveCoordinator.saveCardToPhotos(memoryPointID: entry.memoryPoint.id)
            actionAlert = .saveSucceeded
        } catch {
            actionAlert = .actionFailed(archiveErrorMessage(for: error))
        }
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
