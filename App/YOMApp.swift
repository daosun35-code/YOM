import SwiftUI

@main
struct YOMApp: App {
    @StateObject private var shellState = AppShellState()
    @StateObject private var languageStore = LanguageStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(shellState)
                .environmentObject(languageStore)
                .environment(\.locale, languageStore.language.locale)
        }
    }
}
