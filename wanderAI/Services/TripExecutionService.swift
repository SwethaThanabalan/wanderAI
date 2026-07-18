import Foundation
import SwiftData

/// Manages trip execution state: starting, completing stops, skipping, rescheduling.
@MainActor
final class TripExecutionService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func executionState(for tripId: String) -> TripExecutionState? {
        let descriptor = FetchDescriptor<TripExecutionState>(
            predicate: #Predicate { $0.tripId == tripId }
        )
        return try? context.fetch(descriptor).first
    }

    func startTrip(tripId: String, days: [DayPayload]) throws -> TripExecutionState {
        if let existing = executionState(for: tripId) {
            return existing
        }

        let state = TripExecutionState(
            tripId: tripId,
            status: "inProgress",
            activeDayId: days.first?.id,
            currentStopId: days.first?.stops.first?.id,
            startedAt: .now
        )

        // Create stop states for all stops
        var stopStates: [StopExecutionState] = []
        for day in days {
            for stop in day.stops {
                let stopState = StopExecutionState(
                    stopId: stop.id,
                    status: stop.id == state.currentStopId ? "current" : "planned",
                    originalDayId: day.id,
                    activeDayId: day.id,
                    activeSequence: stop.sequence
                )
                stopStates.append(stopState)
            }
        }
        state.stopStates = stopStates

        context.insert(state)
        try context.save()
        return state
    }

    func completeStop(tripId: String, stopId: String) throws {
        guard let state = executionState(for: tripId) else { return }

        if let stopState = state.stopStates.first(where: { $0.stopId == stopId }) {
            stopState.status = "completed"
            stopState.completedAt = .now
        }

        // Advance to next planned stop
        let activeDayId = state.activeDayId ?? ""
        let dayStops = state.stopStates
            .filter { $0.activeDayId == activeDayId && $0.status == "planned" }
            .sorted { $0.activeSequence < $1.activeSequence }

        if let next = dayStops.first {
            next.status = "current"
            state.currentStopId = next.stopId
        } else {
            state.currentStopId = nil
        }

        try context.save()
    }

    func skipStop(tripId: String, stopId: String, reason: String?) throws {
        guard let state = executionState(for: tripId) else { return }

        if let stopState = state.stopStates.first(where: { $0.stopId == stopId }) {
            stopState.status = "skipped"
            stopState.skipReason = reason
        }

        // Advance current if needed
        if state.currentStopId == stopId {
            let activeDayId = state.activeDayId ?? ""
            let dayStops = state.stopStates
                .filter { $0.activeDayId == activeDayId && $0.status == "planned" }
                .sorted { $0.activeSequence < $1.activeSequence }

            if let next = dayStops.first {
                next.status = "current"
                state.currentStopId = next.stopId
            } else {
                state.currentStopId = nil
            }
        }

        try context.save()
    }
}
