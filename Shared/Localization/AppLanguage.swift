import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case en
    case zhHans
    case yue

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .en:
            return Locale(identifier: "en")
        case .zhHans:
            return Locale(identifier: "zh-Hans")
        case .yue:
            return Locale(identifier: "yue-Hant")
        }
    }

    var displayName: String {
        switch self {
        case .en:
            return "English"
        case .zhHans:
            return "简体中文"
        case .yue:
            return "粵語（繁體）"
        }
    }
}
