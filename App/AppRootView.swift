import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        Group {
            if languageStore.hasCompletedOnboarding {
                TabView(selection: $shellState.selectedTab) {
                    ArchiveTabRootView()
                        .tabItem { Label(strings.tabArchive, systemImage: "tray.full") }
                        .tag(AppTab.archive)

                    MapTabRootView()
                        .tabItem { Label(strings.tabMap, systemImage: "map") }
                        .tag(AppTab.map)

                    SettingsTabRootView()
                        .tabItem { Label(strings.tabSettings, systemImage: "gearshape") }
                        .tag(AppTab.settings)
                }
                .transition(.opacity)
            } else {
                OnboardingFlowView {
                    withAnimation(shellAnimation) {
                        languageStore.completeOnboarding()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(shellAnimation, value: languageStore.hasCompletedOnboarding)
    }

    private var shellAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.9)
    }
}
