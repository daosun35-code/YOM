import Foundation

@MainActor
final class LanguageStore: ObservableObject {
    private enum Keys {
        static let language = "app.language"
        static let onboardingCompleted = "app.onboarding.completed"
    }

    private let defaults: UserDefaults

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.onboardingCompleted)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedLanguage = defaults.string(forKey: Keys.language)
        self.language = AppLanguage(rawValue: savedLanguage ?? "") ?? Self.defaultLanguage(from: Locale.preferredLanguages)
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.onboardingCompleted)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    private static func defaultLanguage(from preferredLanguages: [String]) -> AppLanguage {
        guard let preferred = preferredLanguages.first?.lowercased() else {
            return .en
        }
        if preferred.hasPrefix("zh-hans") || preferred.hasPrefix("zh-cn") {
            return .zhHans
        }
        if preferred.hasPrefix("yue") || preferred.hasPrefix("zh-hk") || preferred.hasPrefix("zh-mo") {
            return .yue
        }
        return .en
    }
}
