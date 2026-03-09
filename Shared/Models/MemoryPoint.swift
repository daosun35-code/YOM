import CoreLocation
import Foundation

struct MemoryPoint: Identifiable, Hashable {
    let poi: PointOfInterest
    let storyByLanguage: [AppLanguage: String]
    let unlockRadiusM: Double
    let tags: [String]
    let media: [MemoryMedia]

    var id: UUID { poi.id }
    var year: Int { poi.year }
    var coordinate: CLLocationCoordinate2D { poi.coordinate }

    func title(in language: AppLanguage) -> String {
        poi.title(in: language)
    }

    func summary(in language: AppLanguage) -> String {
        poi.summary(in: language)
    }

    func story(in language: AppLanguage) -> String {
        storyByLanguage[language] ?? storyByLanguage[.en] ?? ""
    }

    func distanceText(in language: AppLanguage) -> String {
        poi.distanceText(in: language)
    }

    static func == (lhs: MemoryPoint, rhs: MemoryPoint) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
