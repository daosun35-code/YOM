import SwiftUI

enum AppTab: Hashable {
    case archive
    case map
    case settings
}

enum SettingsRoute: Hashable {
    case about
}

enum ArchiveRoute: Hashable {
    case retrieval(PointOfInterest)
}

@MainActor
final class AppShellState: ObservableObject {
    @Published var selectedTab: AppTab = .map
    @Published var archivePath = NavigationPath()
    @Published var mapPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
}
