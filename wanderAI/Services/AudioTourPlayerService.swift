import Foundation
import AVFoundation
import Combine

/// Manages local audio playback for downloaded audio tours.
@MainActor
@Observable
final class AudioTourPlayerService {
    enum PlaybackState {
        case idle
        case playing
        case paused
    }

    private(set) var playbackState: PlaybackState = .idle
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    /// Loads and plays an audio file from the given local URL.
    func play(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)

            if player?.url == url, playbackState == .paused {
                // Resume
                player?.play()
                playbackState = .playing
                startTimer()
                return
            }

            // New file or different file
            stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            player?.play()
            playbackState = .playing
            startTimer()
        } catch {
            print("[wanderAI] ❌ Audio playback error: \(error.localizedDescription)")
            playbackState = .idle
        }
    }

    /// Pauses the current playback.
    func pause() {
        player?.pause()
        playbackState = .paused
        stopTimer()
    }

    /// Stops playback and resets to the beginning.
    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTime = 0
        playbackState = .idle
        stopTimer()
    }

    /// Restarts playback from the beginning.
    func restart(url: URL) {
        stop()
        play(url: url)
    }

    // MARK: - Private

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = self.player?.currentTime ?? 0
                if self.player?.isPlaying == false && self.playbackState == .playing {
                    // Playback finished
                    self.playbackState = .idle
                    self.currentTime = 0
                    self.stopTimer()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
