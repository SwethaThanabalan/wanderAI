import Foundation
import SwiftData

/// A user-created review for the overall trip.
@Model
final class LocalTripReview {
    @Attribute(.unique) var reviewId: String
    var tripId: String
    var overallRating: Int
    var itineraryQuality: Int?
    var paceRating: Int?
    var routeQuality: Int?
    var groupSuitability: Int?
    var favoriteDestinationId: String?
    var summary: String?
    var createdAt: Date

    init(
        reviewId: String = UUID().uuidString,
        tripId: String,
        overallRating: Int,
        itineraryQuality: Int? = nil,
        paceRating: Int? = nil,
        routeQuality: Int? = nil,
        groupSuitability: Int? = nil,
        favoriteDestinationId: String? = nil,
        summary: String? = nil,
        createdAt: Date = .now
    ) {
        self.reviewId = reviewId
        self.tripId = tripId
        self.overallRating = overallRating
        self.itineraryQuality = itineraryQuality
        self.paceRating = paceRating
        self.routeQuality = routeQuality
        self.groupSuitability = groupSuitability
        self.favoriteDestinationId = favoriteDestinationId
        self.summary = summary
        self.createdAt = createdAt
    }
}
