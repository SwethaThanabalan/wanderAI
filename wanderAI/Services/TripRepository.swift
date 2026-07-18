import Foundation
import SwiftData

/// Provides access to locally stored trips.
@MainActor
final class TripRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [StoredTrip] {
        let descriptor = FetchDescriptor<StoredTrip>(
            sortBy: [SortDescriptor(\.importedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func trip(for id: String) -> StoredTrip? {
        let descriptor = FetchDescriptor<StoredTrip>(
            predicate: #Predicate { $0.tripId == id }
        )
        return try? context.fetch(descriptor).first
    }

    func delete(_ trip: StoredTrip) {
        context.delete(trip)
        try? context.save()
    }

    /// Decodes the full trip payload from stored raw JSON.
    func decodeTripPayload(_ trip: StoredTrip) -> TripPayload? {
        guard let document = try? JSONDecoder().decode(TripImportDocument.self, from: trip.rawJSON) else {
            return nil
        }
        return document.trip
    }
}
