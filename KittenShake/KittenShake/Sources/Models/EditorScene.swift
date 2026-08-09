import SwiftUI
import Combine

/// Shared mutable editing state for the guided kitten-placement flow
/// (shake-review → position → build-scene). Held as a single `@StateObject`
/// by `HomeContainerView` and threaded through the flow via
/// `.environmentObject`, so navigating back and forth between steps never
/// loses in-progress sprite placements — unlike the old `EditorView`, which
/// owned all of this as local `@State`.
@MainActor
final class EditorScene: ObservableObject {
    @Published var backgroundImage: UIImage?
    @Published var sprites: [KittenSprite] = []
    @Published var selectedSpriteID: UUID?
    @Published var kittenImageCache: [String: UIImage] = [:]

    private var undoStack: [[KittenSprite]] = []
    private var shakeTimestamps: [Date] = []

    var canUndo: Bool { !undoStack.isEmpty }

    /// Starts a brand-new scene against a freshly acquired/cropped photo.
    func reset(background: UIImage) {
        backgroundImage = background
        sprites = []
        selectedSpriteID = nil
        undoStack = []
        shakeTimestamps = []
    }

    func image(for name: String) -> UIImage? {
        if let cached = kittenImageCache[name] { return cached }
        let loaded = GeneratedKittenStore.shared.contains(name)
            ? GeneratedKittenStore.shared.image(named: name)
            : ResourceLocator.image(named: name)
        guard let loaded else { return nil }
        kittenImageCache[name] = loaded
        return loaded
    }

    func pushUndo() {
        undoStack.append(sprites)
        if undoStack.count > 20 { undoStack.removeFirst() }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        sprites = previous
        if !sprites.contains(where: { $0.id == selectedSpriteID }) {
            selectedSpriteID = sprites.last?.id
        }
    }

    /// Adds a new random classic kitten as the current "candidate" (used
    /// when entering shake-review) and selects it. Returns its id.
    @discardableResult
    func addCandidateKitten() -> UUID {
        pushUndo()
        let existingNames = Set(sprites.map { $0.imageName })
        let name = KittenCatalog.classicPack.kittenImageNames.first { !existingNames.contains($0) }
            ?? KittenCatalog.randomKittenImageName()
        let jitter = CGFloat.random(in: -0.08...0.08)
        let sprite = KittenSprite(imageName: name, normalizedPosition: CGPoint(x: 0.5 + jitter, y: 0.5 + jitter))
        sprites.append(sprite)
        selectedSpriteID = sprite.id
        SoundPlayer.shared.playRandomMeow()
        return sprite.id
    }

    /// Adds an already-generated AI kitten (already computed placement) as
    /// the current candidate/selection.
    func addSprite(imageName: String, normalizedPosition: CGPoint, scale: CGFloat) {
        pushUndo()
        let sprite = KittenSprite(imageName: imageName, normalizedPosition: normalizedPosition, scale: scale)
        sprites.append(sprite)
        selectedSpriteID = sprite.id
        SoundPlayer.shared.playRandomMeow()
    }

    /// Re-rolls the given sprite (or adds a new candidate if none) to a new
    /// random kitten image — used by "Shake Again" and physical shakes.
    func reshuffle(spriteID: UUID?) {
        guard let id = spriteID, let idx = sprites.firstIndex(where: { $0.id == id }) else {
            addCandidateKitten()
            return
        }
        pushUndo()
        let now = Date()
        shakeTimestamps.append(now)
        shakeTimestamps = shakeTimestamps.filter { now.timeIntervalSince($0) < 1.5 }
        let annoyed = shakeTimestamps.count >= 3

        sprites[idx].imageName = KittenCatalog.randomKittenImageName(excluding: sprites[idx].imageName)
        SoundPlayer.shared.playRandomMeow(annoyed: annoyed)
    }

    func removeSprite(id: UUID) {
        pushUndo()
        sprites.removeAll { $0.id == id }
        if selectedSpriteID == id { selectedSpriteID = sprites.last?.id }
    }

    func moveSprites(fromOffsets source: IndexSet, toOffset destination: Int) {
        pushUndo()
        sprites.move(fromOffsets: source, toOffset: destination)
    }

    func pet() {
        SoundPlayer.shared.startPurr()
        SoundPlayer.shared.stopPurr(after: 1.5)
    }

    func flattenedImage(includeWatermark: Bool) -> UIImage? {
        guard let backgroundImage else { return nil }
        return ImageExporter.renderFlattenedImage(
            background: backgroundImage,
            sprites: sprites,
            kittenImage: { [weak self] name in self?.image(for: name) },
            includeWatermark: includeWatermark
        )
    }

    /// Seeds a deterministic scene for `-ksScreen` verification hooks: a
    /// background photo plus one placed kitten, selected.
    func seedForDebug(background: UIImage, kittenName: String = "kitten_02") {
        backgroundImage = background
        let sprite = KittenSprite(imageName: kittenName, normalizedPosition: CGPoint(x: 0.62, y: 0.68))
        sprites = [sprite]
        selectedSpriteID = sprite.id
        undoStack = []
    }
}
