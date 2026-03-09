import Foundation

struct MemoryMedia: Identifiable, Hashable, Codable {
    let id: UUID
    let memoryPointId: UUID
    let type: MediaType
    let localAssetName: String
    let duration: TimeInterval?
    let thumbnailAssetName: String?

    enum MediaType: String, Codable, CaseIterable {
        case image
        case audio
        case video
        case ar
    }
}
