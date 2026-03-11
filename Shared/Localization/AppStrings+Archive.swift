import Foundation

extension AppStrings {
    static let archiveTranslations: AppTranslationTable = [
        "archiveTitle": [
            .en: "Archive",
            .zhHans: "档案库",
            .yue: "檔案庫"
        ],
        "archiveSubmenuTitle": [
            .en: "Archive Filter",
            .zhHans: "档案筛选",
            .yue: "檔案篩選"
        ],
        "archiveSubmenuExplored": [
            .en: "Explored",
            .zhHans: "已探索",
            .yue: "已探索"
        ],
        "archiveSubmenuFavorites": [
            .en: "Favorites",
            .zhHans: "收藏",
            .yue: "收藏"
        ],
        "archiveExploredSectionTitle": [
            .en: "Explored Timeline",
            .zhHans: "已探索时间线",
            .yue: "已探索時間線"
        ],
        "archiveFavoritesSectionTitle": [
            .en: "Saved Favorites",
            .zhHans: "已收藏",
            .yue: "已收藏"
        ],
        "archiveFavoriteTag": [
            .en: "Favorite",
            .zhHans: "已收藏",
            .yue: "已收藏"
        ],
        "archiveEmptyExploredTitle": [
            .en: "No archived memories yet",
            .zhHans: "暂无归档记忆",
            .yue: "暫無歸檔記憶"
        ],
        "archiveEmptyExploredBody": [
            .en: "Complete a memory experience to store it here for later revisits.",
            .zhHans: "完成一次记忆体验后，就会在这里留下可回看的归档。",
            .yue: "完成一次記憶體驗之後，就會喺呢度留下可以重溫嘅歸檔。"
        ],
        "archiveEmptyFavoritesTitle": [
            .en: "No favorites yet",
            .zhHans: "暂无收藏",
            .yue: "暫無收藏"
        ],
        "archiveEmptyFavoritesBody": [
            .en: "Favorite archived memories will stay pinned here.",
            .zhHans: "被标记为收藏的归档记忆会固定显示在这里。",
            .yue: "被標記為收藏嘅歸檔記憶會固定顯示喺呢度。"
        ],
        "archiveOpenRetrievalText": [
            .en: "Open Retrieval",
            .zhHans: "进入提取页",
            .yue: "進入提取頁"
        ],
        "archiveOpenRetrievalHint": [
            .en: "Open this archive card in the retrieval page",
            .zhHans: "打开该档案卡片的记忆提取页",
            .yue: "打開此檔案卡片嘅記憶提取頁"
        ],
        "archiveItemUnavailable": [
            .en: "This archive item is no longer available.",
            .zhHans: "该档案条目当前不可用。",
            .yue: "此檔案項目目前不可用。"
        ],
        "archiveShareCard": [
            .en: "Share Card",
            .zhHans: "分享卡片",
            .yue: "分享卡片"
        ],
        "archiveSaveCard": [
            .en: "Save to Photos",
            .zhHans: "保存到相册",
            .yue: "儲存到相簿"
        ],
        "archiveSaveSuccessTitle": [
            .en: "Saved to Photos",
            .zhHans: "已保存到相册",
            .yue: "已儲存到相簿"
        ],
        "archiveSaveSuccessBody": [
            .en: "The generated memory card is now in your photo library.",
            .zhHans: "生成的记忆卡片已经保存到你的相册。",
            .yue: "生成嘅記憶卡片已經儲存到你嘅相簿。"
        ],
        "archiveActionErrorTitle": [
            .en: "Archive Action Unavailable",
            .zhHans: "档案操作暂不可用",
            .yue: "檔案操作暫時不可用"
        ],
        "archiveCardUnavailable": [
            .en: "This memory card isn't ready yet. Complete the experience again to regenerate it.",
            .zhHans: "这张记忆卡片暂未生成，请重新完成体验后再试。",
            .yue: "呢張記憶卡片暫時未生成，請重新完成體驗後再試。"
        ],
        "archivePhotoAccessDeniedBody": [
            .en: "Allow photo access before saving generated memory cards.",
            .zhHans: "请先允许相册写入权限，再保存生成的记忆卡片。",
            .yue: "請先允許相簿寫入權限，再儲存生成嘅記憶卡片。"
        ],
        "archiveSaveFailedBody": [
            .en: "We couldn't save the generated memory card to Photos.",
            .zhHans: "暂时无法把生成的记忆卡片保存到相册。",
            .yue: "暫時無法將生成嘅記憶卡片儲存到相簿。"
        ],
        "archiveCompleteFailedBody": [
            .en: "We couldn't archive this memory right now. Try again in a moment.",
            .zhHans: "当前无法归档这段记忆，请稍后再试。",
            .yue: "目前無法歸檔呢段記憶，請稍後再試。"
        ],
        "archiveActionGenericFailureBody": [
            .en: "The requested archive action couldn't be completed right now.",
            .zhHans: "当前无法完成该档案操作。",
            .yue: "目前無法完成此檔案操作。"
        ],
        "archiveArchivedOn": [
            .en: "Archived %@",
            .zhHans: "归档于 %@",
            .yue: "歸檔於 %@"
        ]
    ]

    var archiveTitle: String { text("archiveTitle") }
    var archiveSubmenuTitle: String { text("archiveSubmenuTitle") }
    var archiveSubmenuExplored: String { text("archiveSubmenuExplored") }
    var archiveSubmenuFavorites: String { text("archiveSubmenuFavorites") }
    var archiveExploredSectionTitle: String { text("archiveExploredSectionTitle") }
    var archiveFavoritesSectionTitle: String { text("archiveFavoritesSectionTitle") }
    var archiveFavoriteTag: String { text("archiveFavoriteTag") }
    var archiveEmptyExploredTitle: String { text("archiveEmptyExploredTitle") }
    var archiveEmptyExploredBody: String { text("archiveEmptyExploredBody") }
    var archiveEmptyFavoritesTitle: String { text("archiveEmptyFavoritesTitle") }
    var archiveEmptyFavoritesBody: String { text("archiveEmptyFavoritesBody") }
    var archiveOpenRetrievalText: String { text("archiveOpenRetrievalText") }
    var archiveOpenRetrievalHint: String { text("archiveOpenRetrievalHint") }
    var archiveItemUnavailable: String { text("archiveItemUnavailable") }
    var archiveShareCard: String { text("archiveShareCard") }
    var archiveSaveCard: String { text("archiveSaveCard") }
    var archiveSaveSuccessTitle: String { text("archiveSaveSuccessTitle") }
    var archiveSaveSuccessBody: String { text("archiveSaveSuccessBody") }
    var archiveActionErrorTitle: String { text("archiveActionErrorTitle") }
    var archiveCardUnavailable: String { text("archiveCardUnavailable") }
    var archivePhotoAccessDeniedBody: String { text("archivePhotoAccessDeniedBody") }
    var archiveSaveFailedBody: String { text("archiveSaveFailedBody") }
    var archiveCompleteFailedBody: String { text("archiveCompleteFailedBody") }
    var archiveActionGenericFailureBody: String { text("archiveActionGenericFailureBody") }

    func archiveArchivedOn(_ dateText: String) -> String {
        String(format: text("archiveArchivedOn"), dateText)
    }
}
