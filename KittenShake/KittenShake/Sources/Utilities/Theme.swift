import SwiftUI

/// Central design tokens for the brand visual identity: warm cream/peach
/// backgrounds, a coral-orange accent, dark navy text, and Fraunces (a
/// chunky, warm display serif bundled in Resources/Fonts) for headlines,
/// all with sensible dark-mode variants defined as Asset Catalog color sets.
enum KSTheme {
    // MARK: Colors

    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let surfaceRaised = Color("AppSurfaceRaised")
    static let accent = Color("AccentCoral")
    /// A deeper, more saturated coral-red than `accent`, sampled from the
    /// mockup's "Add kittens." tagline line — used for display-scale
    /// headline emphasis where the plain button coral reads too light.
    static let accentDeep = Color("AccentCoralDeep")
    static let gold = Color("AccentGold")
    /// Warm pale peach used for soft badge/tile fills (heart badge circle,
    /// "Choose from Library" icon tile) where pure white reads too stark
    /// against the cream background, per the mockups.
    static let peach = Color("AccentPeach")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let cardBorder = Color("CardBorder")

    // MARK: Metrics

    static let cardRadius: CGFloat = 28
    static let controlRadius: CGFloat = 28
    static let pillRadius: CGFloat = 100
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    /// Bottom clearance reserved by screens pushed onto `HomeContainerView`'s
    /// `NavigationStack` (Get Started, Build Scene, Result, Position Mode,
    /// Shake Review) so their trailing content isn't laid out behind the
    /// floating `KSTabBar`. `RootView` reserves the tab bar's height via
    /// `.safeAreaInset(edge: .bottom)` on its outer `ZStack`, but that inset
    /// isn't reliably inherited by content pushed via `navigationDestination`
    /// — those screens get the full, un-reduced screen height to lay out in,
    /// so without this explicit reserve their bottom-most controls can end
    /// up rendered underneath the (opaque, but shorter) tab bar rather than
    /// above it. Measured empirically against the rendered `KSTabBar` on an
    /// iPhone 17 simulator (~134pt from screen bottom to clear cream
    /// background above the bar); kept with a small margin of safety.
    static let flowBottomClearance: CGFloat = 115

    // MARK: Type

    /// The brand's chunky warm serif (Fraunces) used for headlines and the
    /// wordmark, matching the mockups' heavy, rounded display type.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .fraunces(size: size, weight: weight)
    }

    /// Rounded sans used for body/secondary copy, echoing the mockups'
    /// friendly rounded sans without bundling a second custom font family.
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
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
                    .shadow(color: KSTheme.accent.opacity(0.14), radius: 18, x: 0, y: 10)
            )
    }
}

// MARK: - Status pill

/// The rounded status/tip pill seen throughout the mockups ("Shake
/// detected!", "New kitten added", "Choose a clear photo…"): a small glyph
/// plus text on a soft pale background.
struct KSPill: View {
    var systemImage: String
    var text: String
    var tint: Color = KSTheme.accent
    var background: Color = KSTheme.gold.opacity(0.16)
    var textFont: Font = .subheadline.weight(.semibold)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(text)
                .foregroundStyle(tint)
        }
        .font(textFont)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(background)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Soft cloud background

/// A very low-contrast rounded "cloud blob" backdrop shape echoing the
/// mockups' soft cloud silhouettes peeking in from the screen edges.
private struct CloudBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addEllipse(in: CGRect(x: 0, y: h * 0.35, width: w * 0.6, height: h * 0.55))
        p.addEllipse(in: CGRect(x: w * 0.3, y: h * 0.1, width: w * 0.55, height: h * 0.6))
        p.addEllipse(in: CGRect(x: w * 0.55, y: h * 0.4, width: w * 0.45, height: h * 0.5))
        return p
    }
}

/// Two soft cloud shapes tucked into the top corners, used behind screen
/// content via `.ksBackground(clouds:)`. Kept extremely low-contrast so it
/// never competes with foreground content, and skipped entirely in dark
/// mode where the mockups' airy cream backdrop doesn't apply.
struct KSCloudBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            if colorScheme == .light {
                CloudBlob()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: geo.size.width * 0.7, height: geo.size.height * 0.16)
                    .position(x: geo.size.width * 0.12, y: geo.size.height * 0.1)

                CloudBlob()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: geo.size.width * 0.65, height: geo.size.height * 0.14)
                    .position(x: geo.size.width * 0.92, y: geo.size.height * 0.22)
            }
        }
        .allowsHitTesting(false)
    }
}

/// The standard full-bleed screen backdrop: cream background plus the soft
/// cloud accents, used as the first layer in every screen's root `ZStack`
/// in place of a bare `KSTheme.background.ignoresSafeArea()`.
struct KSScreenBackground: View {
    var body: some View {
        ZStack {
            KSTheme.background
            KSCloudBackdrop()
        }
        .ignoresSafeArea()
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

/// The cat-face wordmark used across Home, Onboarding, and the Result
/// screen. Thin wrapper around `BrandHeader` (cat mark + two-line Fraunces
/// "Kitten Shake" lockup) kept under its historical name so existing call
/// sites don't need to change.
struct KittenShakeWordmark: View {
    var logoSize: CGFloat = 64
    var titleSize: CGFloat = 30

    var body: some View {
        BrandHeader(markSize: logoSize, lineSize: titleSize)
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
        self.background(
            ZStack {
                KSTheme.background
                KSCloudBackdrop()
            }
            .ignoresSafeArea()
        )
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
