import SwiftUI

@main
@MainActor
struct YOMApp: App {
    @StateObject private var shellState: AppShellState
    @StateObject private var languageStore: LanguageStore
    @StateObject private var memoryRepository: LocalMemoryRepository
    @StateObject private var archiveCoordinator: MemoryArchiveCoordinator
    @StateObject private var passiveCoordinator: PassiveExperienceCoordinator
    private let launchArguments = ProcessInfo.processInfo.arguments

    init() {
        if launchArguments.contains("UITEST_RESET_APP_STATE"),
           let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            MemoryArchiveCoordinator.resetPersistentStore()
        }

        let languageStore = LanguageStore()
        let memoryRepository = LocalMemoryRepository()
        _shellState = StateObject(wrappedValue: AppShellState())
        _languageStore = StateObject(wrappedValue: languageStore)
        _memoryRepository = StateObject(wrappedValue: memoryRepository)
        _archiveCoordinator = StateObject(wrappedValue: MemoryArchiveCoordinator())
        _passiveCoordinator = StateObject(
            wrappedValue: PassiveExperienceCoordinator(
                memoryLookup: memoryRepository.memoryPoint(by:),
                allMemories: { memoryRepository.memoryPoints },
                preferredLanguage: { languageStore.language }
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(shellState)
                .environmentObject(languageStore)
                .environmentObject(memoryRepository)
                .environmentObject(archiveCoordinator)
                .environmentObject(passiveCoordinator)
                .environment(\.locale, languageStore.language.locale)
                .transformEnvironment(\.dynamicTypeSize) { value in
                    guard launchArguments.contains("UITEST_FORCE_DYNAMIC_TYPE_ACCESSIBILITY_XXXL") else { return }
                    value = .accessibility5
                }
        }
    }
}
