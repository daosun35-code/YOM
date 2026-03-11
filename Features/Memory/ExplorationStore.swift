import Foundation
import Photos
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

struct ArchivedMemoryEntry: Identifiable, Hashable {
    let memoryPoint: MemoryPoint
    let record: ExplorationRecord

    var id: UUID { memoryPoint.id }
    var cardURL: URL? { record.cardLocalPath.map(URL.init(fileURLWithPath:)) }
}

enum MemoryArchiveCoordinatorError: Error {
    case archiveUnavailable
    case missingGeneratedCard
    case cardRenderFailed
    case photoLibraryDenied
    case photoSaveFailed
}

protocol PhotoLibraryCardSaving {
    func saveImage(at fileURL: URL) async throws
}

struct SystemPhotoLibraryCardSaver: PhotoLibraryCardSaving {
    func saveImage(at fileURL: URL) async throws {
        let authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw MemoryArchiveCoordinatorError.photoLibraryDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                guard PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL) != nil else {
                    return
                }
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard success else {
                    continuation.resume(throwing: MemoryArchiveCoordinatorError.photoSaveFailed)
                    return
                }

                continuation.resume(returning: ())
            })
        }
    }
}

@MainActor
final class MemoryArchiveCoordinator: ObservableObject {
    @Published private(set) var records: [ExplorationRecord] = []

    private let explorationStore: any ExplorationStoreProtocol
    private let cardRenderer: any CardRendererProtocol
    private let photoSaver: any PhotoLibraryCardSaving
    private let now: () -> Date

    init(
        explorationStore: (any ExplorationStoreProtocol)? = nil,
        cardRenderer: (any CardRendererProtocol)? = nil,
        photoSaver: any PhotoLibraryCardSaving = SystemPhotoLibraryCardSaver(),
        now: @escaping () -> Date = Date.init
    ) {
        self.explorationStore = explorationStore ?? Self.makeDefaultExplorationStore()
        self.cardRenderer = cardRenderer ?? DefaultCardRenderer()
        self.photoSaver = photoSaver
        self.now = now
        refreshRecords()
    }

    func archiveEntries(memoryPointLookup: (UUID) -> MemoryPoint?) -> [ArchivedMemoryEntry] {
        records.compactMap { record in
            guard let memoryPoint = memoryPointLookup(record.memoryPointId) else {
                return nil
            }
            return ArchivedMemoryEntry(memoryPoint: memoryPoint, record: record)
        }
    }

    func record(for memoryPointID: UUID) -> ExplorationRecord? {
        records.first { $0.memoryPointId == memoryPointID }
    }

    @discardableResult
    func completeExperience(for memoryPoint: MemoryPoint, source: ExplorationSource = .active) throws -> ExplorationRecord {
        try completeExperience(for: memoryPoint, source: source, exploredAt: now())
    }

    func seedArchiveSample(using memoryPoints: [MemoryPoint], sampleCount: Int = 2) {
        let samplePoints = Array(memoryPoints.prefix(sampleCount))
        guard samplePoints.isEmpty == false else { return }

        let baseTimestamp = 1_741_715_200.0
        for (index, memoryPoint) in samplePoints.enumerated() {
            let exploredAt = Date(timeIntervalSince1970: baseTimestamp - Double(index))
            _ = try? completeExperience(for: memoryPoint, source: .active, exploredAt: exploredAt)
        }
    }

    func saveCardToPhotos(memoryPointID: UUID) async throws {
        guard let record = record(for: memoryPointID),
              let cardLocalPath = record.cardLocalPath else {
            throw MemoryArchiveCoordinatorError.missingGeneratedCard
        }

        let fileURL = URL(fileURLWithPath: cardLocalPath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw MemoryArchiveCoordinatorError.missingGeneratedCard
        }

        do {
            try await photoSaver.saveImage(at: fileURL)
        } catch let error as MemoryArchiveCoordinatorError {
            throw error
        } catch {
            throw MemoryArchiveCoordinatorError.photoSaveFailed
        }
    }

    static func resetPersistentStore(fileManager: FileManager = .default) {
        let storeURL = persistentStoreURL(fileManager: fileManager)
        let sidecarURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in sidecarURLs where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }

    private func refreshRecords() {
        do {
            records = try explorationStore.fetchAllRecords()
        } catch {
            records = []
        }
    }

    @discardableResult
    private func completeExperience(
        for memoryPoint: MemoryPoint,
        source: ExplorationSource,
        exploredAt: Date
    ) throws -> ExplorationRecord {
        let cardURL = try renderArchiveCard(for: memoryPoint, exploredAt: exploredAt)

        do {
            let record = try explorationStore.upsertArchive(
                memoryPointId: memoryPoint.id,
                source: source,
                exploredAt: exploredAt,
                cardLocalPath: cardURL.path
            )
            refreshRecords()
            return record
        } catch {
            throw MemoryArchiveCoordinatorError.archiveUnavailable
        }
    }

    private func renderArchiveCard(for memoryPoint: MemoryPoint, exploredAt: Date) throws -> URL {
        do {
            return try cardRenderer.render(
                memory: memoryPoint,
                exploredAt: exploredAt,
                coverAssetName: nil,
                outputScale: 2
            )
        } catch CardRenderError.assetMissing {
            let fallbackMemory = MemoryPoint(
                poi: memoryPoint.poi,
                storyByLanguage: memoryPoint.storyByLanguage,
                unlockRadiusM: memoryPoint.unlockRadiusM,
                tags: memoryPoint.tags,
                media: memoryPoint.media.filter { $0.type != .image }
            )

            do {
                return try cardRenderer.render(
                    memory: fallbackMemory,
                    exploredAt: exploredAt,
                    coverAssetName: nil,
                    outputScale: 2
                )
            } catch {
                throw MemoryArchiveCoordinatorError.cardRenderFailed
            }
        } catch {
            throw MemoryArchiveCoordinatorError.cardRenderFailed
        }
    }

    private static func makeDefaultExplorationStore() -> any ExplorationStoreProtocol {
        do {
            return try SwiftDataExplorationStore(
                storeURL: persistentStoreURL(),
                validMemoryPointIDs: { loadBundleMemoryPointIDs() }
            )
        } catch {
            return UnavailableExplorationStore()
        }
    }

    private static func persistentStoreURL(fileManager: FileManager = .default) -> URL {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseDirectory
            .appending(path: "CommunityMemory", directoryHint: .isDirectory)
            .appending(path: "ExplorationStore.sqlite")
    }

    private static func loadBundleMemoryPointIDs(bundle: Bundle = .main) -> Set<UUID> {
        guard let url = bundle.url(forResource: "memories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let memoryPoints = payload["memoryPoints"] as? [[String: Any]] else {
            return []
        }

        return Set(
            memoryPoints.compactMap { item in
                guard let rawID = item["id"] as? String else { return nil }
                return UUID(uuidString: rawID)
            }
        )
    }
}

@MainActor
private final class UnavailableExplorationStore: ExplorationStoreProtocol {
    func upsertArchive(memoryPointId: UUID, source: ExplorationSource, exploredAt: Date, cardLocalPath: String?) throws
        -> ExplorationRecord {
        throw ExplorationStoreError.storageUnavailable
    }

    func fetchAllRecords() throws -> [ExplorationRecord] {
        throw ExplorationStoreError.storageUnavailable
    }

    func fetchRecord(memoryPointId: UUID) throws -> ExplorationRecord? {
        throw ExplorationStoreError.storageUnavailable
    }

    func isArchived(memoryPointId: UUID) throws -> Bool {
        throw ExplorationStoreError.storageUnavailable
    }
}
