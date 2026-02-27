import Foundation

struct AppStrings {
    let language: AppLanguage

    var appTitle: String {
        switch language {
        case .en: return "YOM"
        case .zhHans: return "YOM 记忆地图"
        case .yue: return "YOM 記憶地圖"
        }
    }

    var tabArchive: String {
        switch language {
        case .en: return "Archive"
        case .zhHans: return "档案"
        case .yue: return "檔案"
        }
    }

    var tabMap: String {
        switch language {
        case .en: return "Map"
        case .zhHans: return "地图"
        case .yue: return "地圖"
        }
    }

    var tabSettings: String {
        switch language {
        case .en: return "Settings"
        case .zhHans: return "设置"
        case .yue: return "設定"
        }
    }

    var onboardingLanguageTitle: String {
        switch language {
        case .en: return "Choose your language"
        case .zhHans: return "选择语言"
        case .yue: return "選擇語言"
        }
    }

    var onboardingLanguageBody: String {
        switch language {
        case .en: return "You can change this anytime in Settings. Changes apply instantly."
        case .zhHans: return "你可以稍后在设置中修改，切换后会立即生效。"
        case .yue: return "你可以之後喺設定更改，切換會即時生效。"
        }
    }

    var onboardingPermissionTitle: String {
        switch language {
        case .en: return "Stay updated while walking"
        case .zhHans: return "步行探索时保持提醒"
        case .yue: return "步行探索時保持提醒"
        }
    }

    var onboardingPermissionBody: String {
        switch language {
        case .en: return "Push permission is optional and does not block map access in the first round shell."
        case .zhHans: return "推送权限为可选项，首轮壳层实现中不会阻止进入地图。"
        case .yue: return "推送權限屬可選，首輪殼層實作唔會阻止進入地圖。"
        }
    }

    var continueText: String {
        switch language {
        case .en: return "Continue"
        case .zhHans: return "继续"
        case .yue: return "繼續"
        }
    }

    var allowPermission: String {
        switch language {
        case .en: return "Allow Notifications"
        case .zhHans: return "允许通知"
        case .yue: return "允許通知"
        }
    }

    var skipForNow: String {
        switch language {
        case .en: return "Not Now"
        case .zhHans: return "暂不"
        case .yue: return "暫不"
        }
    }

    var mapTitle: String {
        switch language {
        case .en: return "Map"
        case .zhHans: return "地图"
        case .yue: return "地圖"
        }
    }

    var searchPrompt: String {
        switch language {
        case .en: return "Search places"
        case .zhHans: return "搜索地点"
        case .yue: return "搜尋地點"
        }
    }

    var searchRecommendations: String {
        switch language {
        case .en: return "Recommendations"
        case .zhHans: return "推荐"
        case .yue: return "推薦"
        }
    }

    var searchRecents: String {
        switch language {
        case .en: return "Recent Searches"
        case .zhHans: return "最近搜索"
        case .yue: return "最近搜尋"
        }
    }

    var searchNoRecents: String {
        switch language {
        case .en: return "No recent searches yet"
        case .zhHans: return "暂无最近搜索"
        case .yue: return "暫無最近搜尋"
        }
    }

    var locateMe: String {
        switch language {
        case .en: return "Locate Me"
        case .zhHans: return "定位我"
        case .yue: return "定位我"
        }
    }

    var goText: String {
        switch language {
        case .en: return "Go"
        case .zhHans: return "前往"
        case .yue: return "前往"
        }
    }

    var changeDestination: String {
        switch language {
        case .en: return "Change Destination"
        case .zhHans: return "更改目的地"
        case .yue: return "更改目的地"
        }
    }

    var detailsText: String {
        switch language {
        case .en: return "Details"
        case .zhHans: return "详情"
        case .yue: return "詳情"
        }
    }

    var navigationActive: String {
        switch language {
        case .en: return "Navigation Active"
        case .zhHans: return "导航进行中"
        case .yue: return "導航進行中"
        }
    }

    var endNavigation: String {
        switch language {
        case .en: return "End"
        case .zhHans: return "结束"
        case .yue: return "結束"
        }
    }

    var archiveTitle: String {
        switch language {
        case .en: return "Archive"
        case .zhHans: return "档案库"
        case .yue: return "檔案庫"
        }
    }

    var archiveSubtitle: String {
        switch language {
        case .en: return "Tap a card to open a retrieval page (shell placeholder)."
        case .zhHans: return "点击卡片进入记忆提取页（壳层占位）。"
        case .yue: return "點擊卡片進入記憶提取頁（殼層占位）。"
        }
    }

    var settingsTitle: String {
        switch language {
        case .en: return "Settings"
        case .zhHans: return "设置"
        case .yue: return "設定"
        }
    }

    var languageSection: String {
        switch language {
        case .en: return "Language"
        case .zhHans: return "语言"
        case .yue: return "語言"
        }
    }

    var navigationSection: String {
        switch language {
        case .en: return "Navigation"
        case .zhHans: return "导航"
        case .yue: return "導航"
        }
    }

    var aboutText: String {
        switch language {
        case .en: return "About"
        case .zhHans: return "关于"
        case .yue: return "關於"
        }
    }

    var aboutBody: String {
        switch language {
        case .en: return "First-round App Shell built with SwiftUI system containers: TabView, NavigationStack, and sheet presentations."
        case .zhHans: return "首轮 App Shell 使用 SwiftUI 系统容器实现：TabView、NavigationStack 与 sheet。"
        case .yue: return "首輪 App Shell 使用 SwiftUI 系統容器實作：TabView、NavigationStack 同 sheet。"
        }
    }

    var retrievalTitle: String {
        switch language {
        case .en: return "Retrieval"
        case .zhHans: return "记忆提取"
        case .yue: return "記憶提取"
        }
    }

    var retrievalModeStatic: String {
        switch language {
        case .en: return "Static mode (first-round shell placeholder)"
        case .zhHans: return "静态模式（首轮壳层占位）"
        case .yue: return "靜態模式（首輪殼層占位）"
        }
    }

    var closeText: String {
        switch language {
        case .en: return "Close"
        case .zhHans: return "关闭"
        case .yue: return "關閉"
        }
    }

    var demoNotesTitle: String {
        switch language {
        case .en: return "Shell behaviors"
        case .zhHans: return "壳层行为"
        case .yue: return "殼層行為"
        }
    }

    var demoNotesBody: String {
        switch language {
        case .en: return "Independent tab navigation state is preserved. Language changes update immediately without restart."
        case .zhHans: return "各 Tab 的导航状态独立并可保留；语言切换即时生效，无需重启。"
        case .yue: return "各 Tab 導航狀態獨立並可保留；語言切換即時生效，無需重啟。"
        }
    }
}
