import Foundation
import SwiftUI

struct ArchiveTabRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore

    private let points = PointOfInterest.samples
    private var pointsByID: [UUID: PointOfInterest] {
        Dictionary(uniqueKeysWithValues: points.map { ($0.id, $0) })
    }

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        NavigationStack(path: $shellState.archivePath) {
            List {
                Section {
                    Text(strings.archiveSubtitle)
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }

                Section(strings.archiveListSectionTitle) {
                    ForEach(points) { point in
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
                            .background(
                                RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous)
                                    .fill(DSColor.surfaceElevated)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DSRadius.r16, style: .continuous)
                                    .stroke(DSColor.borderSubtle.opacity(DSOpacity.subtleBorder), lineWidth: DSBorder.bw1)
                            )
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
            .listStyle(.insetGrouped)
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
}
