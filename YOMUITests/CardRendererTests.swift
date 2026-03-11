import CoreLocation
import UIKit
import XCTest

@MainActor
final class CardRendererTests: XCTestCase {
    func testRenderWritesPNGToSandbox() throws {
        let renderer = DefaultCardRenderer(
            assetResolver: TestAssetResolver(images: ["cover": makeImage(color: .systemBlue)]),
            outputDirectory: makeOutputDirectory()
        )

        let outputURL = try renderer.render(
            memory: makeMemoryPoint(imageAssetName: nil),
            exploredAt: fixedDate,
            coverAssetName: "cover",
            outputScale: 3
        )

        XCTAssertEqual(outputURL.pathExtension, "png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        let data = try Data(contentsOf: outputURL)
        XCTAssertTrue(data.starts(with: [0x89, 0x50, 0x4E, 0x47]))

        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(image.size.width, 1_080, accuracy: 1)
        XCTAssertEqual(image.size.height, 1_920, accuracy: 1)
    }

    func testRenderFallsBackToMemoryImageMediaWhenCoverAssetNameIsNil() throws {
        let assetResolver = TestAssetResolver(images: ["fallback-cover": makeImage(color: .systemGreen)])
        let renderer = DefaultCardRenderer(
            assetResolver: assetResolver,
            outputDirectory: makeOutputDirectory()
        )

        let outputURL = try renderer.render(
            memory: makeMemoryPoint(imageAssetName: "fallback-cover"),
            exploredAt: fixedDate,
            coverAssetName: nil,
            outputScale: 2
        )

        XCTAssertEqual(assetResolver.requestedNames, ["fallback-cover"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testRenderRejectsUnsupportedOutputScale() {
        let renderer = DefaultCardRenderer(
            assetResolver: TestAssetResolver(images: [:]),
            outputDirectory: makeOutputDirectory()
        )

        XCTAssertThrowsError(
            try renderer.render(
                memory: makeMemoryPoint(imageAssetName: nil),
                exploredAt: fixedDate,
                coverAssetName: nil,
                outputScale: 0.5
            )
        ) { error in
            XCTAssertEqual(error as? CardRenderError, .invalidOutputScale(0.5))
        }
    }

    func testRenderThrowsAssetMissingWhenCoverImageCannotBeResolved() {
        let renderer = DefaultCardRenderer(
            assetResolver: TestAssetResolver(images: [:]),
            outputDirectory: makeOutputDirectory()
        )

        XCTAssertThrowsError(
            try renderer.render(
                memory: makeMemoryPoint(imageAssetName: nil),
                exploredAt: fixedDate,
                coverAssetName: "missing-cover",
                outputScale: 1
            )
        ) { error in
            XCTAssertEqual(error as? CardRenderError, .assetMissing("missing-cover"))
        }
    }

    func testRenderThrowsRenderFailedWhenImageFactoryReturnsNil() {
        let renderer = DefaultCardRenderer(
            assetResolver: TestAssetResolver(images: [:]),
            outputDirectory: makeOutputDirectory(),
            imageFactory: { _, _, _ in nil }
        )

        XCTAssertThrowsError(
            try renderer.render(
                memory: makeMemoryPoint(imageAssetName: nil),
                exploredAt: fixedDate,
                coverAssetName: nil,
                outputScale: 1
            )
        ) { error in
            XCTAssertEqual(error as? CardRenderError, .renderFailed)
        }
    }

    private var fixedDate: Date {
        Date(timeIntervalSince1970: 1_731_110_400)
    }

    private func makeOutputDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 180))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 240, height: 180)))
        }
    }

    private func makeMemoryPoint(imageAssetName: String?) -> MemoryPoint {
        let pointOfInterest = PointOfInterest(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
            year: 1935,
            coordinate: CLLocationCoordinate2D(latitude: 40.7143, longitude: -74.0060),
            distanceMeters: 120,
            nameByLanguage: [.en: "Market Street Corner"],
            summaryByLanguage: [.en: "A busy intersection where neighborhood merchants and labor organizers crossed paths."]
        )

        let media = imageAssetName.map {
            [
                MemoryMedia(
                    id: UUID(),
                    memoryPointId: pointOfInterest.id,
                    type: .image,
                    localAssetName: $0,
                    duration: nil,
                    thumbnailAssetName: nil
                )
            ]
        } ?? []

        return MemoryPoint(
            poi: pointOfInterest,
            storyByLanguage: [.en: "Residents remembered the corner as an improvised message board for arrivals seeking work and community."],
            unlockRadiusM: 80,
            tags: ["Chinatown", "Mutual Aid", "Streetscape"],
            media: media
        )
    }
}

private final class TestAssetResolver: CardAssetResolving {
    private let images: [String: UIImage]
    private(set) var requestedNames: [String] = []

    init(images: [String: UIImage]) {
        self.images = images
    }

    func image(named name: String) -> UIImage? {
        requestedNames.append(name)
        return images[name]
    }
}
