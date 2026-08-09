import UIKit

/// Wraps a `UIImage` so it can travel through a `NavigationStack` path
/// (UIImage itself isn't Hashable/Identifiable).
final class ImageBox: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage

    init(_ image: UIImage) {
        self.image = image
    }

    static func == (lhs: ImageBox, rhs: ImageBox) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Navigation destinations within the Home tab's guided photo-editing flow:
/// Get Started → Camera/Library → Crop → Shake Review → Position Mode →
/// Build Scene → Result. Shake Review, Position Mode, and Build Scene read
/// their working state from the shared `EditorScene` environment object
/// rather than carrying it as associated values.
enum HomeRoute: Hashable {
    case getStarted
    case camera
    case crop(ImageBox)
    case shakeReview
    case position
    case buildScene
    case result(ImageBox)
}
