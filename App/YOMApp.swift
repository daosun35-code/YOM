import SwiftUI

@main
struct YOMApp: App {
    @StateObject private var shellState = AppShellState()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var memoryRepository = LocalMemoryRepository()
    private let launchArguments = ProcessInfo.processInfo.arguments

    init() {
        guard launchArguments.contains("UITEST_RESET_APP_STATE"),
              let bundleID = Bundle.main.bundleIdentifier else {
            return
        }

        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(shellState)
                .environmentObject(languageStore)
                .environmentObject(memoryRepository)
                .environment(\.locale, languageStore.language.locale)
                .transformEnvironment(\.dynamicTypeSize) { value in
                    guard launchArguments.contains("UITEST_FORCE_DYNAMIC_TYPE_ACCESSIBILITY_XXXL") else { return }
                    value = .accessibility5
                }
        }
    }
}
