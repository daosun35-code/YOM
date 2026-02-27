import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var strings: AppStrings { AppStrings(language: languageStore.language) }

    var body: some View {
        ZStack {
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
            .allowsHitTesting(languageStore.hasCompletedOnboarding)
            .accessibilityHidden(!languageStore.hasCompletedOnboarding)

            if !languageStore.hasCompletedOnboarding {
                OnboardingFlowView {
                    withAnimation(shellAnimation) {
                        languageStore.completeOnboarding()
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(shellAnimation, value: languageStore.hasCompletedOnboarding)
    }

    private var shellAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.9)
    }
}
