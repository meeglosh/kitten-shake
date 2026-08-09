import Foundation

/// Reads a `-ksScreen <name>` launch argument so automated verification
/// (simctl launch --args) can jump straight to a given screen for
/// screenshotting, bypassing camera/photo-picker interactions that aren't
/// scriptable from the command line. Has no effect in normal app usage.
///
/// IMPORTANT: Every hook here is compiled out entirely in Release builds
/// (see `#if DEBUG` below). In Release, all properties are inert constants
/// (`nil`/`false`) regardless of launch arguments, so these hooks — in
/// particular the `-ksForceSubscriber` paywall bypass — can never be
/// triggered in a shipped build.
enum UITestSupport {
#if DEBUG
    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-ksScreen"), idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    /// Verification-only hook: when present, `BuildSceneView` automatically
    /// triggers the AI Kitten action shortly after appearing, so the
    /// generation → placement flow can be screenshotted without needing a
    /// real tap-automation harness in the simulator.
    static var autoAI: Bool {
        ProcessInfo.processInfo.arguments.contains("-ksAutoAI")
    }

    /// Verification-only hook: forces `Entitlements.isSubscriber` to `true`
    /// without a real StoreKit purchase. Used to exercise the
    /// subscriber-only UI/export paths (Subscribed ✓, no watermark) in
    /// environments where the interactive StoreKit purchase-confirmation
    /// sheet can't be driven headlessly (no XCUITest harness attached).
    /// Has no effect unless passed explicitly at launch.
    static var forceSubscriber: Bool {
        ProcessInfo.processInfo.arguments.contains("-ksForceSubscriber")
    }

    /// Verification-only hook: `BuildSceneView` automatically saves and
    /// jumps to `ResultView` shortly after appearing, so the watermark
    /// on/off behavior (driven by `Entitlements.isSubscriber`) can be
    /// screenshotted without a real tap on the Save button.
    static var autoExport: Bool {
        ProcessInfo.processInfo.arguments.contains("-ksAutoExport")
    }
#else
    // Release builds: hooks are compile-time-inert. No launch argument can
    // activate them, and the argument strings themselves are not present in
    // the binary.
    static var screen: String? { nil }
    static var autoAI: Bool { false }
    static var forceSubscriber: Bool { false }
    static var autoExport: Bool { false }
#endif
}
