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
        case .en: return "Allow Notifications and Open Map"
        case .zhHans: return "允许通知并进入地图"
        case .yue: return "允許通知並進入地圖"
        }
    }

    var skipForNow: String {
        switch language {
        case .en: return "Open Map Without Notifications"
        case .zhHans: return "暂不授权，直接进入地图"
        case .yue: return "暫不授權，直接進入地圖"
        }
    }

    var onboardingStep1Of2: String {
        switch language {
        case .en: return "Step 1 of 2"
        case .zhHans: return "第 1 步，共 2 步"
        case .yue: return "第 1 步，共 2 步"
        }
    }

    var onboardingStep2Of2: String {
        switch language {
        case .en: return "Step 2 of 2"
        case .zhHans: return "第 2 步，共 2 步"
        case .yue: return "第 2 步，共 2 步"
        }
    }

    var selectedStateText: String {
        switch language {
        case .en: return "Selected"
        case .zhHans: return "已选中"
        case .yue: return "已選取"
        }
    }

    var onboardingPermissionOptionalHint: String {
        switch language {
        case .en: return "Optional in first-round app shell"
        case .zhHans: return "首轮壳层中该权限为可选项"
        case .yue: return "首輪殼層中此權限屬可選"
        }
    }

    var onboardingAllowPermissionHint: String {
        switch language {
        case .en: return "Allow alerts while exploring and continue to the map"
        case .zhHans: return "允许后可在探索时接收提醒，并继续进入地图"
        case .yue: return "允許後可喺探索時接收提醒，並繼續進入地圖"
        }
    }

    var onboardingSkipPermissionHint: String {
        switch language {
        case .en: return "Skip permission for now and continue to the map immediately"
        case .zhHans: return "暂不授权，立即继续进入地图"
        case .yue: return "暫不授權，立即繼續進入地圖"
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

    var searchInputHint: String {
        switch language {
        case .en: return "Try a landmark name or street"
        case .zhHans: return "可输入地标名称或街道"
        case .yue: return "可輸入地標名稱或街道"
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

    var changeDestinationHint: String {
        switch language {
        case .en: return "This will replace your current destination and recalculate the route."
        case .zhHans: return "此操作会替换当前目的地，并重新计算路线。"
        case .yue: return "此操作會取代目前目的地，並重新計算路線。"
        }
    }

    var detailsText: String {
        switch language {
        case .en: return "Details"
        case .zhHans: return "详情"
        case .yue: return "詳情"
        }
    }

    var openNavigationDetailsHint: String {
        switch language {
        case .en: return "Open navigation details"
        case .zhHans: return "打开导航详情"
        case .yue: return "打開導航詳情"
        }
    }

    var searchResultFallbackTitle: String {
        switch language {
        case .en: return "Search Result"
        case .zhHans: return "搜索结果"
        case .yue: return "搜尋結果"
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

    var endNavigationConfirmTitle: String {
        switch language {
        case .en: return "End navigation?"
        case .zhHans: return "确认结束导航？"
        case .yue: return "確認結束導航？"
        }
    }

    var endNavigationConfirmBody: String {
        switch language {
        case .en: return "Your active route will be cleared."
        case .zhHans: return "当前导航路线将被清除。"
        case .yue: return "目前導航路線將被清除。"
        }
    }

    var endNavigationConfirmAction: String {
        switch language {
        case .en: return "End Navigation"
        case .zhHans: return "结束导航"
        case .yue: return "結束導航"
        }
    }

    var routeLoading: String {
        switch language {
        case .en: return "Calculating route..."
        case .zhHans: return "正在计算路线..."
        case .yue: return "正在計算路線..."
        }
    }

    var routeUnavailable: String {
        switch language {
        case .en: return "Route unavailable"
        case .zhHans: return "暂无可用路线"
        case .yue: return "暫無可用路線"
        }
    }

    var routeFailedRetry: String {
        switch language {
        case .en: return "Route update failed, retrying when location changes"
        case .zhHans: return "路线更新失败，定位变化后将重试"
        case .yue: return "路線更新失敗，定位變化後會重試"
        }
    }

    var retryText: String {
        switch language {
        case .en: return "Retry"
        case .zhHans: return "重试"
        case .yue: return "重試"
        }
    }

    var searchNoResultsTitle: String {
        switch language {
        case .en: return "No Results Found"
        case .zhHans: return "未找到结果"
        case .yue: return "未找到結果"
        }
    }

    var searchNoResultsBody: String {
        switch language {
        case .en: return "Try another keyword or pick a recommendation."
        case .zhHans: return "请尝试其他关键词，或选择推荐地点。"
        case .yue: return "請嘗試其他關鍵詞，或選擇推薦地點。"
        }
    }

    var locationPermissionTitle: String {
        switch language {
        case .en: return "Location Access Needed"
        case .zhHans: return "需要位置权限"
        case .yue: return "需要位置權限"
        }
    }

    var locationPermissionBody: String {
        switch language {
        case .en: return "Enable location access in Settings to use Locate Me and route guidance."
        case .zhHans: return "请在设置中启用定位权限，以使用“定位我”和路线导航。"
        case .yue: return "請在設定啟用定位權限，以使用「定位我」同路線導航。"
        }
    }

    var openSettingsText: String {
        switch language {
        case .en: return "Open Settings"
        case .zhHans: return "打开设置"
        case .yue: return "打開設定"
        }
    }

    var notNowText: String {
        switch language {
        case .en: return "Not Now"
        case .zhHans: return "暂不"
        case .yue: return "暫不"
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

    var archiveListSectionTitle: String {
        switch language {
        case .en: return "Memory Timeline"
        case .zhHans: return "记忆时间线"
        case .yue: return "記憶時間線"
        }
    }

    var archiveSubmenuTitle: String {
        switch language {
        case .en: return "Archive Filter"
        case .zhHans: return "档案筛选"
        case .yue: return "檔案篩選"
        }
    }

    var archiveSubmenuExplored: String {
        switch language {
        case .en: return "Explored"
        case .zhHans: return "已探索"
        case .yue: return "已探索"
        }
    }

    var archiveSubmenuFavorites: String {
        switch language {
        case .en: return "Favorites"
        case .zhHans: return "收藏"
        case .yue: return "收藏"
        }
    }

    var archiveExploredSectionTitle: String {
        switch language {
        case .en: return "Explored Timeline"
        case .zhHans: return "已探索时间线"
        case .yue: return "已探索時間線"
        }
    }

    var archiveFavoritesSectionTitle: String {
        switch language {
        case .en: return "Saved Favorites"
        case .zhHans: return "已收藏"
        case .yue: return "已收藏"
        }
    }

    var archiveFavoriteTag: String {
        switch language {
        case .en: return "Favorite"
        case .zhHans: return "已收藏"
        case .yue: return "已收藏"
        }
    }

    var archiveEmptyStateTitle: String {
        switch language {
        case .en: return "No favorites yet"
        case .zhHans: return "暂无收藏"
        case .yue: return "暫無收藏"
        }
    }

    var archiveEmptyStateBody: String {
        switch language {
        case .en: return "Save meaningful moments to quickly revisit them."
        case .zhHans: return "把重要记忆加入收藏后，可在这里快速回看。"
        case .yue: return "將重要記憶加入收藏後，可以喺呢度快速重溫。"
        }
    }

    func archiveSectionTitle(base: String, count: Int) -> String {
        switch language {
        case .en: return "\(base) · \(count)"
        case .zhHans: return "\(base)（\(count)）"
        case .yue: return "\(base)（\(count)）"
        }
    }

    var archiveOpenRetrievalText: String {
        switch language {
        case .en: return "Open Retrieval"
        case .zhHans: return "进入提取页"
        case .yue: return "進入提取頁"
        }
    }

    var archiveOpenRetrievalHint: String {
        switch language {
        case .en: return "Open this archive card in the retrieval page"
        case .zhHans: return "打开该档案卡片的记忆提取页"
        case .yue: return "打開此檔案卡片嘅記憶提取頁"
        }
    }

    var archiveItemUnavailable: String {
        switch language {
        case .en: return "This archive item is no longer available."
        case .zhHans: return "该档案条目当前不可用。"
        case .yue: return "此檔案項目目前不可用。"
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

    var betaSection: String {
        switch language {
        case .en: return "Beta"
        case .zhHans: return "Beta"
        case .yue: return "Beta"
        }
    }

    var betaReturnToOnboardingText: String {
        switch language {
        case .en: return "Return to Onboarding (Beta Only)"
        case .zhHans: return "返回引导页（Beta Only）"
        case .yue: return "返回引導頁（Beta Only）"
        }
    }

    var betaReturnToOnboardingHint: String {
        switch language {
        case .en: return "Reset onboarding completion and show the onboarding flow again"
        case .zhHans: return "重置引导完成状态，并重新展示引导流程"
        case .yue: return "重設引導完成狀態，並重新顯示引導流程"
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

    var clearText: String {
        switch language {
        case .en: return "Clear"
        case .zhHans: return "清除"
        case .yue: return "清除"
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
