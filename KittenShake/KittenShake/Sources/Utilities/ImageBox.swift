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

/// Navigation destinations within the Home tab's photo-editing flow.
enum HomeRoute: Hashable {
    case crop(ImageBox)
    case editor(ImageBox)
    case result(ImageBox)
}
