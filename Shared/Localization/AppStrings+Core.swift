import Foundation

extension AppStrings {
    static let coreTranslations: AppTranslationTable = [
        "appTitle": [
            .en: "YOM",
            .zhHans: "YOM 记忆地图",
            .yue: "YOM 記憶地圖"
        ],
        "tabArchive": [
            .en: "Archive",
            .zhHans: "档案",
            .yue: "檔案"
        ],
        "tabMap": [
            .en: "Map",
            .zhHans: "地图",
            .yue: "地圖"
        ],
        "tabSettings": [
            .en: "Settings",
            .zhHans: "设置",
            .yue: "設定"
        ],
        "onboardingLanguageTitle": [
            .en: "Choose your language",
            .zhHans: "选择语言",
            .yue: "選擇語言"
        ],
        "onboardingLanguageBody": [
            .en: "You can change this anytime in Settings. Changes apply instantly.",
            .zhHans: "你可以稍后在设置中修改，切换后会立即生效。",
            .yue: "你可以之後喺設定更改，切換會即時生效。"
        ],
        "onboardingPermissionTitle": [
            .en: "Stay updated while walking",
            .zhHans: "步行探索时保持提醒",
            .yue: "步行探索時保持提醒"
        ],
        "onboardingPermissionBody": [
            .en: "Push permission is optional and does not block map access in the first round shell.",
            .zhHans: "推送权限为可选项，首轮壳层实现中不会阻止进入地图。",
            .yue: "推送權限屬可選，首輪殼層實作唔會阻止進入地圖。"
        ],
        "continueText": [
            .en: "Continue",
            .zhHans: "继续",
            .yue: "繼續"
        ],
        "allowPermission": [
            .en: "Allow Notifications and Open Map",
            .zhHans: "允许通知并进入地图",
            .yue: "允許通知並進入地圖"
        ],
        "skipForNow": [
            .en: "Open Map Without Notifications",
            .zhHans: "暂不授权，直接进入地图",
            .yue: "暫不授權，直接進入地圖"
        ],
        "onboardingStep1Of2": [
            .en: "Step 1 of 2",
            .zhHans: "第 1 步，共 2 步",
            .yue: "第 1 步，共 2 步"
        ],
        "onboardingStep2Of2": [
            .en: "Step 2 of 2",
            .zhHans: "第 2 步，共 2 步",
            .yue: "第 2 步，共 2 步"
        ],
        "selectedStateText": [
            .en: "Selected",
            .zhHans: "已选中",
            .yue: "已選取"
        ],
        "onboardingPermissionOptionalHint": [
            .en: "Optional in first-round app shell",
            .zhHans: "首轮壳层中该权限为可选项",
            .yue: "首輪殼層中此權限屬可選"
        ],
        "onboardingAllowPermissionHint": [
            .en: "Allow alerts while exploring and continue to the map",
            .zhHans: "允许后可在探索时接收提醒，并继续进入地图",
            .yue: "允許後可喺探索時接收提醒，並繼續進入地圖"
        ],
        "onboardingSkipPermissionHint": [
            .en: "Skip permission for now and continue to the map immediately",
            .zhHans: "暂不授权，立即继续进入地图",
            .yue: "暫不授權，立即繼續進入地圖"
        ],
        "closeText": [
            .en: "Close",
            .zhHans: "关闭",
            .yue: "關閉"
        ],
        "clearText": [
            .en: "Clear",
            .zhHans: "清除",
            .yue: "清除"
        ],
        "demoNotesTitle": [
            .en: "Shell behaviors",
            .zhHans: "壳层行为",
            .yue: "殼層行為"
        ],
        "demoNotesBody": [
            .en: "Independent tab navigation state is preserved. Language changes update immediately without restart.",
            .zhHans: "各 Tab 的导航状态独立并可保留；语言切换即时生效，无需重启。",
            .yue: "各 Tab 導航狀態獨立並可保留；語言切換即時生效，無需重啟。"
        ],
        "notNowText": [
            .en: "Not Now",
            .zhHans: "暂不",
            .yue: "暫不"
        ],
        "retryText": [
            .en: "Retry",
            .zhHans: "重试",
            .yue: "重試"
        ],
        "detailsText": [
            .en: "View Details",
            .zhHans: "查看详情",
            .yue: "查看詳情"
        ]
    ]

    var appTitle: String { text("appTitle") }
    var tabArchive: String { text("tabArchive") }
    var tabMap: String { text("tabMap") }
    var tabSettings: String { text("tabSettings") }
    var onboardingLanguageTitle: String { text("onboardingLanguageTitle") }
    var onboardingLanguageBody: String { text("onboardingLanguageBody") }
    var onboardingPermissionTitle: String { text("onboardingPermissionTitle") }
    var onboardingPermissionBody: String { text("onboardingPermissionBody") }
    var continueText: String { text("continueText") }
    var allowPermission: String { text("allowPermission") }
    var skipForNow: String { text("skipForNow") }
    var onboardingStep1Of2: String { text("onboardingStep1Of2") }
    var onboardingStep2Of2: String { text("onboardingStep2Of2") }
    var selectedStateText: String { text("selectedStateText") }
    var onboardingPermissionOptionalHint: String { text("onboardingPermissionOptionalHint") }
    var onboardingAllowPermissionHint: String { text("onboardingAllowPermissionHint") }
    var onboardingSkipPermissionHint: String { text("onboardingSkipPermissionHint") }
    var closeText: String { text("closeText") }
    var clearText: String { text("clearText") }
    var demoNotesTitle: String { text("demoNotesTitle") }
    var demoNotesBody: String { text("demoNotesBody") }
    var notNowText: String { text("notNowText") }
    var retryText: String { text("retryText") }
    var detailsText: String { text("detailsText") }
}
