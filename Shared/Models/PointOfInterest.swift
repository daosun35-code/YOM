import CoreLocation
import Foundation

struct PointOfInterest: Identifiable, Hashable {
    let id: UUID
    let year: Int
    let coordinate: CLLocationCoordinate2D
    let distanceMeters: Int
    private let nameByLanguage: [AppLanguage: String]
    private let summaryByLanguage: [AppLanguage: String]

    init(
        id: UUID = UUID(),
        year: Int,
        coordinate: CLLocationCoordinate2D,
        distanceMeters: Int,
        nameByLanguage: [AppLanguage: String],
        summaryByLanguage: [AppLanguage: String]
    ) {
        self.id = id
        self.year = year
        self.coordinate = coordinate
        self.distanceMeters = distanceMeters
        self.nameByLanguage = nameByLanguage
        self.summaryByLanguage = summaryByLanguage
    }

    func title(in language: AppLanguage) -> String {
        nameByLanguage[language] ?? nameByLanguage[.en] ?? "Untitled"
    }

    func summary(in language: AppLanguage) -> String {
        summaryByLanguage[language] ?? summaryByLanguage[.en] ?? ""
    }

    func distanceText(in language: AppLanguage) -> String {
        if language == .en {
            let feet = Int((Double(distanceMeters) * 3.28084).rounded())
            if feet >= 5280 {
                let miles = Double(feet) / 5280.0
                return String(format: "%.1f mi", miles)
            }
            return "\(feet) ft"
        }

        if distanceMeters >= 1000 {
            let km = Double(distanceMeters) / 1000.0
            return String(format: "%.1f km", km)
        }
        return "\(distanceMeters) m"
    }

    func accessibilityLabel(in language: AppLanguage) -> String {
        "\(year), \(title(in: language)), \(distanceText(in: language))"
    }

    static func == (lhs: PointOfInterest, rhs: PointOfInterest) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension PointOfInterest {
    static let samples: [PointOfInterest] = [
        PointOfInterest(
            year: 1935,
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            distanceMeters: 240,
            nameByLanguage: [
                .en: "Market Street Corner",
                .zhHans: "市场街街角",
                .yue: "市場街街角"
            ],
            summaryByLanguage: [
                .en: "A storefront photo and oral story from a busy tram stop.",
                .zhHans: "一张有轨电车站旁店铺照片与口述故事。",
                .yue: "一張電車站旁店舖相片同口述故事。"
            ]
        ),
        PointOfInterest(
            year: 1947,
            coordinate: CLLocationCoordinate2D(latitude: 37.7793, longitude: -122.4184),
            distanceMeters: 540,
            nameByLanguage: [
                .en: "Civic Hall Steps",
                .zhHans: "市政厅台阶",
                .yue: "市政廳台階"
            ],
            summaryByLanguage: [
                .en: "Community gathering memories recorded after the war.",
                .zhHans: "战后社区集会的记忆记录。",
                .yue: "戰後社區聚會嘅記憶紀錄。"
            ]
        ),
        PointOfInterest(
            year: 1962,
            coordinate: CLLocationCoordinate2D(latitude: 37.7694, longitude: -122.4862),
            distanceMeters: 1600,
            nameByLanguage: [
                .en: "Ocean View Playfield",
                .zhHans: "海景游乐场",
                .yue: "海景遊樂場"
            ],
            summaryByLanguage: [
                .en: "Family snapshots and a neighborhood radio clip.",
                .zhHans: "家庭照片与一段街区广播录音。",
                .yue: "家庭相片同一段社區廣播錄音。"
            ]
        )
    ]
}
