import SwiftUI

struct RetrievalView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    let point: PointOfInterest
    let showsCloseButton: Bool
    let onClose: (() -> Void)?

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.space24) {
                readableSection {
                    VStack {
                        Spacer(minLength: 0)
                        Text(point.title(in: languageStore.language))
                            .dsTextStyle(.title, weight: .semibold)
                            .foregroundStyle(DSColor.textPrimary)
                            .padding(DSSpacing.space16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: DSControl.detailHeroHeight)
                    .dsSurfaceCard()
                    .accessibilityHidden(true)
                }

                readableSection {
                    VStack(alignment: .leading, spacing: DSSpacing.space12) {
                        Text(point.title(in: languageStore.language))
                            .dsTextStyle(.title, weight: .semibold)
                            .foregroundStyle(DSColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        Text("\(point.year)")
                            .dsTextStyle(.caption, weight: .semibold)
                            .foregroundStyle(DSColor.textSecondary)
                        Text(point.summary(in: languageStore.language))
                            .dsTextStyle(.body)
                            .foregroundStyle(DSColor.textPrimary)
                            .lineSpacing(DSLineSpacing.body)
                        Text(strings.retrievalModeStatic)
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)
                    }
                }

                readableSection {
                    GroupBox {
                        Text(strings.demoNotesBody)
                            .dsTextStyle(.caption)
                            .foregroundStyle(DSColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, DSSpacing.space4)
                    } label: {
                        Text(strings.demoNotesTitle)
                            .dsTextStyle(.headline)
                    }
                }
            }
            .padding(.horizontal, DSSpacing.space24)
            .padding(.vertical, DSSpacing.space16)
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
            .frame(maxWidth: DSLayout.readableContentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
