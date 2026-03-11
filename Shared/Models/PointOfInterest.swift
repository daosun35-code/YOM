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
