import UIKit
import Combine

/// Persists AI-generated kitten cutouts (transparent PNGs from the
/// generation backend) to `Documents/GeneratedKittens` and exposes them as
/// a dynamic "My AI Kittens" `KittenPack` so they can be reused across
/// sessions and shake-swapped among themselves like any other pack.
///
/// Generated image names are always prefixed `ai_` so callers (and
/// `KittenCatalog`) can tell an AI kitten apart from a bundled classic one
/// without a separate lookup table.
final class GeneratedKittenStore: ObservableObject {
    static let shared = GeneratedKittenStore()

    @Published private(set) var imageNames: [String] = []

    private let folder: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        folder = documents.appendingPathComponent("GeneratedKittens", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        reload()
    }

    var pack: KittenPack {
        KittenPack(id: "ai_generated", displayName: "My AI Kittens", kittenImageNames: imageNames, isFree: true)
    }

    func contains(_ imageName: String) -> Bool {
        imageName.hasPrefix("ai_")
    }

    @discardableResult
    func save(_ image: UIImage) -> String? {
        guard let data = image.pngData() else { return nil }
        let name = "ai_\(UUID().uuidString)"
        do {
            try data.write(to: fileURL(for: name))
        } catch {
            return nil
        }
        imageNames.insert(name, at: 0)
        return name
    }

    func image(named name: String) -> UIImage? {
        guard contains(name) else { return nil }
        return UIImage(contentsOfFile: fileURL(for: name).path)
    }

    private func fileURL(for name: String) -> URL {
        folder.appendingPathComponent("\(name).png")
    }

    private func reload() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey]) else {
            imageNames = []
            return
        }
        imageNames = files
            .filter { $0.pathExtension == "png" }
            .compactMap { url -> (String, Date)? in
                let name = url.deletingPathExtension().lastPathComponent
                let date = (try? fm.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date()
                return (name, date)
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }
}
