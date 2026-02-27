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
            VStack(alignment: .leading, spacing: 16) {
                Text(strings.aboutText)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Text(strings.aboutBody)
                    .font(.body)

                GroupBox(strings.demoNotesTitle) {
                    Text(strings.demoNotesBody)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle(strings.aboutText)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
