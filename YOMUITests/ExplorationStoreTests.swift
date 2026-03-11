import XCTest
import SwiftData

@MainActor
final class ExplorationStoreTests: XCTestCase {
    func testUpsertArchivePersistsAcrossStoreRecreation() throws {
        let memoryPointId = UUID()
        let storeURL = makeStoreURL()
        let exploredAt = Date(timeIntervalSince1970: 1_731_110_400)

        let firstStore = try makeStore(storeURL: storeURL, validIDs: [memoryPointId])
        let savedRecord = try firstStore.upsertArchive(
            memoryPointId: memoryPointId,
            source: .active,
            exploredAt: exploredAt,
            cardLocalPath: "cards/\(memoryPointId.uuidString).png"
        )

        let secondStore = try makeStore(storeURL: storeURL, validIDs: [memoryPointId])
        let fetchedRecord = try XCTUnwrap(secondStore.fetchRecord(memoryPointId: memoryPointId))

        XCTAssertEqual(fetchedRecord, savedRecord)
        XCTAssertEqual(try secondStore.fetchAllRecords(), [savedRecord])
        XCTAssertTrue(try secondStore.isArchived(memoryPointId: memoryPointId))
    }

    func testUpsertArchiveIsIdempotentAndUpdatesExistingRecord() throws {
        let memoryPointId = UUID()
        let store = try makeInMemoryStore(validIDs: [memoryPointId])

        let originalRecord = try store.upsertArchive(
            memoryPointId: memoryPointId,
            source: .active,
            exploredAt: Date(timeIntervalSince1970: 1_731_110_400),
            cardLocalPath: "cards/original.png"
        )

        let updatedRecord = try store.upsertArchive(
            memoryPointId: memoryPointId,
            source: .passive,
            exploredAt: Date(timeIntervalSince1970: 1_731_114_000),
            cardLocalPath: "cards/updated.png"
        )

        XCTAssertEqual(updatedRecord.id, originalRecord.id)
        XCTAssertEqual(updatedRecord.memoryPointId, memoryPointId)
        XCTAssertEqual(updatedRecord.source, .passive)
        XCTAssertEqual(updatedRecord.cardLocalPath, "cards/updated.png")
        XCTAssertEqual(updatedRecord.exploredAt, Date(timeIntervalSince1970: 1_731_114_000))
        XCTAssertEqual(try store.fetchAllRecords(), [updatedRecord])
    }

    func testUpsertArchiveRejectsUnknownMemoryPointID() throws {
        let memoryPointId = UUID()
        let store = try makeInMemoryStore(validIDs: [])

        XCTAssertThrowsError(
            try store.upsertArchive(
                memoryPointId: memoryPointId,
                source: .active,
                exploredAt: Date(),
                cardLocalPath: nil
            )
        ) { error in
            XCTAssertEqual(error as? ExplorationStoreError, .invalidMemoryPointID(memoryPointId))
        }
    }

    func testFetchAllRecordsThrowsEncodingFailedForMalformedStoredRecord() throws {
        let memoryPointId = UUID()
        let container = try makeContainer(isStoredInMemoryOnly: true, storeURL: nil)
        let context = container.mainContext

        let malformedRecord = ExplorationStoreSchemaV1.StoredExplorationRecord(
            id: UUID(),
            memoryPointId: memoryPointId,
            exploredAt: Date(timeIntervalSince1970: 1_731_110_400),
            sourceRawValue: "corrupted-source",
            cardLocalPath: nil
        )
        context.insert(malformedRecord)
        try context.save()

        let store = try SwiftDataExplorationStore(
            modelContainer: container,
            validMemoryPointIDs: { [memoryPointId] }
        )

        XCTAssertThrowsError(try store.fetchAllRecords()) { error in
            XCTAssertEqual(error as? ExplorationStoreError, .encodingFailed)
        }
    }

    private func makeInMemoryStore(validIDs: Set<UUID>) throws -> SwiftDataExplorationStore {
        let container = try makeContainer(isStoredInMemoryOnly: true, storeURL: nil)
        return try SwiftDataExplorationStore(modelContainer: container, validMemoryPointIDs: { validIDs })
    }

    private func makeStore(storeURL: URL, validIDs: Set<UUID>) throws -> SwiftDataExplorationStore {
        try SwiftDataExplorationStore(storeURL: storeURL, validMemoryPointIDs: { validIDs })
    }

    private func makeContainer(isStoredInMemoryOnly: Bool, storeURL: URL?) throws -> ModelContainer {
        if let storeURL {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }

        let configuration: ModelConfiguration
        if isStoredInMemoryOnly {
            configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        } else if let storeURL {
            configuration = ModelConfiguration(url: storeURL)
        } else {
            configuration = ModelConfiguration()
        }

        return try ModelContainer(
            for: ExplorationStoreSchemaV1.StoredExplorationRecord.self,
            configurations: configuration
        )
    }

    private func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            .appending(path: "ExplorationStore.sqlite")
    }
}
