import Foundation

typealias AppTranslationTable = [String: [AppLanguage: String]]

struct AppStrings {
    let language: AppLanguage

    func archiveSectionTitle(base: String, count: Int) -> String {
        switch language {
        case .en:
            "\(base) · \(count)"
        case .zhHans, .yue:
            "\(base)（\(count)）"
        }
    }

    func text(_ key: String) -> String {
        guard let entry = Self.translations[key] else {
            assertionFailure("Missing AppStrings key: \(key)")
            return key
        }

        return entry[language] ?? entry[.en] ?? key
    }

    private static let translations: AppTranslationTable = {
        [
            coreTranslations,
            mapTranslations,
            archiveTranslations,
            settingsTranslations,
            memoryTranslations
        ].reduce(into: [:]) { result, table in
            for (key, value) in table {
                result[key] = value
            }
        }
    }()
}
