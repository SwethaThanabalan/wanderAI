import Foundation
import SwiftData

/// A user-created review for a specific destination/stop.
@Model
final class LocalDestinationReview {
    @Attribute(.unique) var reviewId: String
    var tripId: String
    var stopId: String
    var overallRating: Int
    var reviewText: String?
    var dogFriendlinessRating: Int?
    var kidFriendlinessRating: Int?
    var olderAdultSuitabilityRating: Int?
    var accessibilityRating: Int?
    var crowdLevel: String?
    var visitDate: String?
    var createdAt: Date

    init(
        reviewId: String = UUID().uuidString,
        tripId: String,
        stopId: String,
        overallRating: Int,
        reviewText: String? = nil,
        dogFriendlinessRating: Int? = nil,
        kidFriendlinessRating: Int? = nil,
        olderAdultSuitabilityRating: Int? = nil,
        accessibilityRating: Int? = nil,
        crowdLevel: String? = nil,
        visitDate: String? = nil,
        createdAt: Date = .now
    ) {
        self.reviewId = reviewId
        self.tripId = tripId
        self.stopId = stopId
        self.overallRating = overallRating
        self.reviewText = reviewText
        self.dogFriendlinessRating = dogFriendlinessRating
        self.kidFriendlinessRating = kidFriendlinessRating
        self.olderAdultSuitabilityRating = olderAdultSuitabilityRating
        self.accessibilityRating = accessibilityRating
        self.crowdLevel = crowdLevel
        self.visitDate = visitDate
        self.createdAt = createdAt
    }
}
