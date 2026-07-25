import SwiftUI

/// Local audio playback controls: Play, Pause, Restart.
struct AudioTourPlayerView: View {
    let viewModel: AudioTourViewModel

    private var playerService: AudioTourPlayerService {
        viewModel.playerService
    }

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Image(systemName: "headphones")
                    .font(.title3)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audio Tour")
                        .font(.subheadline.weight(.semibold))
                    Text(viewModel.audioTour?.destinationName ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Progress bar
            if playerService.duration > 0 {
                VStack(spacing: 4) {
                    ProgressView(value: playerService.currentTime, total: playerService.duration)
                        .tint(.green)

                    HStack {
                        Text(formatTime(playerService.currentTime))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatTime(playerService.duration))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Controls
            HStack(spacing: 24) {
                // Restart
                Button {
                    viewModel.restart()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Restart")

                // Play / Pause
                Button {
                    switch playerService.playbackState {
                    case .idle, .paused:
                        viewModel.play()
                    case .playing:
                        viewModel.pause()
                    }
                } label: {
                    Image(systemName: playerService.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                }
                .accessibilityLabel(playerService.playbackState == .playing ? "Pause" : "Play")

                // Placeholder for symmetry
                Image(systemName: "backward.end.fill")
                    .font(.title3)
                    .foregroundStyle(.clear)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
