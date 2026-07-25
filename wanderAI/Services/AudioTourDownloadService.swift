import Foundation

/// Downloads audio tour episodes and saves them permanently under Application Support.
final class AudioTourDownloadService {
    private let session: URLSession
    private let apiService: AudioTourAPIService

    init(apiService: AudioTourAPIService, session: URLSession = .shared) {
        self.apiService = apiService
        self.session = session
    }

    /// Downloads the audio file for the given job and saves it permanently.
    /// Returns the local file path relative to Application Support.
    func downloadAudio(jobId: String) async throws -> String {
        guard let url = apiService.audioURL(for: jobId) else {
            throw AudioTourError.downloadFailed("Invalid audio URL")
        }

        let (tempURL, response) = try await session.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AudioTourError.downloadFailed("Server returned an error")
        }

        let permanentPath = try moveToPermanentStorage(tempURL: tempURL, jobId: jobId)
        return permanentPath
    }

    /// Checks if a downloaded audio file exists at the given path.
    func audioFileExists(at relativePath: String) -> Bool {
        let fullPath = absolutePath(for: relativePath)
        return FileManager.default.fileExists(atPath: fullPath.path)
    }

    /// Returns the full URL for playback from a relative path.
    func playbackURL(for relativePath: String) -> URL {
        absolutePath(for: relativePath)
    }

    // MARK: - Private

    private func moveToPermanentStorage(tempURL: URL, jobId: String) throws -> String {
        let fileManager = FileManager.default

        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw AudioTourError.fileSystemError("Cannot locate Application Support directory")
        }

        let audioDir = appSupport
            .appendingPathComponent("WanderAI", isDirectory: true)
            .appendingPathComponent("AudioTours", isDirectory: true)
            .appendingPathComponent(jobId, isDirectory: true)

        try fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)

        let destination = audioDir.appendingPathComponent("episode.mp3")

        // Remove existing file if re-downloading
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }

        try fileManager.moveItem(at: tempURL, to: destination)

        // Return relative path for storage
        return "WanderAI/AudioTours/\(jobId)/episode.mp3"
    }

    private func absolutePath(for relativePath: String) -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(relativePath)
    }
}
