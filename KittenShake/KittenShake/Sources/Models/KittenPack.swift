import Foundation

/// A themed collection of kitten cutouts. Phase 1 ships a single free pack;
/// Phase 2 can add additional packs sold as in-app purchases without
/// touching any of the editor logic.
struct KittenPack: Identifiable {
    let id: String
    let displayName: String
    let kittenImageNames: [String]
    let isFree: Bool

    /// Picks a random kitten image name from this pack, optionally avoiding
    /// a specific name (used when shaking so the same kitten doesn't repeat).
    func randomKittenImageName(excluding current: String? = nil) -> String {
        guard let current, kittenImageNames.count > 1 else {
            return kittenImageNames.randomElement() ?? "kitten_01"
        }
        let choices = kittenImageNames.filter { $0 != current }
        return choices.randomElement() ?? current
    }
}

/// The data-driven catalog of all kitten packs available to the app.
enum KittenCatalog {
    static let classicPack = KittenPack(
        id: "classic",
        displayName: "Classic Kittens",
        kittenImageNames: (1...16).map { String(format: "kitten_%02d", $0) },
        isFree: true
    )

    /// All packs currently unlocked for the player: the free classic pack,
    /// plus "My AI Kittens" once the player has generated at least one.
    static var unlockedPacks: [KittenPack] {
        let aiPack = GeneratedKittenStore.shared.pack
        return aiPack.kittenImageNames.isEmpty ? [classicPack] : [classicPack, aiPack]
    }

    /// The pack a given kitten image belongs to — used so shaking swaps a
    /// kitten for another one in the *same* pack (AI kittens shake among
    /// AI kittens; classic kittens shake among classic kittens).
    static func pack(containing imageName: String) -> KittenPack {
        GeneratedKittenStore.shared.contains(imageName) ? GeneratedKittenStore.shared.pack : classicPack
    }

    static func randomKittenImageName(excluding current: String? = nil) -> String {
        guard let current else { return classicPack.randomKittenImageName() }
        return pack(containing: current).randomKittenImageName(excluding: current)
    }
}
