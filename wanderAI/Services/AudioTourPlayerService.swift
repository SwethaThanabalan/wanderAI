import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// Manages local audio playback for downloaded audio tours.
/// Configured for background playback — audio continues when the screen locks.
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
    private var audioTitle: String = "Audio Tour"
    private var interruptionObserver: Any?

    init() {
        // Observe audio interruptions (phone calls, Siri, etc.)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Loads and plays an audio file from the given local URL.
    func play(url: URL, title: String? = nil) {
        if let title { audioTitle = title }

        do {
            // Configure audio session for background + CarPlay playback
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            if player?.url == url, playbackState == .paused {
                // Resume
                player?.play()
                playbackState = .playing
                startTimer()
                updateNowPlaying()
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
            setupRemoteCommands()
            updateNowPlaying()
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
        updateNowPlaying()
    }

    /// Stops playback and resets to the beginning.
    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTime = 0
        playbackState = .idle
        stopTimer()
        clearNowPlaying()
    }

    /// Restarts playback from the beginning.
    func restart(url: URL) {
        stop()
        play(url: url)
    }

    // MARK: - Remote Commands (Lock Screen / Control Center)

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                guard let player = self.player, !player.isPlaying else { return }
                player.play()
                self.playbackState = .playing
                self.startTimer()
                self.updateNowPlaying()
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                self.pause()
            }
            return .success
        }

        // Skip forward 15 seconds (prominent in CarPlay)
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            Task { @MainActor in
                guard let player = self.player else { return }
                let newTime = min(player.currentTime + event.interval, player.duration)
                player.currentTime = newTime
                self.currentTime = newTime
                self.updateNowPlaying()
            }
            return .success
        }

        // Skip backward 15 seconds
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            Task { @MainActor in
                guard let player = self.player else { return }
                let newTime = max(player.currentTime - event.interval, 0)
                player.currentTime = newTime
                self.currentTime = newTime
                self.updateNowPlaying()
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in
                self.player?.currentTime = event.positionTime
                self.currentTime = event.positionTime
                self.updateNowPlaying()
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = audioTitle
        info[MPMediaItemPropertyArtist] = "WanderAI"
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime ?? 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackState == .playing ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        info[MPMediaItemPropertyAlbumTitle] = "WanderAI Audio Tour"
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
                    self.clearNowPlaying()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Interruption Handling

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Audio was interrupted (phone call, Siri, etc.)
            if playbackState == .playing {
                pause()
            }
        case .ended:
            // Interruption ended — resume if appropriate
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume), let player, playbackState == .paused {
                    // Re-activate session and resume
                    try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                    player.play()
                    playbackState = .playing
                    startTimer()
                    updateNowPlaying()
                }
            }
        @unknown default:
            break
        }
    }
}
