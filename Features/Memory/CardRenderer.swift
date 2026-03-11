import CoreGraphics
import Foundation
import SwiftUI
import UIKit

enum CardRenderError: Error, Equatable {
    case invalidOutputScale(CGFloat)
    case assetMissing(String)
    case renderFailed
}

@MainActor
protocol CardRendererProtocol {
    func render(memory: MemoryPoint, exploredAt: Date, coverAssetName: String?, outputScale: CGFloat) throws -> URL
}

protocol CardAssetResolving {
    func image(named name: String) -> UIImage?
}

struct BundleCardAssetResolver: CardAssetResolving {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func image(named name: String) -> UIImage? {
        if name.isAbsoluteFilePath {
            return UIImage(contentsOfFile: name)
        }

        if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            return image
        }

        let resourceName = (name as NSString).deletingPathExtension
        let explicitExtension = (name as NSString).pathExtension.trimmedNonEmpty
        if let explicitExtension,
           let url = bundle.url(forResource: resourceName, withExtension: explicitExtension),
           let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }

        for candidateExtension in ["png", "jpg", "jpeg"] {
            if let url = bundle.url(forResource: name, withExtension: candidateExtension),
               let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }

        return nil
    }
}

typealias CardImageFactory = @MainActor (_ content: AnyView, _ size: CGSize, _ scale: CGFloat) -> UIImage?
typealias CardPNGEncoder = (_ image: UIImage) -> Data?

@MainActor
final class DefaultCardRenderer: CardRendererProtocol {
    static let canvasSize = CGSize(width: 360, height: 640)

    private let fileManager: FileManager
    private let assetResolver: any CardAssetResolving
    private let outputDirectory: URL
    private let imageFactory: CardImageFactory
    private let pngEncoder: CardPNGEncoder

    init(
        fileManager: FileManager = .default,
        assetResolver: any CardAssetResolving = BundleCardAssetResolver(),
        outputDirectory: URL? = nil,
        imageFactory: @escaping CardImageFactory = DefaultCardRenderer.makeImage,
        pngEncoder: @escaping CardPNGEncoder = { $0.pngData() }
    ) {
        self.fileManager = fileManager
        self.assetResolver = assetResolver
        self.outputDirectory = outputDirectory ?? Self.defaultOutputDirectory(fileManager: fileManager)
        self.imageFactory = imageFactory
        self.pngEncoder = pngEncoder
    }

    func render(memory: MemoryPoint, exploredAt: Date, coverAssetName: String?, outputScale: CGFloat) throws -> URL {
        guard (1 ... 3).contains(outputScale) else {
            throw CardRenderError.invalidOutputScale(outputScale)
        }

        let coverImage = try resolveCoverImage(memory: memory, coverAssetName: coverAssetName)
        let template = CardTemplateView(
            title: memory.title(in: .en),
            summary: memory.summary(in: .en),
            story: memory.story(in: .en),
            year: memory.year,
            tags: Array(memory.tags.prefix(3)),
            exploredAt: exploredAt,
            coverImage: coverImage
        )

        guard let image = imageFactory(AnyView(template), Self.canvasSize, outputScale) else {
            throw CardRenderError.renderFailed
        }

        guard let pngData = pngEncoder(image) else {
            throw CardRenderError.renderFailed
        }

        do {
            try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
            let outputURL = makeOutputURL(memoryID: memory.id, exploredAt: exploredAt)
            try pngData.write(to: outputURL, options: .atomic)
            return outputURL
        } catch {
            throw CardRenderError.renderFailed
        }
    }

    private func resolveCoverImage(memory: MemoryPoint, coverAssetName: String?) throws -> UIImage? {
        guard let assetName = resolvedCoverAssetName(memory: memory, coverAssetName: coverAssetName) else {
            return nil
        }

        guard let image = assetResolver.image(named: assetName) else {
            throw CardRenderError.assetMissing(assetName)
        }
        return image
    }

    private func resolvedCoverAssetName(memory: MemoryPoint, coverAssetName: String?) -> String? {
        if let coverAssetName = coverAssetName?.trimmedNonEmpty {
            return coverAssetName
        }

        guard let imageMedia = memory.media.first(where: { $0.type == .image }) else {
            return nil
        }

        if let thumbnailAssetName = imageMedia.thumbnailAssetName?.trimmedNonEmpty {
            return thumbnailAssetName
        }

        return imageMedia.localAssetName.trimmedNonEmpty
    }

    private func makeOutputURL(memoryID: UUID, exploredAt: Date) -> URL {
        outputDirectory.appending(path: "memory-card-\(memoryID.uuidString)-\(Int(exploredAt.timeIntervalSince1970)).png")
    }

    private static func defaultOutputDirectory(fileManager: FileManager) -> URL {
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseDirectory.appending(path: "GeneratedMemoryCards", directoryHint: .isDirectory)
    }

    private static func makeImage(content: AnyView, size: CGSize, scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: content.frame(width: size.width, height: size.height))
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = scale
        return renderer.uiImage
    }
}

private struct CardTemplateView: View {
    let title: String
    let summary: String
    let story: String
    let year: Int
    let tags: [String]
    let exploredAt: Date
    let coverImage: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.95, blue: 0.88), Color(red: 0.92, green: 0.87, blue: 0.74)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .padding(24)

            VStack(alignment: .leading, spacing: 18) {
                header
                cover
                summaryBlock
                footer
            }
            .padding(40)
        }
        .frame(width: DefaultCardRenderer.canvasSize.width, height: DefaultCardRenderer.canvasSize.height)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Community Memory")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.7))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(year)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.34, green: 0.20, blue: 0.12))

                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.black.opacity(0.92))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 12)
            }
        }
    }

    private var cover: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.78, green: 0.66, blue: 0.53))

            if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(red: 0.46, green: 0.28, blue: 0.19), Color(red: 0.78, green: 0.66, blue: 0.53)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 32, weight: .semibold))
                    Text("Awaiting local archival image")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.white.opacity(0.92))
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            if tags.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 0.34, green: 0.20, blue: 0.12))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.82), in: Capsule())
                        }
                    }
                }
            }

            Text(summary)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(Color.black.opacity(0.82))
                .lineLimit(4)

            if story.isEmpty == false {
                Text(story)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.68))
                    .lineLimit(5)
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .overlay(Color.black.opacity(0.14))

            Text("Archived \(exploredAt.formatted(.dateTime.year().month(.abbreviated).day()))")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.56))

            Text("Generated locally on device")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.46))
        }
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var isAbsoluteFilePath: Bool {
        hasPrefix("/")
    }
}
