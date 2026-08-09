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

    /// All packs currently unlocked for the player. Phase 2 will filter this
    /// by purchase/entitlement state.
    static let unlockedPacks: [KittenPack] = [classicPack]

    static func randomKittenImageName(excluding current: String? = nil) -> String {
        classicPack.randomKittenImageName(excluding: current)
    }
}
