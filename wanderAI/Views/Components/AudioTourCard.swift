import SwiftUI

/// Displays the appropriate audio tour UI based on the current screen state.
/// Embedded within the destination/stop detail view.
struct AudioTourCard: View {
    let viewModel: AudioTourViewModel

    var body: some View {
        VStack(spacing: 12) {
            switch viewModel.screenState {
            case .noRecord:
                generateButton

            case .processing:
                processingView

            case .completedNotDownloaded:
                downloadButton

            case .downloaded:
                AudioTourPlayerView(viewModel: viewModel)

            case .failed:
                failedView
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Generate

    private var generateButton: some View {
        Button {
            viewModel.showSetupSheet = true
        } label: {
            Label("Generate Audio Tour", systemImage: "headphones")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    // MARK: - Processing

    private var processingView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .foregroundStyle(.green)
                Text(viewModel.currentStatus?.friendlyLabel ?? "Processing")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            Button {
                Task { await viewModel.checkStatus() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Check Status")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.green)
            .disabled(viewModel.isLoading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
        )
    }

    // MARK: - Download

    private var downloadButton: some View {
        Button {
            Task { await viewModel.downloadAudio() }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Label("Download Audio Tour", systemImage: "arrow.down.circle.fill")
            }
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(viewModel.isLoading)
    }

    // MARK: - Failed

    private var failedView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Generation failed")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }

            Button {
                viewModel.retryAfterFailure()
            } label: {
                Text("Try Again")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05))
        )
    }
}
