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
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(strings.archiveListSectionTitle) {
                    ForEach(points) { point in
                        Button {
                            shellState.archivePath.append(ArchiveRoute.retrieval(point.id))
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 64, height: 64)
                                        .overlay {
                                            Text("\(point.year)")
                                                .font(.caption.weight(.semibold))
                                        }
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(point.title(in: languageStore.language))
                                            .font(.body.weight(.medium))
                                        Text(point.summary(in: languageStore.language))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }

                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .accessibilityHidden(true)
                                }
                                .frame(minHeight: 72)

                                HStack(spacing: 6) {
                                    Text(strings.archiveOpenRetrievalText)
                                        .font(.caption.weight(.semibold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption)
                                        .accessibilityHidden(true)
                                }
                                .foregroundStyle(.tint)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
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
