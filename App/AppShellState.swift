import Foundation

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
        static let archiveRoutes = "shell.archiveRoutes"
        static let settingsRoutes = "shell.settingsRoutes"
    }

    private let defaults: UserDefaults

    @Published var selectedTab: AppTab {
        didSet {
            defaults.set(selectedTab.rawValue, forKey: Keys.selectedTab)
        }
    }

    @Published var archiveRoutes: [ArchiveRoute] {
        didSet {
            persist(archiveRoutes, forKey: Keys.archiveRoutes)
        }
    }

    @Published var settingsRoutes: [SettingsRoute] {
        didSet {
            persist(settingsRoutes, forKey: Keys.settingsRoutes)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedTab = AppTab(rawValue: defaults.string(forKey: Keys.selectedTab) ?? "") ?? .map
        self.archiveRoutes = Self.load([ArchiveRoute].self, forKey: Keys.archiveRoutes, defaults: defaults) ?? []
        self.settingsRoutes = Self.load([SettingsRoute].self, forKey: Keys.settingsRoutes, defaults: defaults) ?? []
    }

    private func persist<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }

        defaults.set(data, forKey: key)
    }

    private static func load<Value: Decodable>(
        _ type: Value.Type,
        forKey key: String,
        defaults: UserDefaults
    ) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
