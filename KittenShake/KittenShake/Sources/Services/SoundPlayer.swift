import AVFoundation

/// Plays all of the app's short sound effects and the looping purr.
/// A singleton keeps `AVAudioPlayer` instances alive for the duration of
/// playback (they're deallocated the moment nothing retains them).
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var effectPlayers: Set<AVAudioPlayer> = []
    private var purrPlayer: AVAudioPlayer?

    private static let meowNames: [String] = (1...19).map { String(format: "sfx_meow_%02d", $0) }
    private static let annoyedMeowName = "sfx_meow_20"

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playClick() {
        play(name: "sfx_click_01", ext: "mp3", volume: 0.7)
    }

    /// Plays a random meow. When `annoyed` is true (the user has been
    /// shaking rapidly) a single designated "annoyed" meow plays instead.
    func playRandomMeow(annoyed: Bool = false) {
        let name = annoyed ? Self.annoyedMeowName : (Self.meowNames.randomElement() ?? Self.annoyedMeowName)
        play(name: name, ext: "mp3", volume: 1.0)
    }

    func startPurr() {
        guard purrPlayer == nil,
              let url = ResourceLocator.url(forResource: "sfx_purr_loop_01", withExtension: "mp3") else { return }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.volume = 0.9
        player?.prepareToPlay()
        player?.play()
        purrPlayer = player
    }

    func stopPurr(after delay: TimeInterval = 1.2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.purrPlayer?.stop()
            self?.purrPlayer = nil
        }
    }

    private func play(name: String, ext: String, volume: Float) {
        guard let url = ResourceLocator.url(forResource: name, withExtension: ext) else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = volume
        player.prepareToPlay()
        effectPlayers.insert(player)
        player.play()

        let duration = player.duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) { [weak self] in
            self?.effectPlayers.remove(player)
        }
    }
}
