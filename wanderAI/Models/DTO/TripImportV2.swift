import Foundation

// MARK: - V2 Schema Root

/// Decodes the v2 trip JSON schema (schemaVersion: "2.0.0").
/// Converts to the existing TripImportDocument for unified downstream handling.
struct TripImportV2Root: Decodable {
    let schemaVersion: String
    let trip: TripImportV2Trip
}

struct TripImportV2Trip: Decodable {
    let id: String
    let name: String
    let subtitle: String?
    let primaryDestination: String?
    let startDate: String?
    let endDate: String?
    let durationDays: Int?
    let timezone: String?
    let travelParty: V2TravelParty?
    let hero: V2Hero?
    let days: [V2Day]
    let locations: [V2Location]?
}

struct V2TravelParty: Decodable {
    let adults: Int?
    let children: Int?
    let pets: AnyCodable? // Can be Int or array
}

struct V2Hero: Decodable {
    let title: String?
    let subtitle: String?
    let heroImageAsset: String?
}

struct V2Day: Decodable {
    let id: String
    let dayNumber: Int
    let date: String?
    let title: String
    let summary: V2DaySummary?
    let stops: [V2Stop]
}

struct V2DaySummary: Decodable {
    let estimatedDrivingMinutes: Int?
    let estimatedWalkingMiles: Double?
}

struct V2Stop: Decodable {
    let id: String
    let sequence: Int
    let title: String
    let kind: String?
    let locationId: String?
    let estimatedDurationMinutes: Int?
    let summary: String?
    let highlights: [String]?
    let tips: [String]?
    let scheduledStart: String?
    let walking: V2Walking?
    let suitability: V2Suitability?
}

struct V2Walking: Decodable {
    let distanceMiles: Double?
    let difficulty: String?
    let surface: String?
    let estimatedMinutes: Int?
}

struct V2Suitability: Decodable {
    let dogFriendly: AnyCodable? // Can be Bool or object
    let kidFriendly: AnyCodable?
    let olderAdultFriendly: AnyCodable?
    let wheelchairAccess: String?
}

struct V2Location: Decodable {
    let id: String
    let name: String
    let category: String?
    let address: String?
    let coordinates: V2Coordinates?
}

struct V2Coordinates: Decodable {
    let latitude: Double
    let longitude: Double
}

// MARK: - Flexible Codable for mixed types

/// Handles JSON values that can be different types (Bool, Int, String, etc.)
enum AnyCodable: Decodable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            self = .null
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let b): return b
        default: return nil
        }
    }
}

// MARK: - Conversion to V1

extension TripImportV2Root {
    /// Converts the v2 schema into the existing TripImportDocument format.
    func toV1Document() -> TripImportDocument {
        let locationMap = Dictionary(
            uniqueKeysWithValues: (trip.locations ?? []).map { ($0.id, $0) }
        )

        let days: [DayPayload] = trip.days.map { day in
            let stops: [StopPayload] = day.stops.map { stop in
                let location = stop.locationId.flatMap { locationMap[$0] }
                let coords = location?.coordinates

                let mapRef = MapReference(
                    latitude: coords?.latitude ?? 0,
                    longitude: coords?.longitude ?? 0,
                    formattedAddress: location?.address,
                    placeId: nil,
                    mapLabel: location?.name ?? stop.title,
                    pinStyle: nil
                )

                // Extract time from scheduledStart if available
                let plannedTime: String? = stop.scheduledStart.flatMap { iso in
                    // Extract HH:mm from ISO string
                    if let tIndex = iso.firstIndex(of: "T") {
                        let timeStart = iso.index(after: tIndex)
                        let timeStr = String(iso[timeStart...])
                        // Take first 5 chars (HH:mm)
                        if timeStr.count >= 5 {
                            return String(timeStr.prefix(5))
                        }
                    }
                    return nil
                }

                return StopPayload(
                    id: stop.id,
                    sequence: stop.sequence,
                    name: stop.title,
                    category: stop.kind,
                    plannedTime: plannedTime,
                    estimatedDurationMinutes: stop.estimatedDurationMinutes,
                    summary: stop.summary,
                    description: nil,
                    history: nil,
                    mapReference: mapRef,
                    heroImage: nil,
                    gallery: nil,
                    mustDo: nil,
                    highlights: stop.highlights,
                    practicalInformation: nil,
                    suitability: nil,
                    reviews: nil,
                    travelerTips: nil,
                    tags: nil,
                    community: nil
                )
            }

            let drivingMiles = day.summary?.estimatedDrivingMinutes.map { Double($0) * 0.75 }

            return DayPayload(
                id: day.id,
                dayNumber: day.dayNumber,
                date: day.date,
                title: day.title,
                summary: nil,
                plannedDistanceMiles: drivingMiles,
                estimatedDrivingMinutes: day.summary?.estimatedDrivingMinutes,
                stops: stops,
                routeHighlights: nil
            )
        }

        let tripPayload = TripPayload(
            id: trip.id,
            name: trip.name,
            summary: trip.subtitle,
            primaryDestination: trip.primaryDestination,
            startDate: trip.startDate,
            endDate: trip.endDate,
            timeZone: trip.timezone,
            coverImage: nil,
            travelGroup: nil,
            suitability: nil,
            plannedDistanceMiles: nil,
            highlights: nil,
            days: days,
            community: nil,
            metadata: nil
        )

        return TripImportDocument(
            format: "wanderAI.trip",
            formatVersion: "1.0.0",
            generatedAt: nil,
            generator: nil,
            trip: tripPayload
        )
    }
}
