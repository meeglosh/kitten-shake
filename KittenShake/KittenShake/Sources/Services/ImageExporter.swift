import UIKit

/// Flattens the square background photo and all kitten sprites into a
/// single high-resolution image, ready to save or share. Rendered with
/// `UIGraphicsImageRenderer` (not a view screenshot) so quality is
/// consistent regardless of device/screen scale.
enum ImageExporter {
    static func renderFlattenedImage(
        background: UIImage,
        sprites: [KittenSprite],
        kittenImage: (String) -> UIImage?,
        minimumSide: CGFloat = 2048,
        includeWatermark: Bool = true
    ) -> UIImage {
        let sourceSide = min(background.size.width, background.size.height)
        let side = max(minimumSide, sourceSide)
        let canvasSize = CGSize(width: side, height: side)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return renderer.image { context in
            background.draw(in: CGRect(origin: .zero, size: canvasSize))

            for sprite in sprites {
                guard let image = kittenImage(sprite.imageName) else { continue }

                // Aspect-fit the kitten image inside a square box, matching
                // the editor's `.aspectRatio(contentMode: .fit)` on a
                // `canvasSide * defaultSizeFraction` square frame.
                let box = side * KittenSprite.defaultSizeFraction * sprite.scale
                let aspect = image.size.height / max(image.size.width, 1)
                let width: CGFloat
                let height: CGFloat
                if aspect <= 1 {
                    // Wider than tall (or square): width fills the box.
                    width = box
                    height = box * aspect
                } else {
                    // Taller than wide: height fills the box.
                    height = box
                    width = box / aspect
                }

                let center = CGPoint(
                    x: sprite.normalizedPosition.x * side,
                    y: sprite.normalizedPosition.y * side
                )

                context.cgContext.saveGState()
                context.cgContext.translateBy(x: center.x, y: center.y)
                context.cgContext.rotate(by: CGFloat(sprite.rotation.radians))
                let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
                image.draw(in: rect)
                context.cgContext.restoreGState()
            }

            if includeWatermark {
                drawWatermark(in: context.cgContext, canvasSide: side)
            }
        }
    }

    /// Draws the small "Kitten Shake" watermark in the bottom-right corner
    /// of exported images only (never shown in the live editor preview).
    /// Simple white text with a soft shadow, sized relative to the export
    /// resolution so it looks consistent at any output size.
    private static func drawWatermark(in cgContext: CGContext, canvasSide: CGFloat) {
        let fontSize = canvasSide * 0.045
        guard let font = UIFont(name: "FreckleFace-Regular", size: fontSize) else { return }

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.55)
        shadow.shadowBlurRadius = fontSize * 0.12
        shadow.shadowOffset = CGSize(width: 0, height: fontSize * 0.04)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .shadow: shadow
        ]

        let text = "Kitten Shake"
        let textSize = text.size(withAttributes: attributes)
        let margin = canvasSide * 0.03
        let origin = CGPoint(
            x: canvasSide - textSize.width - margin,
            y: canvasSide - textSize.height - margin
        )

        text.draw(at: origin, withAttributes: attributes)
    }
}
