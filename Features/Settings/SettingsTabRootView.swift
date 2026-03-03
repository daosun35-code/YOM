import SwiftUI

struct SettingsTabRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        NavigationStack(path: $shellState.settingsPath) {
            Form {
                Section(strings.languageSection) {
                    Picker(strings.languageSection, selection: $languageStore.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section(strings.navigationSection) {
                    Button {
                        shellState.settingsPath.append(SettingsRoute.about)
                    } label: {
                        Label(strings.aboutText, systemImage: "info.circle")
                    }
                    .accessibilityLabel(strings.aboutText)
                }
            }
            .navigationTitle(strings.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .about:
                    AboutView()
                }
            }
        }
    }
}

struct AboutView: View {
    @EnvironmentObject private var languageStore: LanguageStore

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.space24) {
                readableSection {
                    VStack(alignment: .leading, spacing: DSSpacing.space12) {
                        Text(strings.aboutText)
                            .dsTextStyle(.title, weight: .semibold)
                            .foregroundStyle(DSColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)

                        Text(strings.aboutBody)
                            .dsTextStyle(.body)
                            .foregroundStyle(DSColor.textPrimary)
                            .lineSpacing(DSLineSpacing.body)
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
        .navigationTitle(strings.aboutText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func readableSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: DSLayout.readableContentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
