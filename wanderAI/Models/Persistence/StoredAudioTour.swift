import Foundation
import SwiftData

/// Persists audio tour job state for a specific trip + stop combination.
@Model
final class StoredAudioTour {
    @Attribute(.unique) var jobId: String
    var tripId: String
    var stopId: String
    var destinationName: String
    var durationMinutes: Int
    var selectedPersonas: [String]
    var status: String
    var localAudioPath: String?
    var createdAt: Date
    var lastStatusCheckedAt: Date?
    var downloadedAt: Date?

    init(
        jobId: String,
        tripId: String,
        stopId: String,
        destinationName: String,
        durationMinutes: Int,
        selectedPersonas: [String],
        status: String,
        localAudioPath: String? = nil,
        createdAt: Date = .now,
        lastStatusCheckedAt: Date? = nil,
        downloadedAt: Date? = nil
    ) {
        self.jobId = jobId
        self.tripId = tripId
        self.stopId = stopId
        self.destinationName = destinationName
        self.durationMinutes = durationMinutes
        self.selectedPersonas = selectedPersonas
        self.status = status
        self.localAudioPath = localAudioPath
        self.createdAt = createdAt
        self.lastStatusCheckedAt = lastStatusCheckedAt
        self.downloadedAt = downloadedAt
    }
}
