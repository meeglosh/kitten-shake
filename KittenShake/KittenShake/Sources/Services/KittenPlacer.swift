import UIKit
import Vision

/// Computes an on-device placement for a freshly generated AI kitten so it
/// lands somewhere sensible on the user's photo instead of dead center.
/// Heuristic (in priority order):
///   1. Detected face → place at "shoulder height", just below and beside
///      the face, never over it.
///   2. No face, but a salient region → hug the edge of that region.
///   3. Neither → lower-third center, a safe default that rarely collides
///      with a subject's face in typical portrait-ish photos.
/// Classic (non-AI) kittens are unaffected — `EditorView` only calls this
/// for AI-generated sprites.
enum KittenPlacer {
    struct Placement {
        let normalizedPosition: CGPoint
        let scale: CGFloat
    }

    /// Target kitten width as a fraction of the canvas side. Expressed as a
    /// `KittenSprite.scale` multiplier since sprites render at
    /// `KittenSprite.defaultSizeFraction * scale`.
    static let sizeFraction: CGFloat = 0.35
    static var scaleForTargetSize: CGFloat { sizeFraction / KittenSprite.defaultSizeFraction }

    static func computePlacement(for image: UIImage) async -> Placement {
        guard let cgImage = image.cgImage else { return fallback() }

        let faceRequest = VNDetectFaceRectanglesRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation(image.imageOrientation))

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([faceRequest, saliencyRequest])
                } catch {
                    continuation.resume(returning: fallback())
                    return
                }

                if let face = faceRequest.results?.first {
                    continuation.resume(returning: placement(besideFace: face.boundingBox))
                    return
                }

                if let saliencyResult = saliencyRequest.results?.first,
                   let topRegion = saliencyResult.salientObjects?.first {
                    continuation.resume(returning: placement(atEdgeOf: topRegion.boundingBox))
                    return
                }

                continuation.resume(returning: fallback())
            }
        }
    }

    /// `boundingBox` is in Vision's normalized, bottom-left-origin space.
    private static func placement(besideFace boundingBox: CGRect) -> Placement {
        let faceCenterX = boundingBox.midX
        let faceBottomY = 1 - boundingBox.minY // top-left-origin Y of the face's chin.
        let faceWidth = boundingBox.width

        // Prefer whichever side has more room, so the kitten stays on-canvas.
        let side: CGFloat = faceCenterX <= 0.5 ? 1 : -1
        let x = clamp(faceCenterX + side * (faceWidth * 0.6 + 0.22), 0.2, 0.8)
        let y = clamp(faceBottomY + 0.22, 0.42, 0.88)
        return Placement(normalizedPosition: CGPoint(x: x, y: y), scale: scaleForTargetSize)
    }

    private static func placement(atEdgeOf boundingBox: CGRect) -> Placement {
        let x = clamp(boundingBox.minX, 0.15, 0.85)
        let y = clamp(1 - boundingBox.minY, 0.4, 0.9)
        return Placement(normalizedPosition: CGPoint(x: x, y: y), scale: scaleForTargetSize)
    }

    private static func fallback() -> Placement {
        Placement(normalizedPosition: CGPoint(x: 0.5, y: 0.78), scale: scaleForTargetSize)
    }

    private static func clamp(_ value: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        min(max(value, lo), hi)
    }

    private static func cgOrientation(_ orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
