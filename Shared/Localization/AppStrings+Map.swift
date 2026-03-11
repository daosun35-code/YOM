import Foundation

extension AppStrings {
    static let mapTranslations: AppTranslationTable = [
        "mapTitle": [
            .en: "Map",
            .zhHans: "地图",
            .yue: "地圖"
        ],
        "searchPrompt": [
            .en: "Search places",
            .zhHans: "搜索地点",
            .yue: "搜尋地點"
        ],
        "searchInputHint": [
            .en: "Try a landmark name or street",
            .zhHans: "可输入地标名称或街道",
            .yue: "可輸入地標名稱或街道"
        ],
        "searchRecommendations": [
            .en: "Recommendations",
            .zhHans: "推荐",
            .yue: "推薦"
        ],
        "searchRecents": [
            .en: "Recent Searches",
            .zhHans: "最近搜索",
            .yue: "最近搜尋"
        ],
        "searchNoRecents": [
            .en: "No recent searches yet",
            .zhHans: "暂无最近搜索",
            .yue: "暫無最近搜尋"
        ],
        "locateMe": [
            .en: "Locate Me",
            .zhHans: "定位我",
            .yue: "定位我"
        ],
        "goText": [
            .en: "Go",
            .zhHans: "前往",
            .yue: "前往"
        ],
        "changeDestination": [
            .en: "Change Destination",
            .zhHans: "更改目的地",
            .yue: "更改目的地"
        ],
        "searchResultFallbackTitle": [
            .en: "Search Result",
            .zhHans: "搜索结果",
            .yue: "搜尋結果"
        ],
        "navigationActive": [
            .en: "Navigation Active",
            .zhHans: "导航进行中",
            .yue: "導航進行中"
        ],
        "navigationInlineCardTitle": [
            .en: "Current Trip",
            .zhHans: "当前行程",
            .yue: "目前行程"
        ],
        "navigationInlineNextActionLabel": [
            .en: "Next Action",
            .zhHans: "下一动作",
            .yue: "下一步"
        ],
        "navigationInlineNextActionPlaceholder": [
            .en: "Step details will appear after route sync.",
            .zhHans: "路线同步后将显示下一步。",
            .yue: "路線同步後會顯示下一步。"
        ],
        "navigationInlineExpandDetailAction": [
            .en: "Open Full Details",
            .zhHans: "展开完整详情",
            .yue: "展開完整詳情"
        ],
        "navigationInlineCollapseAction": [
            .en: "Collapse trip card",
            .zhHans: "收起行程卡片",
            .yue: "收起行程卡片"
        ],
        "navigationInlineValuePlaceholder": [
            .en: "--",
            .zhHans: "--",
            .yue: "--"
        ],
        "navigationTaskInfoTitle": [
            .en: "Navigation Task",
            .zhHans: "导航任务信息",
            .yue: "導航任務資訊"
        ],
        "navigationTaskETALabel": [
            .en: "ETA",
            .zhHans: "预计到达",
            .yue: "預計到達"
        ],
        "navigationTaskDistanceLabel": [
            .en: "Distance",
            .zhHans: "距离",
            .yue: "距離"
        ],
        "navigationTaskStatusLabel": [
            .en: "Status",
            .zhHans: "状态",
            .yue: "狀態"
        ],
        "navigationTaskStatusReady": [
            .en: "Ready",
            .zhHans: "已就绪",
            .yue: "已就緒"
        ],
        "navigationTaskStatusPending": [
            .en: "Pending",
            .zhHans: "待开始",
            .yue: "待開始"
        ],
        "endNavigation": [
            .en: "End",
            .zhHans: "结束",
            .yue: "結束"
        ],
        "routeLoading": [
            .en: "Calculating route...",
            .zhHans: "正在计算路线...",
            .yue: "正在計算路線..."
        ],
        "routeUnavailable": [
            .en: "Route unavailable",
            .zhHans: "暂无可用路线",
            .yue: "暫無可用路線"
        ],
        "routeFailedRetry": [
            .en: "Route update failed. Tap Retry to try again.",
            .zhHans: "路线更新失败，请点击“重试”。",
            .yue: "路線更新失敗，請點擊「重試」。"
        ],
        "searchNoResultsTitle": [
            .en: "No Results Found",
            .zhHans: "未找到结果",
            .yue: "未找到結果"
        ],
        "searchNoResultsBody": [
            .en: "Try another keyword or pick a recommendation.",
            .zhHans: "请尝试其他关键词，或选择推荐地点。",
            .yue: "請嘗試其他關鍵詞，或選擇推薦地點。"
        ],
        "locationPermissionTitle": [
            .en: "Location Access Needed",
            .zhHans: "需要位置权限",
            .yue: "需要位置權限"
        ],
        "locationPermissionBody": [
            .en: "Enable location access in Settings to use Locate Me and route guidance.",
            .zhHans: "请在设置中启用定位权限，以使用“定位我”和路线导航。",
            .yue: "請在設定啟用定位權限，以使用「定位我」同路線導航。"
        ],
        "openSettingsText": [
            .en: "Open Settings",
            .zhHans: "打开设置",
            .yue: "打開設定"
        ]
    ]

    var mapTitle: String { text("mapTitle") }
    var searchPrompt: String { text("searchPrompt") }
    var searchInputHint: String { text("searchInputHint") }
    var searchRecommendations: String { text("searchRecommendations") }
    var searchRecents: String { text("searchRecents") }
    var searchNoRecents: String { text("searchNoRecents") }
    var locateMe: String { text("locateMe") }
    var goText: String { text("goText") }
    var changeDestination: String { text("changeDestination") }
    var searchResultFallbackTitle: String { text("searchResultFallbackTitle") }
    var navigationActive: String { text("navigationActive") }
    var navigationInlineCardTitle: String { text("navigationInlineCardTitle") }
    var navigationInlineNextActionLabel: String { text("navigationInlineNextActionLabel") }
    var navigationInlineNextActionPlaceholder: String { text("navigationInlineNextActionPlaceholder") }
    var navigationInlineExpandDetailAction: String { text("navigationInlineExpandDetailAction") }
    var navigationInlineCollapseAction: String { text("navigationInlineCollapseAction") }
    var navigationInlineValuePlaceholder: String { text("navigationInlineValuePlaceholder") }
    var navigationTaskInfoTitle: String { text("navigationTaskInfoTitle") }
    var navigationTaskETALabel: String { text("navigationTaskETALabel") }
    var navigationTaskDistanceLabel: String { text("navigationTaskDistanceLabel") }
    var navigationTaskStatusLabel: String { text("navigationTaskStatusLabel") }
    var navigationTaskStatusReady: String { text("navigationTaskStatusReady") }
    var navigationTaskStatusPending: String { text("navigationTaskStatusPending") }
    var endNavigation: String { text("endNavigation") }
    var routeLoading: String { text("routeLoading") }
    var routeUnavailable: String { text("routeUnavailable") }
    var routeFailedRetry: String { text("routeFailedRetry") }
    var searchNoResultsTitle: String { text("searchNoResultsTitle") }
    var searchNoResultsBody: String { text("searchNoResultsBody") }
    var locationPermissionTitle: String { text("locationPermissionTitle") }
    var locationPermissionBody: String { text("locationPermissionBody") }
    var openSettingsText: String { text("openSettingsText") }
}
