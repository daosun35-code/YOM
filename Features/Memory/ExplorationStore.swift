import Foundation
import SwiftData

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

@MainActor
protocol ExplorationStoreProtocol {
    func upsertArchive(memoryPointId: UUID, source: ExplorationSource, exploredAt: Date, cardLocalPath: String?) throws
        -> ExplorationRecord
    func fetchAllRecords() throws -> [ExplorationRecord]
    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord?
    func isArchived(memoryPointId: UUID) throws -> Bool
}

enum ExplorationStoreSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [StoredExplorationRecord.self]
    }

    @Model
    final class StoredExplorationRecord {
        var id: UUID
        @Attribute(.unique) var memoryPointId: UUID
        var exploredAt: Date
        var sourceRawValue: String
        var cardLocalPath: String?

        init(
            id: UUID,
            memoryPointId: UUID,
            exploredAt: Date,
            sourceRawValue: String,
            cardLocalPath: String?
        ) {
            self.id = id
            self.memoryPointId = memoryPointId
            self.exploredAt = exploredAt
            self.sourceRawValue = sourceRawValue
            self.cardLocalPath = cardLocalPath
        }

        convenience init(record: ExplorationRecord) {
            self.init(
                id: record.id,
                memoryPointId: record.memoryPointId,
                exploredAt: record.exploredAt,
                sourceRawValue: record.source.rawValue,
                cardLocalPath: record.cardLocalPath
            )
        }
    }
}

@MainActor
protocol ExplorationStoreBacking {
    func upsert(record: ExplorationRecord) throws -> ExplorationRecord
    func fetchAllRecords() throws -> [ExplorationRecord]
    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord?
}

@MainActor
final class SwiftDataExplorationStore: ExplorationStoreProtocol {
    private let modelContainer: ModelContainer?
    private let backing: any ExplorationStoreBacking
    private let validMemoryPointIDs: () -> Set<UUID>

    init(
        modelContainer: ModelContainer? = nil,
        storeURL: URL? = nil,
        validMemoryPointIDs: @escaping () -> Set<UUID>
    ) throws {
        let resolvedContainer: ModelContainer
        if let modelContainer {
            resolvedContainer = modelContainer
        } else {
            resolvedContainer = try Self.makeModelContainer(storeURL: storeURL)
        }

        self.modelContainer = resolvedContainer
        self.backing = SwiftDataExplorationStoreBacking(modelContext: resolvedContainer.mainContext)
        self.validMemoryPointIDs = validMemoryPointIDs
    }

    init(backing: any ExplorationStoreBacking, validMemoryPointIDs: @escaping () -> Set<UUID>) {
        self.modelContainer = nil
        self.backing = backing
        self.validMemoryPointIDs = validMemoryPointIDs
    }

    func upsertArchive(memoryPointId: UUID, source: ExplorationSource, exploredAt: Date, cardLocalPath: String?) throws
        -> ExplorationRecord {
        guard validMemoryPointIDs().contains(memoryPointId) else {
            throw ExplorationStoreError.invalidMemoryPointID(memoryPointId)
        }

        if let existingRecord = try backing.fetchRecord(memoryPointId: memoryPointId) {
            let updatedRecord = ExplorationRecord(
                id: existingRecord.id,
                memoryPointId: memoryPointId,
                source: source,
                exploredAt: exploredAt,
                cardLocalPath: cardLocalPath
            )
            return try backing.upsert(record: updatedRecord)
        }

        let newRecord = ExplorationRecord(
            memoryPointId: memoryPointId,
            source: source,
            exploredAt: exploredAt,
            cardLocalPath: cardLocalPath
        )
        return try backing.upsert(record: newRecord)
    }

    func fetchAllRecords() throws -> [ExplorationRecord] {
        try backing.fetchAllRecords()
    }

    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord? {
        try backing.fetchRecord(memoryPointId: memoryPointId)
    }

    func isArchived(memoryPointId: UUID) throws -> Bool {
        try fetchRecord(memoryPointId: memoryPointId) != nil
    }

    private static func makeModelContainer(storeURL: URL?) throws -> ModelContainer {
        if let storeURL {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let configuration = ModelConfiguration(url: storeURL)
            return try ModelContainer(
                for: ExplorationStoreSchemaV1.StoredExplorationRecord.self,
                configurations: configuration
            )
        }

        let configuration = ModelConfiguration()
        return try ModelContainer(
            for: ExplorationStoreSchemaV1.StoredExplorationRecord.self,
            configurations: configuration
        )
    }
}

@MainActor
private final class SwiftDataExplorationStoreBacking: ExplorationStoreBacking {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func upsert(record: ExplorationRecord) throws -> ExplorationRecord {
        if let existingRecord = try fetchEntity(memoryPointId: record.memoryPointId) {
            existingRecord.exploredAt = record.exploredAt
            existingRecord.sourceRawValue = record.source.rawValue
            existingRecord.cardLocalPath = record.cardLocalPath
            try saveContext()
            return try map(existingRecord)
        }

        let insertedRecord = ExplorationStoreSchemaV1.StoredExplorationRecord(record: record)
        modelContext.insert(insertedRecord)
        try saveContext()
        return try map(insertedRecord)
    }

    func fetchAllRecords() throws -> [ExplorationRecord] {
        let descriptor = FetchDescriptor<ExplorationStoreSchemaV1.StoredExplorationRecord>(
            sortBy: [
                SortDescriptor(\.exploredAt, order: .reverse),
                SortDescriptor(\.memoryPointId)
            ]
        )

        do {
            return try modelContext.fetch(descriptor).map(map)
        } catch let error as ExplorationStoreError {
            throw error
        } catch {
            throw ExplorationStoreError.storageUnavailable
        }
    }

    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord? {
        do {
            return try fetchEntity(memoryPointId: memoryPointId).map(map)
        } catch let error as ExplorationStoreError {
            throw error
        } catch {
            throw ExplorationStoreError.storageUnavailable
        }
    }

    private func fetchEntity(memoryPointId: UUID) throws -> ExplorationStoreSchemaV1.StoredExplorationRecord? {
        let descriptor = FetchDescriptor<ExplorationStoreSchemaV1.StoredExplorationRecord>(
            predicate: #Predicate { record in
                record.memoryPointId == memoryPointId
            }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw ExplorationStoreError.storageUnavailable
        }
    }

    private func saveContext() throws {
        do {
            try modelContext.save()
        } catch {
            throw ExplorationStoreError.storageUnavailable
        }
    }

    private func map(_ record: ExplorationStoreSchemaV1.StoredExplorationRecord) throws -> ExplorationRecord {
        guard let source = ExplorationSource(rawValue: record.sourceRawValue) else {
            throw ExplorationStoreError.encodingFailed
        }

        return ExplorationRecord(
            id: record.id,
            memoryPointId: record.memoryPointId,
            source: source,
            exploredAt: record.exploredAt,
            cardLocalPath: record.cardLocalPath
        )
    }
}
