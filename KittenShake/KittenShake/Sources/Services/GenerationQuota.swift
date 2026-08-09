import Foundation
import Combine

/// Tracks the client's best-known count of free AI-kitten generations
/// remaining. The Worker is the source of truth (it keys the free-tier
/// allowance off `deviceId`); this just mirrors the `remaining` value from
/// each `/v1/generate` response so the UI can show "N free left" and flip
/// to the paywall at 0 without waiting on a network round trip.
final class GenerationQuota: ObservableObject {
    static let shared = GenerationQuota()

    private static let key = "ks.freeGenerationsRemaining"
    /// Mirrors the Worker's free-tier allowance (see contract: 3 free uses).
    private static let defaultRemaining = 3

    @Published var freeRemaining: Int {
        didSet { UserDefaults.standard.set(freeRemaining, forKey: Self.key) }
    }

    private init() {
        if UserDefaults.standard.object(forKey: Self.key) != nil {
            freeRemaining = UserDefaults.standard.integer(forKey: Self.key)
        } else {
            freeRemaining = Self.defaultRemaining
        }
    }

    func record(remaining: Int?) {
        guard let remaining else { return } // nil means "subscriber, unlimited" — nothing to track.
        freeRemaining = max(0, remaining)
    }

    func markExhausted() {
        freeRemaining = 0
    }
}
