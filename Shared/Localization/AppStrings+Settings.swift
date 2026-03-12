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
        "nearbyMemoryRemindersSection": [
            .en: "Nearby reminders",
            .zhHans: "附近提醒",
            .yue: "附近提醒"
        ],
        "nearbyMemoryRemindersTitle": [
            .en: "Nearby memory reminders",
            .zhHans: "附近记忆提醒",
            .yue: "附近記憶提醒"
        ],
        "nearbyMemoryRemindersBody": [
            .en: "Monitor the nearest memory points on device and return to navigation after a reminder tap.",
            .zhHans: "在设备端监控最近的记忆点，并在点按提醒后返回导航主线。",
            .yue: "喺裝置端監控最近記憶點，點按提醒之後返回導航主線。"
        ],
        "nearbyMemoryRemindersEnabledBody": [
            .en: "Nearby memory reminders are on. Monitoring stays on this device.",
            .zhHans: "附近记忆提醒已开启，监控仅在本机进行。",
            .yue: "附近記憶提醒已開啟，監控只會喺本機進行。"
        ],
        "nearbyMemoryRemindersDisabledBody": [
            .en: "Nearby memory reminders are off.",
            .zhHans: "附近记忆提醒当前关闭。",
            .yue: "附近記憶提醒目前關閉。"
        ],
        "nearbyMemoryRemindersPermissionTitle": [
            .en: "Nearby memory reminders unavailable",
            .zhHans: "附近记忆提醒暂不可用",
            .yue: "附近記憶提醒暫不可用"
        ],
        "nearbyMemoryRemindersNotificationDeniedBody": [
            .en: "Allow notifications in Settings to receive nearby memory reminders.",
            .zhHans: "请先在设置中允许通知，才能接收附近记忆提醒。",
            .yue: "請先喺設定允許通知，先可以收到附近記憶提醒。"
        ],
        "nearbyMemoryRemindersLocationDeniedBody": [
            .en: "Allow Always location access in Settings to keep nearby memory reminders working in the background.",
            .zhHans: "请先在设置中允许“始终”定位权限，附近记忆提醒才能在后台工作。",
            .yue: "請先喺設定允許「永遠」定位權限，附近記憶提醒先可以喺背景運作。"
        ],
        "nearbyMemoryRemindersLocationUnavailableBody": [
            .en: "We couldn't determine your current location. Open the map once and try again.",
            .zhHans: "暂时无法确定你当前的位置，请先打开地图再重试。",
            .yue: "暫時無法判斷你而家位置，請先打開地圖再試。"
        ],
        "nearbyMemoryRemindersGenericFailureBody": [
            .en: "We couldn't enable nearby memory reminders right now. Try again.",
            .zhHans: "暂时无法开启附近记忆提醒，请稍后重试。",
            .yue: "暫時無法開啟附近記憶提醒，請稍後再試。"
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
    var nearbyMemoryRemindersSection: String { text("nearbyMemoryRemindersSection") }
    var nearbyMemoryRemindersTitle: String { text("nearbyMemoryRemindersTitle") }
    var nearbyMemoryRemindersBody: String { text("nearbyMemoryRemindersBody") }
    var nearbyMemoryRemindersEnabledBody: String { text("nearbyMemoryRemindersEnabledBody") }
    var nearbyMemoryRemindersDisabledBody: String { text("nearbyMemoryRemindersDisabledBody") }
    var nearbyMemoryRemindersPermissionTitle: String { text("nearbyMemoryRemindersPermissionTitle") }
    var nearbyMemoryRemindersNotificationDeniedBody: String { text("nearbyMemoryRemindersNotificationDeniedBody") }
    var nearbyMemoryRemindersLocationDeniedBody: String { text("nearbyMemoryRemindersLocationDeniedBody") }
    var nearbyMemoryRemindersLocationUnavailableBody: String { text("nearbyMemoryRemindersLocationUnavailableBody") }
    var nearbyMemoryRemindersGenericFailureBody: String { text("nearbyMemoryRemindersGenericFailureBody") }
    var betaSection: String { text("betaSection") }
    var betaReturnToOnboardingText: String { text("betaReturnToOnboardingText") }
    var betaReturnToOnboardingHint: String { text("betaReturnToOnboardingHint") }
    var betaResetConfirmationTitle: String { text("betaResetConfirmationTitle") }
    var betaResetConfirmationMessage: String { text("betaResetConfirmationMessage") }
    var betaResetConfirmAction: String { text("betaResetConfirmAction") }
    var aboutText: String { text("aboutText") }
    var aboutBody: String { text("aboutBody") }
}
