import UIKit

/// A saved creation on disk: the full-resolution JPEG plus a small thumbnail
/// for fast grid rendering.
struct Creation: Identifiable, Equatable {
    let id: String
    let imageURL: URL
    let thumbnailURL: URL
    let createdAt: Date
}

/// Persists every exported image to `Documents/Creations` (full JPEG +
/// thumbnail) so the Creations tab can show a gallery of past exports.
final class CreationStore: ObservableObject {
    static let shared = CreationStore()

    @Published private(set) var creations: [Creation] = []

    private let folder: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        folder = documents.appendingPathComponent("Creations", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        reload()
    }

    /// Saves the flattened export image to disk and returns the new `Creation`.
    @discardableResult
    func save(_ image: UIImage) -> Creation? {
        let id = UUID().uuidString
        let imageURL = folder.appendingPathComponent("\(id).jpg")
        let thumbURL = folder.appendingPathComponent("\(id)_thumb.jpg")

        guard let fullData = image.jpegData(compressionQuality: 0.92) else { return nil }
        try? fullData.write(to: imageURL)

        let thumb = Self.thumbnail(for: image, maxDimension: 480)
        if let thumbData = thumb.jpegData(compressionQuality: 0.8) {
            try? thumbData.write(to: thumbURL)
        }

        let creation = Creation(id: id, imageURL: imageURL, thumbnailURL: thumbURL, createdAt: Date())
        creations.insert(creation, at: 0)
        return creation
    }

    func delete(_ creation: Creation) {
        try? FileManager.default.removeItem(at: creation.imageURL)
        try? FileManager.default.removeItem(at: creation.thumbnailURL)
        creations.removeAll { $0.id == creation.id }
    }

    func reload() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey]) else {
            creations = []
            return
        }
        let images = files.filter { $0.lastPathComponent.hasSuffix(".jpg") && !$0.lastPathComponent.hasSuffix("_thumb.jpg") }
        creations = images.compactMap { url -> Creation? in
            let id = url.deletingPathExtension().lastPathComponent
            let thumbURL = folder.appendingPathComponent("\(id)_thumb.jpg")
            let date = (try? fm.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date()
            return Creation(id: id, imageURL: url, thumbnailURL: fm.fileExists(atPath: thumbURL.path) ? thumbURL : url, createdAt: date)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    private static func thumbnail(for image: UIImage, maxDimension: CGFloat) -> UIImage {
        let scale = maxDimension / max(image.size.width, image.size.height)
        guard scale < 1 else { return image }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
