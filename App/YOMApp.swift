import SwiftUI

@main
@MainActor
struct YOMApp: App {
    @StateObject private var shellState: AppShellState
    @StateObject private var languageStore: LanguageStore
    @StateObject private var memoryRepository: LocalMemoryRepository
    @StateObject private var archiveCoordinator: MemoryArchiveCoordinator
    private let launchArguments = ProcessInfo.processInfo.arguments

    init() {
        if launchArguments.contains("UITEST_RESET_APP_STATE"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            MemoryArchiveCoordinator.resetPersistentStore()
        }

        _shellState = StateObject(wrappedValue: AppShellState())
        _languageStore = StateObject(wrappedValue: LanguageStore())
        _memoryRepository = StateObject(wrappedValue: LocalMemoryRepository())
        _archiveCoordinator = StateObject(wrappedValue: MemoryArchiveCoordinator())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(shellState)
                .environmentObject(languageStore)
                .environmentObject(memoryRepository)
                .environmentObject(archiveCoordinator)
                .environment(\.locale, languageStore.language.locale)
                .transformEnvironment(\.dynamicTypeSize) { value in
                    guard launchArguments.contains("UITEST_FORCE_DYNAMIC_TYPE_ACCESSIBILITY_XXXL") else { return }
                    value = .accessibility5
                }
        }
    }
}
