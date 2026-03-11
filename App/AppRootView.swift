import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var shellState: AppShellState
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var memoryRepository: LocalMemoryRepository
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let launchArguments = ProcessInfo.processInfo.arguments

    private var strings: AppStrings { AppStrings(language: languageStore.language) }
    private var forceMemoryDetailViewForUITests: Bool {
        launchArguments.contains("UITEST_FORCE_MEMORY_DETAIL_VIEW")
    }

    var body: some View {
        Group {
            if languageStore.hasCompletedOnboarding {
                signedInContent
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

    @ViewBuilder
    private var signedInContent: some View {
        if forceMemoryDetailViewForUITests, let memoryPoint = memoryRepository.memoryPoints.first {
            NavigationStack {
                MemoryDetailView(memoryPoint: memoryPoint, onComplete: {})
            }
        } else {
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
        }
    }

    private var shellAnimation: Animation {
        DSMotion.shell(reduceMotion: reduceMotion || launchArguments.contains("UITEST_FORCE_REDUCE_MOTION"))
    }
}
