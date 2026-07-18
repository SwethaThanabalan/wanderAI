import Foundation
import SwiftData
import MapKit

/// ViewModel for the map-first trip experience.
@MainActor
@Observable
final class TripMapViewModel {
    let storedTrip: StoredTrip
    private let context: ModelContext

    var tripPayload: TripPayload?
    var executionState: TripExecutionState?
    var selectedDayIndex: Int = 0

    // MARK: - Computed

    var tripName: String { storedTrip.name }

    var selectedDay: DayPayload? {
        guard let days = tripPayload?.days, selectedDayIndex < days.count else { return nil }
        return days[selectedDayIndex]
    }

    var totalStops: Int {
        tripPayload?.days.reduce(0) { $0 + $1.stops.count } ?? 0
    }

    var completedStops: Int {
        executionState?.stopStates.filter { $0.status == "completed" }.count ?? 0
    }

    var progress: Double {
        totalStops > 0 ? Double(completedStops) / Double(totalStops) : 0
    }

    var actionButtonLabel: String {
        switch executionState?.status {
        case "inProgress": return "Resume Adventure"
        case "completed": return "View Completed Trip"
        default: return "Start Adventure"
        }
    }

    // MARK: - Map Annotations

    var stopAnnotations: [StopAnnotation] {
        guard let day = selectedDay else { return [] }
        return day.stops.map { stop in
            StopAnnotation(
                id: stop.id,
                name: stop.name,
                coordinate: CLLocationCoordinate2D(
                    latitude: stop.mapReference.latitude,
                    longitude: stop.mapReference.longitude
                ),
                sequence: stop.sequence,
                status: stopStatus(for: stop.id)
            )
        }
    }

    var highlightAnnotations: [HighlightAnnotation] {
        guard let day = selectedDay, let highlights = day.routeHighlights else { return [] }
        return highlights.map { hl in
            HighlightAnnotation(
                id: hl.id,
                name: hl.name,
                coordinate: CLLocationCoordinate2D(
                    latitude: hl.mapReference.latitude,
                    longitude: hl.mapReference.longitude
                ),
                category: hl.category ?? "other"
            )
        }
    }

    // MARK: - Init

    init(storedTrip: StoredTrip, context: ModelContext) {
        self.storedTrip = storedTrip
        self.context = context
        loadTrip()
        loadExecutionState()
    }

    // MARK: - Actions

    func startOrResumeTrip() {
        guard let trip = tripPayload else { return }
        let service = AppContainer.tripExecutionService(context: context)
        executionState = try? service.startTrip(tripId: storedTrip.tripId, days: trip.days)
    }

    func stopStatus(for stopId: String) -> String {
        executionState?.stopStates.first(where: { $0.stopId == stopId })?.status ?? "planned"
    }

    // MARK: - Private

    private func loadTrip() {
        let repo = AppContainer.tripRepository(context: context)
        tripPayload = repo.decodeTripPayload(storedTrip)
        if let trip = tripPayload {
            print("[wanderAI] ✅ Trip decoded: \(trip.name), \(trip.days.count) days, \(trip.days.flatMap(\.stops).count) stops")
        } else {
            print("[wanderAI] ❌ Failed to decode trip from rawJSON (\(storedTrip.rawJSON.count) bytes)")
        }
    }

    private func loadExecutionState() {
        let service = AppContainer.tripExecutionService(context: context)
        executionState = service.executionState(for: storedTrip.tripId)
    }
}

// MARK: - Annotation Models

struct StopAnnotation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let sequence: Int
    let status: String
}

struct HighlightAnnotation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: String
}
