import Foundation
import SwiftData

/// Tracks the status of an individual stop during trip execution.
@Model
final class StopExecutionState {
    var stopId: String
    var status: String // "planned", "current", "completed", "skipped", "moved", "removed"
    var completedAt: Date?
    var originalDayId: String
    var activeDayId: String
    var activeSequence: Int
    var skipReason: String?

    var tripExecution: TripExecutionState?

    init(
        stopId: String,
        status: String = "planned",
        completedAt: Date? = nil,
        originalDayId: String,
        activeDayId: String,
        activeSequence: Int,
        skipReason: String? = nil
    ) {
        self.stopId = stopId
        self.status = status
        self.completedAt = completedAt
        self.originalDayId = originalDayId
        self.activeDayId = activeDayId
        self.activeSequence = activeSequence
        self.skipReason = skipReason
    }
}
