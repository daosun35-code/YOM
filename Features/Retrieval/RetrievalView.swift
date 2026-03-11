import SwiftUI

struct RetrievalView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    let memoryPoint: MemoryPoint
    let showsCloseButton: Bool
    let onClose: (() -> Void)?

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.space24) {
                VStack {
                    Spacer(minLength: 0)
                    Text(memoryPoint.title(in: languageStore.language))
                        .dsTextStyle(.title, weight: .semibold)
                        .foregroundStyle(DSColor.textPrimary)
                        .padding(DSSpacing.space16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: DSControl.detailHeroHeight)
                .dsSurfaceCard()
                .accessibilityHidden(true)
                .dsReadableContent()

                VStack(alignment: .leading, spacing: DSSpacing.space12) {
                    Text(memoryPoint.title(in: languageStore.language))
                        .dsTextStyle(.title, weight: .semibold)
                        .foregroundStyle(DSColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(memoryPoint.year)")
                        .dsTextStyle(.caption, weight: .semibold)
                        .foregroundStyle(DSColor.textSecondary)
                    Text(memoryPoint.summary(in: languageStore.language))
                        .dsTextStyle(.body)
                        .foregroundStyle(DSColor.textPrimary)
                        .lineSpacing(DSLineSpacing.body)
                    Text(strings.retrievalModeStatic)
                        .dsTextStyle(.caption)
                        .foregroundStyle(DSColor.textSecondary)
                }
                .dsReadableContent()

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
                .dsReadableContent()
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
}
