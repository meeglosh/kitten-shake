import SwiftUI

/// A single kitten placed on the editor canvas: which cutout it uses, and
/// its transform (position/scale/rotation) expressed in normalized canvas
/// coordinates so it renders identically on screen and in the exported image.
struct KittenSprite: Identifiable, Equatable {
    let id: UUID
    var imageName: String
    /// Center of the kitten, normalized to the square canvas (0...1 on both axes).
    var normalizedPosition: CGPoint
    var scale: CGFloat
    var rotation: Angle

    init(
        id: UUID = UUID(),
        imageName: String,
        normalizedPosition: CGPoint,
        scale: CGFloat = 1.0,
        rotation: Angle = .zero
    ) {
        self.id = id
        self.imageName = imageName
        self.normalizedPosition = normalizedPosition
        self.scale = scale
        self.rotation = rotation
    }

    /// A kitten's default width, as a fraction of the canvas side length.
    static let defaultSizeFraction: CGFloat = 0.42

    static let minScale: CGFloat = 0.3
    static let maxScale: CGFloat = 3.0
}
