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

                Section {
                    ForEach(points) { point in
                        Button {
                            shellState.archivePath.append(ArchiveRoute.retrieval(point.id))
                        } label: {
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
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                            .frame(minHeight: 72)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(point.accessibilityLabel(in: languageStore.language))
                        .accessibilityHint(strings.detailsText)
                    }
                }
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
}
