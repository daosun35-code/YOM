import SwiftUI

@main
struct YOMApp: App {
    @StateObject private var shellState = AppShellState()
    @StateObject private var languageStore = LanguageStore()

    init() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("UITEST_RESET_APP_STATE"),
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
                .environment(\.locale, languageStore.language.locale)
        }
    }
}
