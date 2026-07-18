import Foundation
import SwiftData

/// Stores the user's travel preferences locally. Only one active profile at a time in P0.
@Model
final class StoredPreferences {
    @Attribute(.unique) var profileId: String
    var rawJSON: Data
    var updatedAt: Date

    init(
        profileId: String = "default",
        rawJSON: Data,
        updatedAt: Date = .now
    ) {
        self.profileId = profileId
        self.rawJSON = rawJSON
        self.updatedAt = updatedAt
    }
}
