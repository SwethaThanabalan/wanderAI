import SwiftUI

/// Local audio playback controls: Play, Pause, Restart, and Ask a Question.
struct AudioTourPlayerView: View {
    let viewModel: AudioTourViewModel

    private var playerService: AudioTourPlayerService {
        viewModel.playerService
    }

    @State private var voiceQA = VoiceQAService()

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

                // Skip forward 15s
                Button {
                    viewModel.skipForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title3)
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Skip forward 15 seconds")
            }

            // Voice Q&A interrupt button
            VoiceQAButton(
                voiceQA: voiceQA,
                persona: viewModel.audioTour?.selectedPersonas.first,
                destination: viewModel.audioTour?.destinationName,
                tripName: nil,
                region: nil,
                currentStop: viewModel.audioTour?.destinationName,
                onWillRecord: {
                    // Pause the tour while recording/answering
                    if playerService.playbackState == .playing {
                        viewModel.pause()
                    }
                },
                onDismissed: {
                    // Resume tour playback after Q&A is done
                    if playerService.playbackState == .paused {
                        viewModel.play()
                    }
                }
            )
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
