import SwiftUI

/// "Ask a Question" interrupt button for audio tours.
/// Press-and-hold to record, release to send. Shows states: recording, processing, answer.
struct VoiceQAButton: View {
    let voiceQA: VoiceQAService
    let persona: String?
    let destination: String?
    let tripName: String?
    let region: String?
    let currentStop: String?
    let onWillRecord: () -> Void   // Pause the tour
    let onDismissed: () -> Void    // Resume the tour

    @State private var isHolding = false

    var body: some View {
        VStack(spacing: 12) {
            switch voiceQA.state {
            case .idle:
                askButton

            case .recording:
                recordingView

            case .processing:
                processingView

            case .playingAnswer:
                answerView

            case .error(let message):
                errorView(message)
            }
        }
    }

    // MARK: - Idle: Ask Button

    private var askButton: some View {
        Button {
            onWillRecord()
            voiceQA.startRecording()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.subheadline)
                Text("Ask a Question")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.green)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask a question about this stop")
    }

    // MARK: - Recording

    private var recordingView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                Text("Listening...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 16) {
                // Cancel
                Button {
                    voiceQA.cancelRecording()
                    onDismissed()
                } label: {
                    Text("Cancel")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Done / Send
                Button {
                    Task {
                        await voiceQA.stopRecordingAndAsk(
                            persona: persona,
                            destination: destination,
                            tripName: tripName,
                            state: region,
                            currentStop: currentStop
                        )
                        if voiceQA.state == .idle {
                            onDismissed()
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.subheadline)
                        Text("Send")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Processing

    private var processingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.green)
            Text("Thinking...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Answer Playing

    private var answerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let transcription = voiceQA.transcription, !transcription.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(transcription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }

            if let answer = voiceQA.answerText, !answer.isEmpty {
                Text(answer)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(4)
            }

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("Playing answer...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    voiceQA.dismiss()
                    onDismissed()
                } label: {
                    Text("Done")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                voiceQA.dismiss()
                onDismissed()
            } label: {
                Text("Dismiss")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }
}
