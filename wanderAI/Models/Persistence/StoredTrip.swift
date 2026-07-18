import Foundation
import SwiftData

/// Stores the complete imported trip as raw JSON data alongside key metadata.
/// The raw payload is decoded on-demand to populate views.
@Model
final class StoredTrip {
    @Attribute(.unique) var tripId: String
    var name: String
    var primaryDestination: String?
    var startDate: String?
    var endDate: String?
    var numberOfDays: Int
    var coverImageAsset: String?
    var isSample: Bool
    var importedAt: Date

    /// The full JSON payload stored as Data for reliable round-tripping.
    var rawJSON: Data

    init(
        tripId: String,
        name: String,
        primaryDestination: String?,
        startDate: String?,
        endDate: String?,
        numberOfDays: Int,
        coverImageAsset: String?,
        isSample: Bool,
        importedAt: Date = .now,
        rawJSON: Data
    ) {
        self.tripId = tripId
        self.name = name
        self.primaryDestination = primaryDestination
        self.startDate = startDate
        self.endDate = endDate
        self.numberOfDays = numberOfDays
        self.coverImageAsset = coverImageAsset
        self.isSample = isSample
        self.importedAt = importedAt
        self.rawJSON = rawJSON
    }
}
