import SwiftUI

struct RetrievalView: View {
    private static let readableContentMaxWidth: CGFloat = 680

    @EnvironmentObject private var languageStore: LanguageStore

    let point: PointOfInterest
    let showsCloseButton: Bool
    let onClose: (() -> Void)?

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                readableSection {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 220)
                        .overlay(alignment: .bottomLeading) {
                            Text(point.title(in: languageStore.language))
                                .font(.title3.weight(.semibold))
                                .padding()
                        }
                        .accessibilityHidden(true)
                }

                readableSection {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(point.title(in: languageStore.language))
                            .font(.title3.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Text("\(point.year)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(point.summary(in: languageStore.language))
                            .font(.body)
                            .lineSpacing(3)
                        Text(strings.retrievalModeStatic)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                readableSection {
                    GroupBox {
                        Text(strings.demoNotesBody)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } label: {
                        Text(strings.demoNotesTitle)
                            .font(.headline)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(strings.retrievalTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.closeText) {
                        onClose?()
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
        }
    }

    private func readableSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: Self.readableContentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
