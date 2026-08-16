import Foundation
import SwiftData

/// Manages audio tour lifecycle for a specific trip + stop combination.
@MainActor
@Observable
final class AudioTourViewModel {
    // MARK: - State

    private(set) var audioTour: StoredAudioTour?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var showSetupSheet = false

    let playerService: AudioTourPlayerService

    // MARK: - Dependencies

    private let tripId: String
    private let stopId: String
    private let destinationName: String
    private let region: String
    private let visitDate: String
    private let context: ModelContext
    private let apiService: AudioTourAPIService
    private let downloadService: AudioTourDownloadService

    // MARK: - Computed

    var currentStatus: AudioTourStatus? {
        guard let status = audioTour?.status else { return nil }
        return AudioTourStatus(rawValue: status)
    }

    var screenState: ScreenState {
        guard let tour = audioTour else { return .noRecord }
        guard let status = AudioTourStatus(rawValue: tour.status) else { return .noRecord }

        switch status {
        case .failed:
            return .failed
        case .completed:
            if tour.localAudioPath != nil, downloadService.audioFileExists(at: tour.localAudioPath!) {
                return .downloaded
            }
            return .completedNotDownloaded
        default:
            return .processing
        }
    }

    enum ScreenState {
        case noRecord
        case processing
        case completedNotDownloaded
        case downloaded
        case failed
    }

    // MARK: - Init

    init(
        tripId: String,
        stopId: String,
        destinationName: String,
        region: String,
        visitDate: String,
        context: ModelContext,
        apiService: AudioTourAPIService,
        downloadService: AudioTourDownloadService,
        playerService: AudioTourPlayerService
    ) {
        self.tripId = tripId
        self.stopId = stopId
        self.destinationName = destinationName
        self.region = region
        self.visitDate = visitDate
        self.context = context
        self.apiService = apiService
        self.downloadService = downloadService
        self.playerService = playerService
        loadExistingTour()
    }

    // MARK: - Actions

    /// Submit a new audio tour generation job.
    func submitJob(durationMinutes: Int, personas: [String]) async {
        // Validate IDs are not empty
        guard !tripId.isEmpty, !stopId.isEmpty else {
            errorMessage = AudioTourError.invalidID.localizedDescription
            return
        }

        // Check for duplicate
        if let existing = audioTour,
           let status = AudioTourStatus(rawValue: existing.status),
           status.blocksDuplicate {
            errorMessage = "An audio tour is already \(status.friendlyLabel.lowercased())."
            return
        }

        isLoading = true
        errorMessage = nil

        let request = AudioTourJobRequest(
            tripId: DeterministicUUID.from(tripId),
            stopId: DeterministicUUID.from(stopId),
            destinationName: destinationName,
            region: region,
            visitDate: visitDate,
            episodeMinutes: durationMinutes,
            personas: personas
        )

        do {
            let response = try await apiService.submitJob(request: request)

            // Immediately save the backend job ID locally
            let tour = StoredAudioTour(
                jobId: response.jobId,
                tripId: tripId,
                stopId: stopId,
                destinationName: destinationName,
                durationMinutes: durationMinutes,
                selectedPersonas: personas,
                status: response.status
            )
            context.insert(tour)
            try context.save()

            audioTour = tour
            showSetupSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Check current job status from the backend.
    func checkStatus() async {
        guard let tour = audioTour else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.checkStatus(jobId: tour.jobId)
            tour.status = response.status
            tour.lastStatusCheckedAt = .now
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Download the completed audio file.
    func downloadAudio() async {
        guard let tour = audioTour else { return }

        isLoading = true
        errorMessage = nil

        do {
            let localPath = try await downloadService.downloadAudio(jobId: tour.jobId)
            tour.localAudioPath = localPath
            tour.downloadedAt = .now
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Retry after a failed job — deletes the existing record and opens setup.
    func retryAfterFailure() {
        if let tour = audioTour {
            context.delete(tour)
            try? context.save()
            audioTour = nil
        }
        showSetupSheet = true
    }

    /// Play the downloaded audio.
    func play() {
        guard let path = audioTour?.localAudioPath else { return }
        let url = downloadService.playbackURL(for: path)
        playerService.play(url: url)
    }

    /// Pause playback.
    func pause() {
        playerService.pause()
    }

    /// Restart playback from beginning.
    func restart() {
        guard let path = audioTour?.localAudioPath else { return }
        let url = downloadService.playbackURL(for: path)
        playerService.restart(url: url)
    }

    /// Skip forward 15 seconds.
    func skipForward() {
        playerService.skipForward(seconds: 15)
    }

    // MARK: - Private

    private func loadExistingTour() {
        let tid = tripId
        let sid = stopId
        let descriptor = FetchDescriptor<StoredAudioTour>(
            predicate: #Predicate { $0.tripId == tid && $0.stopId == sid }
        )
        audioTour = try? context.fetch(descriptor).first
    }
}
