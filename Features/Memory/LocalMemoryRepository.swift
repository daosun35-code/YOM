import CoreLocation
import Foundation

/// Loads memory points from a local Bundle JSON file.
/// Acts as the single source of truth for memory data in the local-first architecture.
@MainActor
final class LocalMemoryRepository: ObservableObject {
    @Published private(set) var memoryPoints: [MemoryPoint] = []
    private var pointsByID: [UUID: MemoryPoint] = [:]

    init() {
        loadFromBundle()
    }

    func memoryPoint(by id: UUID) -> MemoryPoint? {
        pointsByID[id]
    }

    /// All underlying `PointOfInterest` values for map pin rendering.
    var allPOIs: [PointOfInterest] {
        memoryPoints.map(\.poi)
    }

    static func bundleMemoryPointIDs(bundle: Bundle = .main) -> Set<UUID> {
        Set(loadMemoryPoints(bundle: bundle).map(\.id))
    }

    // MARK: - Private

    private func loadFromBundle() {
        let points = Self.loadMemoryPoints(bundle: .main)
        self.memoryPoints = points
        self.pointsByID = Dictionary(uniqueKeysWithValues: points.map { ($0.id, $0) })
    }

    private static func loadMemoryPoints(bundle: Bundle) -> [MemoryPoint] {
        guard let url = bundle.url(forResource: "memories", withExtension: "json") else {
            print("[LocalMemoryRepository] ⚠️ memories.json not found in Bundle – running with empty data")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(MemoriesPayload.self, from: data)
            return decoded.memoryPoints.map { $0.toMemoryPoint() }
        } catch {
            print("[LocalMemoryRepository] ⚠️ Failed to decode memories.json: \(error)")
            return []
        }
    }
}

// MARK: - JSON Decoding Models

private struct MemoriesPayload: Codable {
    let memoryPoints: [MemoryPointDTO]
}

private struct MemoryPointDTO: Codable {
    let id: UUID
    let year: Int
    let latitude: Double
    let longitude: Double
    let distanceMeters: Int
    let nameByLanguage: [String: String]
    let summaryByLanguage: [String: String]
    let storyByLanguage: [String: String]
    let unlockRadiusM: Double
    let tags: [String]
    let media: [MemoryMediaDTO]

    func toMemoryPoint() -> MemoryPoint {
        let poi = PointOfInterest(
            id: id,
            year: year,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            distanceMeters: distanceMeters,
            nameByLanguage: mapLanguageDict(nameByLanguage),
            summaryByLanguage: mapLanguageDict(summaryByLanguage)
        )

        let memoryMedia = media.map { dto in
            MemoryMedia(
                id: dto.id,
                memoryPointId: id,
                type: MemoryMedia.MediaType(rawValue: dto.type) ?? .image,
                localAssetName: dto.localAssetName,
                duration: dto.duration,
                thumbnailAssetName: dto.thumbnailAssetName
            )
        }

        return MemoryPoint(
            poi: poi,
            storyByLanguage: mapLanguageDict(storyByLanguage),
            unlockRadiusM: unlockRadiusM,
            tags: tags,
            media: memoryMedia
        )
    }

    private func mapLanguageDict(_ dict: [String: String]) -> [AppLanguage: String] {
        var result: [AppLanguage: String] = [:]
        for (key, value) in dict {
            if let lang = AppLanguage(rawValue: key) {
                result[lang] = value
            }
        }
        return result
    }
}

private struct MemoryMediaDTO: Codable {
    let id: UUID
    let type: String
    let localAssetName: String
    let duration: TimeInterval?
    let thumbnailAssetName: String?
}
