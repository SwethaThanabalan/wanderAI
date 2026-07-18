import Foundation
import SwiftData

/// Manages local user reviews for destinations and trips.
@MainActor
final class ReviewRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Destination Reviews

    func destinationReview(tripId: String, stopId: String) -> LocalDestinationReview? {
        let descriptor = FetchDescriptor<LocalDestinationReview>(
            predicate: #Predicate { $0.tripId == tripId && $0.stopId == stopId }
        )
        return try? context.fetch(descriptor).first
    }

    func saveDestinationReview(_ review: LocalDestinationReview) throws {
        context.insert(review)
        try context.save()
    }

    func deleteDestinationReview(_ review: LocalDestinationReview) throws {
        context.delete(review)
        try context.save()
    }

    // MARK: - Trip Reviews

    func tripReview(for tripId: String) -> LocalTripReview? {
        let descriptor = FetchDescriptor<LocalTripReview>(
            predicate: #Predicate { $0.tripId == tripId }
        )
        return try? context.fetch(descriptor).first
    }

    func saveTripReview(_ review: LocalTripReview) throws {
        context.insert(review)
        try context.save()
    }

    func deleteTripReview(_ review: LocalTripReview) throws {
        context.delete(review)
        try context.save()
    }
}
