import Foundation

extension AppStrings {
    static let settingsTranslations: AppTranslationTable = [
        "settingsTitle": [
            .en: "Settings",
            .zhHans: "设置",
            .yue: "設定"
        ],
        "languageSection": [
            .en: "Language",
            .zhHans: "语言",
            .yue: "語言"
        ],
        "navigationSection": [
            .en: "Navigation",
            .zhHans: "导航",
            .yue: "導航"
        ],
        "betaSection": [
            .en: "Beta",
            .zhHans: "Beta",
            .yue: "Beta"
        ],
        "betaReturnToOnboardingText": [
            .en: "Return to Onboarding (Beta Only)",
            .zhHans: "返回引导页（Beta Only）",
            .yue: "返回引導頁（Beta Only）"
        ],
        "betaReturnToOnboardingHint": [
            .en: "Reset onboarding completion and show the onboarding flow again",
            .zhHans: "重置引导完成状态，并重新展示引导流程",
            .yue: "重設引導完成狀態，並重新顯示引導流程"
        ],
        "betaResetConfirmationTitle": [
            .en: "Return to Onboarding?",
            .zhHans: "确认返回引导页？",
            .yue: "確認返回引導頁？"
        ],
        "betaResetConfirmationMessage": [
            .en: "This will reset onboarding completion and switch to the Map tab.",
            .zhHans: "此操作会重置引导完成状态，并切换到地图页。",
            .yue: "此操作會重設引導完成狀態，並切換到地圖頁。"
        ],
        "betaResetConfirmAction": [
            .en: "Reset and Return",
            .zhHans: "重置并返回",
            .yue: "重設並返回"
        ],
        "aboutText": [
            .en: "About",
            .zhHans: "关于",
            .yue: "關於"
        ],
        "aboutBody": [
            .en: "First-round App Shell built with SwiftUI system containers: TabView, NavigationStack, and sheet presentations.",
            .zhHans: "首轮 App Shell 使用 SwiftUI 系统容器实现：TabView、NavigationStack 与 sheet。",
            .yue: "首輪 App Shell 使用 SwiftUI 系統容器實作：TabView、NavigationStack 同 sheet。"
        ]
    ]

    var settingsTitle: String { text("settingsTitle") }
    var languageSection: String { text("languageSection") }
    var navigationSection: String { text("navigationSection") }
    var betaSection: String { text("betaSection") }
    var betaReturnToOnboardingText: String { text("betaReturnToOnboardingText") }
    var betaReturnToOnboardingHint: String { text("betaReturnToOnboardingHint") }
    var betaResetConfirmationTitle: String { text("betaResetConfirmationTitle") }
    var betaResetConfirmationMessage: String { text("betaResetConfirmationMessage") }
    var betaResetConfirmAction: String { text("betaResetConfirmAction") }
    var aboutText: String { text("aboutText") }
    var aboutBody: String { text("aboutBody") }
}
