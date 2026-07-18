import Foundation
import SwiftData

/// Tracks the execution progress of a trip, kept separate from the imported data.
@Model
final class TripExecutionState {
    @Attribute(.unique) var tripId: String
    var status: String // "notStarted", "inProgress", "completed"
    var activeDayId: String?
    var currentStopId: String?
    var startedAt: Date?
    var completedAt: Date?

    @Relationship(deleteRule: .cascade)
    var stopStates: [StopExecutionState]

    init(
        tripId: String,
        status: String = "notStarted",
        activeDayId: String? = nil,
        currentStopId: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        stopStates: [StopExecutionState] = []
    ) {
        self.tripId = tripId
        self.status = status
        self.activeDayId = activeDayId
        self.currentStopId = currentStopId
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.stopStates = stopStates
    }
}
