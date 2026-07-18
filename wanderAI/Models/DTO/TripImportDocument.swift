import Foundation

// MARK: - Root Import Document

struct TripImportDocument: Codable {
    let format: String
    let formatVersion: String
    let generatedAt: String?
    let generator: GeneratorInfo?
    let trip: TripPayload
}

struct GeneratorInfo: Codable {
    let type: String?
    let name: String?
    let version: String?
}

// MARK: - Trip

struct TripPayload: Codable {
    let id: String
    let name: String
    let summary: String?
    let primaryDestination: String?
    let startDate: String?
    let endDate: String?
    let timeZone: String?
    let coverImage: ImageReference?
    let travelGroup: TravelGroup?
    let suitability: SuitabilityInfo?
    let plannedDistanceMiles: Double?
    let highlights: [String]?
    let days: [DayPayload]
    let community: CommunityData?
    let metadata: TripMetadata?
}

// MARK: - Image Reference

struct ImageReference: Codable {
    let type: String // "asset" or "remote"
    let value: String
    let altText: String?
}

// MARK: - Travel Group

struct TravelGroup: Codable {
    let adults: Int?
    let children: Int?
    let olderAdults: Int?
    let pets: [PetInfo]?
}

struct PetInfo: Codable {
    let type: String
    let name: String?
    let size: String?
}

// MARK: - Suitability

struct SuitabilityInfo: Codable {
    let dogFriendly: SuitabilityDimension?
    let kidFriendly: SuitabilityDimension?
    let olderAdultFriendly: SuitabilityDimension?
    let wheelchairAccessible: SuitabilityDimension?
    let strollerFriendly: SuitabilityDimension?
}

struct SuitabilityDimension: Codable {
    let status: String // "yes", "no", "partial", "unknown"
    let details: String?
}

// MARK: - Day

struct DayPayload: Codable {
    let id: String
    let dayNumber: Int
    let date: String?
    let title: String
    let summary: String?
    let plannedDistanceMiles: Double?
    let estimatedDrivingMinutes: Int?
    let stops: [StopPayload]
    let routeHighlights: [RouteHighlightPayload]?
}

// MARK: - Stop

struct StopPayload: Codable {
    let id: String
    let sequence: Int
    let name: String
    let category: String?
    let plannedTime: String?
    let estimatedDurationMinutes: Int?
    let summary: String?
    let description: String?
    let history: String?
    let mapReference: MapReference
    let heroImage: ImageReference?
    let gallery: [ImageReference]?
    let mustDo: [String]?
    let highlights: [String]?
    let practicalInformation: PracticalInformation?
    let suitability: SuitabilityInfo?
    let reviews: [ImportedReviewPayload]?
    let travelerTips: [TravelerTipPayload]?
    let tags: [String]?
    let community: CommunityData?
}

// MARK: - Map Reference

struct MapReference: Codable {
    let latitude: Double
    let longitude: Double
    let formattedAddress: String?
    let placeId: String?
    let mapLabel: String
    let pinStyle: String? // "start", "primary", "secondary", "end"
}

// MARK: - Practical Information

struct PracticalInformation: Codable {
    let openingHours: String?
    let admission: String?
    let parking: ParkingInfo?
    let restrooms: RestroomInfo?
    let phone: String?
    let website: String?
    let seasonality: String?
    let warnings: [String]?
}

struct ParkingInfo: Codable {
    let available: Bool?
    let details: String?
}

struct RestroomInfo: Codable {
    let available: Bool?
    let details: String?
}

// MARK: - Route Highlight

struct RouteHighlightPayload: Codable {
    let id: String
    let name: String
    let category: String?
    let description: String?
    let sequenceAfterStopId: String?
    let mapReference: MapReference
    let image: ImageReference?
    let estimatedDetourMinutes: Int?
    let optional: Bool?
    let popularity: PopularityInfo?
    let suitability: SuitabilityInfo?
}

struct PopularityInfo: Codable {
    let label: String?
    let score: Double?
}

// MARK: - Community Data

struct CommunityData: Codable {
    let aggregateRating: Double?
    let reviewCount: Int?
    let popularityLabel: String?
    let sourceLabel: String?
}

// MARK: - Imported Review

struct ImportedReviewPayload: Codable {
    let id: String
    let authorDisplayName: String?
    let authorType: String?
    let rating: Int?
    let title: String?
    let text: String?
    let visitSeason: String?
    let helpfulCount: Int?
    let source: String?
}

// MARK: - Traveler Tip

struct TravelerTipPayload: Codable {
    let id: String
    let authorDisplayName: String?
    let authorType: String?
    let text: String?
    let visitSeason: String?
    let helpfulCount: Int?
    let tags: [String]?
}

// MARK: - Trip Metadata

struct TripMetadata: Codable {
    let isSample: Bool?
    let notes: String?
}
