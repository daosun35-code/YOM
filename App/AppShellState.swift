import Foundation
import SwiftUI

enum AppTab: String, Hashable, Codable {
    case archive
    case map
    case settings
}

enum SettingsRoute: Hashable, Codable {
    case about
}

enum ArchiveRoute: Hashable, Codable {
    case retrieval(UUID)
}

@MainActor
final class AppShellState: ObservableObject {
    private enum Keys {
        static let selectedTab = "shell.selectedTab"
        static let archivePath = "shell.archivePath"
        static let mapPath = "shell.mapPath"
        static let settingsPath = "shell.settingsPath"
    }

    private let defaults: UserDefaults

    @Published var selectedTab: AppTab {
        didSet {
            defaults.set(selectedTab.rawValue, forKey: Keys.selectedTab)
        }
    }

    @Published var archivePath: NavigationPath {
        didSet {
            persist(path: archivePath, forKey: Keys.archivePath)
        }
    }

    @Published var mapPath: NavigationPath {
        didSet {
            persist(path: mapPath, forKey: Keys.mapPath)
        }
    }

    @Published var settingsPath: NavigationPath {
        didSet {
            persist(path: settingsPath, forKey: Keys.settingsPath)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedTab = AppTab(rawValue: defaults.string(forKey: Keys.selectedTab) ?? "") ?? .map
        self.archivePath = Self.loadPath(forKey: Keys.archivePath, defaults: defaults)
        self.mapPath = Self.loadPath(forKey: Keys.mapPath, defaults: defaults)
        self.settingsPath = Self.loadPath(forKey: Keys.settingsPath, defaults: defaults)
    }

    private func persist(path: NavigationPath, forKey key: String) {
        guard let codable = path.codable,
              let data = try? JSONEncoder().encode(codable) else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(data, forKey: key)
    }

    private static func loadPath(forKey key: String, defaults: UserDefaults) -> NavigationPath {
        guard let data = defaults.data(forKey: key),
              let codable = try? JSONDecoder().decode(NavigationPath.CodableRepresentation.self, from: data) else {
            return NavigationPath()
        }

        return NavigationPath(codable)
    }
}
