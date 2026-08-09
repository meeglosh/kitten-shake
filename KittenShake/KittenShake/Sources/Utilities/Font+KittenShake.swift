import SwiftUI

extension Font {
    /// The playful legacy display font, kept around for any lingering call
    /// sites but no longer used for headline chrome (see `KSTheme.display`).
    static func freckleFace(size: CGFloat) -> Font {
        .custom("FreckleFace-Regular", size: size)
    }

    /// Fraunces — the brand's chunky warm serif, bundled as static instances
    /// (Resources/Fonts/Fraunces) baked from the variable font at a high
    /// SOFT value (rounder terminals, close to the mockups' Recoleta-ish
    /// feel) and an optical size tuned for headline-scale text.
    static func fraunces(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let name: String
        switch weight {
        case .black, .heavy:
            name = "Fraunces-Black"
        case .bold:
            name = "Fraunces-Bold"
        default:
            name = "Fraunces-SemiBold"
        }
        return .custom(name, size: size)
    }
}
