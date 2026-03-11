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
        "archiveEmptyStateTitle": [
            .en: "No favorites yet",
            .zhHans: "暂无收藏",
            .yue: "暫無收藏"
        ],
        "archiveEmptyStateBody": [
            .en: "Save meaningful moments to quickly revisit them.",
            .zhHans: "把重要记忆加入收藏后，可在这里快速回看。",
            .yue: "將重要記憶加入收藏後，可以喺呢度快速重溫。"
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
        ]
    ]

    var archiveTitle: String { text("archiveTitle") }
    var archiveSubmenuTitle: String { text("archiveSubmenuTitle") }
    var archiveSubmenuExplored: String { text("archiveSubmenuExplored") }
    var archiveSubmenuFavorites: String { text("archiveSubmenuFavorites") }
    var archiveExploredSectionTitle: String { text("archiveExploredSectionTitle") }
    var archiveFavoritesSectionTitle: String { text("archiveFavoritesSectionTitle") }
    var archiveFavoriteTag: String { text("archiveFavoriteTag") }
    var archiveEmptyStateTitle: String { text("archiveEmptyStateTitle") }
    var archiveEmptyStateBody: String { text("archiveEmptyStateBody") }
    var archiveOpenRetrievalText: String { text("archiveOpenRetrievalText") }
    var archiveOpenRetrievalHint: String { text("archiveOpenRetrievalHint") }
    var archiveItemUnavailable: String { text("archiveItemUnavailable") }
}
