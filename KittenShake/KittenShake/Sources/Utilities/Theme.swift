import SwiftUI

/// Central design tokens for the Phase 2 visual identity: warm cream/peach
/// backgrounds, a coral-orange accent, dark navy text, and a serif display
/// face (New York via `.fontDesign(.serif)`), all with sensible dark-mode
/// variants defined as Asset Catalog color sets.
enum KSTheme {
    // MARK: Colors

    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let surfaceRaised = Color("AppSurfaceRaised")
    static let accent = Color("AccentCoral")
    static let gold = Color("AccentGold")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let cardBorder = Color("CardBorder")

    // MARK: Metrics

    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 18
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: Type

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

// MARK: - Card container

struct KSCard<Content: View>: View {
    var padding: CGFloat = KSTheme.spacingL
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: KSTheme.cardRadius, style: .continuous)
                    .fill(KSTheme.surface)
                    .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 8)
            )
    }
}

// MARK: - Buttons

struct KSPrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                    .fill(isDisabled ? KSTheme.accent.opacity(0.4) : KSTheme.accent)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct KSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(KSTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                    .fill(KSTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                            .stroke(KSTheme.textSecondary.opacity(0.15), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == KSPrimaryButtonStyle {
    static var ksPrimary: KSPrimaryButtonStyle { KSPrimaryButtonStyle() }
    static func ksPrimary(disabled: Bool) -> KSPrimaryButtonStyle { KSPrimaryButtonStyle(isDisabled: disabled) }
}

extension ButtonStyle where Self == KSSecondaryButtonStyle {
    static var ksSecondary: KSSecondaryButtonStyle { KSSecondaryButtonStyle() }
}

/// A distinct "AI-powered" treatment (coral→gold gradient, matching the
/// Home hero card) used for the AI Kitten action so it reads as a
/// different, premium kind of button next to the plain coral primary style.
struct KSSparkleButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: KSTheme.controlRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [KSTheme.accent, KSTheme.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isDisabled ? 0.4 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == KSSparkleButtonStyle {
    static var ksSparkle: KSSparkleButtonStyle { KSSparkleButtonStyle() }
    static func ksSparkle(disabled: Bool) -> KSSparkleButtonStyle { KSSparkleButtonStyle(isDisabled: disabled) }
}

// MARK: - Reusable chrome

/// The cat-face wordmark used across Home, Onboarding, and the Result screen.
struct KittenShakeWordmark: View {
    var logoSize: CGFloat = 44
    var titleSize: CGFloat = 30

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "cat.fill")
                .font(.system(size: logoSize * 0.62))
                .foregroundStyle(KSTheme.accent)
                .frame(width: logoSize, height: logoSize)
                .background(
                    Circle().fill(KSTheme.accent.opacity(0.14))
                )
            Text("Kitten Shake")
                .font(KSTheme.display(titleSize))
                .foregroundStyle(KSTheme.textPrimary)
        }
    }
}

/// Restricts content to a comfortable reading width and centers it — used on
/// iPad so screens don't stretch edge-to-edge.
struct ReadableWidth: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func ksReadableWidth() -> some View { modifier(ReadableWidth()) }

    func ksBackground() -> some View {
        self.background(KSTheme.background.ignoresSafeArea())
    }
}

/// Small decorative sparkle/heart accents used to echo the mockups' playful
/// confetti without pulling in a particle-effects dependency.
struct SparkleAccent: View {
    var systemName: String = "sparkle"
    var color: Color = KSTheme.gold
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size))
            .foregroundStyle(color)
    }
}
