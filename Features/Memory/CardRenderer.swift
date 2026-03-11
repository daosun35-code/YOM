import CoreGraphics
import Foundation

enum CardRenderError: Error, Equatable {
    case invalidOutputScale(CGFloat)
    case assetMissing(String)
    case renderFailed
    case notImplemented
}

protocol CardRendererProtocol {
    func render(memory: MemoryPoint, exploredAt: Date, coverAssetName: String?, outputScale: CGFloat) throws -> URL
}

/// AI-01 scaffold only. Rendering lands in AI-03.
final class DefaultCardRenderer: CardRendererProtocol {
    func render(memory: MemoryPoint, exploredAt: Date, coverAssetName: String?, outputScale: CGFloat) throws -> URL {
        let _ = (memory, exploredAt, coverAssetName, outputScale)
        throw CardRenderError.notImplemented
    }
}
