import Foundation

enum ExplorationSource: String, Codable, CaseIterable, Hashable {
    case active
    case passive
}

struct ExplorationRecord: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let memoryPointId: UUID
    let exploredAt: Date
    let source: ExplorationSource
    let cardLocalPath: String?

    init(
        id: UUID = UUID(),
        memoryPointId: UUID,
        source: ExplorationSource,
        exploredAt: Date,
        cardLocalPath: String?
    ) {
        self.id = id
        self.memoryPointId = memoryPointId
        self.source = source
        self.exploredAt = exploredAt
        self.cardLocalPath = cardLocalPath
    }
}

enum ExplorationStoreError: Error, Equatable {
    case invalidMemoryPointID(UUID)
    case storageUnavailable
    case encodingFailed
    case notImplemented
}

protocol ExplorationStoreProtocol {
    func upsertArchive(memoryPointId: UUID, source: ExplorationSource, exploredAt: Date, cardLocalPath: String?) throws
        -> ExplorationRecord
    func fetchAllRecords() throws -> [ExplorationRecord]
    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord?
    func isArchived(memoryPointId: UUID) throws -> Bool
}

/// AI-01 scaffold only. Persistence lands in AI-02.
final class SwiftDataExplorationStore: ExplorationStoreProtocol {
    func upsertArchive(memoryPointId: UUID, source: ExplorationSource, exploredAt: Date, cardLocalPath: String?) throws
        -> ExplorationRecord {
        let _ = (memoryPointId, source, exploredAt, cardLocalPath)
        throw ExplorationStoreError.notImplemented
    }

    func fetchAllRecords() throws -> [ExplorationRecord] {
        throw ExplorationStoreError.notImplemented
    }

    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord? {
        let _ = memoryPointId
        throw ExplorationStoreError.notImplemented
    }

    func isArchived(memoryPointId: UUID) throws -> Bool {
        let _ = memoryPointId
        throw ExplorationStoreError.notImplemented
    }
}
