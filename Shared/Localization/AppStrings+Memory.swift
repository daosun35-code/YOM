import Foundation

extension AppStrings {
    static let memoryTranslations: AppTranslationTable = [
        "retrievalTitle": [
            .en: "Retrieval",
            .zhHans: "记忆提取",
            .yue: "記憶提取"
        ],
        "retrievalModeStatic": [
            .en: "Static mode (first-round shell placeholder)",
            .zhHans: "静态模式（首轮壳层占位）",
            .yue: "靜態模式（首輪殼層占位）"
        ],
        "memoryDetailTitle": [
            .en: "Memory Detail",
            .zhHans: "记忆详情",
            .yue: "記憶詳情"
        ],
        "memoryDetailStorySection": [
            .en: "Story",
            .zhHans: "故事",
            .yue: "故事"
        ],
        "memoryDetailMediaSection": [
            .en: "Media",
            .zhHans: "媒体资料",
            .yue: "媒體資料"
        ],
        "memoryMediaComingSoon": [
            .en: "Coming Soon",
            .zhHans: "即将支持",
            .yue: "即將支援"
        ],
        "memoryExperienceComplete": [
            .en: "Complete Experience",
            .zhHans: "完成体验",
            .yue: "完成體驗"
        ],
        "memoryMediaTypeImage": [
            .en: "Image",
            .zhHans: "图片",
            .yue: "圖片"
        ],
        "memoryMediaTypeAudio": [
            .en: "Audio",
            .zhHans: "音频",
            .yue: "音訊"
        ],
        "memoryMediaTypeVideo": [
            .en: "Video",
            .zhHans: "视频",
            .yue: "影片"
        ],
        "memoryMediaTypeAR": [
            .en: "AR",
            .zhHans: "AR",
            .yue: "AR"
        ]
    ]

    var retrievalTitle: String { text("retrievalTitle") }
    var retrievalModeStatic: String { text("retrievalModeStatic") }
    var memoryDetailTitle: String { text("memoryDetailTitle") }
    var memoryDetailStorySection: String { text("memoryDetailStorySection") }
    var memoryDetailMediaSection: String { text("memoryDetailMediaSection") }
    var memoryMediaComingSoon: String { text("memoryMediaComingSoon") }
    var memoryExperienceComplete: String { text("memoryExperienceComplete") }
    var memoryMediaTypeImage: String { text("memoryMediaTypeImage") }
    var memoryMediaTypeAudio: String { text("memoryMediaTypeAudio") }
    var memoryMediaTypeVideo: String { text("memoryMediaTypeVideo") }
    var memoryMediaTypeAR: String { text("memoryMediaTypeAR") }
}
