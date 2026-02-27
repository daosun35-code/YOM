import SwiftUI

struct RetrievalView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    let point: PointOfInterest
    let showsCloseButton: Bool
    let onClose: (() -> Void)?

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 220)
                    .overlay(alignment: .bottomLeading) {
                        Text(point.title(in: languageStore.language))
                            .font(.title2.weight(.semibold))
                            .padding()
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(point.year)")
                        .font(.headline)
                    Text(point.summary(in: languageStore.language))
                        .font(.body)
                    Text(strings.retrievalModeStatic)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                GroupBox(strings.demoNotesTitle) {
                    Text(strings.demoNotesBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
            }
            .padding()
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
