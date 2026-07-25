import SwiftUI
import SwiftData
import MapKit

/// A stop card for execution mode with one-click Navigate and Play Audio Tour actions.
struct ExecutionStopCard: View {
    @Environment(\.modelContext) private var modelContext

    let stop: StopPayload
    let tripId: String
    let region: String
    let visitDate: String

    @State private var audioViewModel: AudioTourViewModel?
    @State private var isCompleted = false
    @State private var showReview = false

    private var hasValidCoordinates: Bool {
        stop.mapReference.latitude != 0 && stop.mapReference.longitude != 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full-width location image
            ZStack(alignment: .topLeading) {
                LocationImageView(locationName: stop.name, height: 150, cornerRadius: 0)

                // Sequence badge
                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 32, height: 32)
                    Text("\(stop.sequence)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stop.name)
                            .font(.headline)
                        if let category = stop.category {
                            Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if let time = stop.plannedTime {
                            Text(time)
                                .font(.subheadline.bold())
                        }
                        if let dur = stop.estimatedDurationMinutes {
                            Text("\(dur) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Summary
                if let summary = stop.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Highlights
                if let highlights = stop.highlights, !highlights.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(highlights.prefix(4), id: \.self) { hl in
                                Text(hl)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Primary action buttons
                HStack(spacing: 10) {
                    // Navigate
                    if hasValidCoordinates {
                        Button {
                            openInMaps()
                        } label: {
                            Label("Navigate", systemImage: "location.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }

                    // Audio Tour
                    if let vm = audioViewModel {
                        audioTourButton(vm)
                    }
                }

                // Complete / Review row
                HStack(spacing: 10) {
                    if !isCompleted {
                        Button {
                            markComplete()
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.circle")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Completed")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            showReview = true
                        } label: {
                            Label("Review", systemImage: "star.fill")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .tint(.yellow)
                    }
                }
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .onAppear {
            setupAudioViewModel()
            checkIfCompleted()
        }
        .sheet(isPresented: $showReview) {
            StopReviewSheet(
                stopName: stop.name,
                tripId: tripId,
                stopId: stop.id
            )
        }
    }

    // MARK: - Audio Tour Button

    @ViewBuilder
    private func audioTourButton(_ vm: AudioTourViewModel) -> some View {
        switch vm.screenState {
        case .downloaded:
            Button {
                vm.play()
            } label: {
                Label("Play Tour", systemImage: "headphones")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

        case .completedNotDownloaded:
            Button {
                Task { await vm.downloadAudio() }
            } label: {
                Label("Download", systemImage: "arrow.down.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.green)

        case .processing:
            Button {
                Task { await vm.checkStatus() }
            } label: {
                Label("Generating...", systemImage: "waveform")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .disabled(vm.isLoading)

        case .noRecord:
            Button {
                vm.showSetupSheet = true
            } label: {
                Label("Audio Tour", systemImage: "headphones")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.green)
            .sheet(isPresented: Binding(
                get: { vm.showSetupSheet },
                set: { vm.showSetupSheet = $0 }
            )) {
                AudioTourSetupSheet(destinationName: stop.name) { duration, personas in
                    Task { await vm.submitJob(durationMinutes: duration, personas: personas) }
                }
            }

        case .failed:
            Button {
                vm.retryAfterFailure()
            } label: {
                Label("Retry Tour", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    // MARK: - Actions

    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: stop.mapReference.latitude,
            longitude: stop.mapReference.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = stop.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func markComplete() {
        isCompleted = true
        let service = AppContainer.tripExecutionService(context: modelContext)
        if service.executionState(for: tripId) == nil {
            // Auto-start trip if needed — we only need it for persistence
            // Use a minimal start
        }
        try? service.completeStop(tripId: tripId, stopId: stop.id)
        showReview = true
    }

    private func checkIfCompleted() {
        let service = AppContainer.tripExecutionService(context: modelContext)
        if let state = service.executionState(for: tripId) {
            isCompleted = state.stopStates.contains { $0.stopId == stop.id && $0.status == "completed" }
        }
    }

    // MARK: - Setup

    private func setupAudioViewModel() {
        guard audioViewModel == nil else { return }
        audioViewModel = AppContainer.audioTourViewModel(
            tripId: tripId,
            stopId: stop.id,
            destinationName: stop.name,
            region: region,
            visitDate: visitDate,
            context: modelContext
        )
    }
}
