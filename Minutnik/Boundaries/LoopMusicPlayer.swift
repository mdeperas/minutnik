import AVFoundation

@MainActor
final class LoopMusicPlayer: MusicPlayer {
    private var player: AVAudioPlayer?
    private var stopTask: Task<Void, Never>?

    func play(_ fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a"),
              let loaded = try? AVAudioPlayer(contentsOf: url) else {
            Log.sound.error("muzyka: brak pliku \(fileName, privacy: .public)")
            return
        }
        stopTask?.cancel()
        player?.stop()
        loaded.numberOfLoops = -1
        loaded.volume = 0
        loaded.play()
        player = loaded
        Log.sound.notice("muzyka: start \(fileName, privacy: .public)")
    }

    func fade(to volume: Float, over seconds: TimeInterval) {
        guard let player else { return }
        if volume > 0, !player.isPlaying { player.play() }
        player.setVolume(volume, fadeDuration: seconds)
    }

    func stop() {
        guard let current = player else { return }
        current.setVolume(0, fadeDuration: MusicTrack.fadeSeconds)
        stopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(MusicTrack.fadeSeconds))
            guard !Task.isCancelled else { return }
            current.stop()
            if self?.player === current { self?.player = nil }
        }
    }
}
