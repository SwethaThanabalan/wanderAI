import Foundation

// MARK: - Root Preference Export

struct PreferenceExportDocument: Codable {
    let format: String
    let formatVersion: String
    let exportedAt: String
    let preferences: PreferencePayload
}

// MARK: - Preferences

struct PreferencePayload: Codable {
    let travelerComposition: TravelerComposition?
    let travelStyle: TravelStylePrefs?
    let interests: [InterestItem]?
    let accessibility: AccessibilityPrefs?
    let petPreferences: PetPrefs?
    let kidPreferences: KidPrefs?
    let olderAdultPreferences: OlderAdultPrefs?
    let foodPreferences: FoodPrefs?
    let drivingPreferences: DrivingPrefs?
    let accommodationPreferences: AccommodationPrefs?
    let destinationPreferences: DestinationPrefs?
    let avoidances: [String]?
    let notesForPlanner: String?
}

struct TravelerComposition: Codable {
    let defaultGroupType: String?
    let adultCount: Int?
    let childCount: Int?
    let olderAdultCount: Int?
    let travelsWithPets: Bool?
}

struct TravelStylePrefs: Codable {
    let pace: String?
    let spontaneity: String?
    let preferredDailyStartTime: String?
    let preferredDailyEndTime: String?
    let maximumActivitiesPerDay: Int?
}

struct InterestItem: Codable {
    let name: String
    let priority: String?
}

struct AccessibilityPrefs: Codable {
    let wheelchairAccessRequired: Bool?
    let avoidStairs: Bool?
    let minimalWalking: Bool?
    let frequentSeating: Bool?
    let frequentRestroomStops: Bool?
    let maximumWalkingMilesPerDay: Double?
    let additionalNotes: String?
}

struct PetPrefs: Codable {
    let travelingWithDog: Bool?
    let dogSize: String?
    let leashFriendlyLocationsAccepted: Bool?
    let dogFriendlyTrailsPreferred: Bool?
    let dogParksPreferred: Bool?
    let petFriendlyDiningPreferred: Bool?
    let avoidPetRestrictedStops: Bool?
}

struct KidPrefs: Codable {
    let travelingWithChildren: Bool?
    let childAgeRanges: [String]?
    let strollerAccessRequired: Bool?
    let playgroundsPreferred: Bool?
    let familyRestroomsPreferred: Bool?
    let napFriendlySchedule: Bool?
}

struct OlderAdultPrefs: Codable {
    let travelingWithOlderAdults: Bool?
    let minimalStairsPreferred: Bool?
    let benchesPreferred: Bool?
    let pavedPathsPreferred: Bool?
    let accessibleParkingPreferred: Bool?
    let frequentRestroomsPreferred: Bool?
}

struct FoodPrefs: Codable {
    let dietaryRestrictions: [String]?
    let preferredCuisines: [String]?
    let avoidedFoods: [String]?
    let diningStyle: [String]?
    let localCoffeePreferred: Bool?
}

struct DrivingPrefs: Codable {
    let maximumDrivingMinutesPerDay: Int?
    let scenicRoutesPreferred: Bool?
    let avoidTolls: Bool?
    let avoidFerries: Bool?
    let avoidUnpavedRoads: Bool?
    let comfortableWithMountainRoads: Bool?
    let frequentDrivingBreaks: Bool?
}

struct AccommodationPrefs: Codable {
    let preferredTypes: [String]?
    let minimumNightsPerBase: Int?
    let petFriendlyRequired: Bool?
    let parkingRequired: Bool?
    let kitchenPreferred: Bool?
}

struct DestinationPrefs: Codable {
    let preferredDestinationTypes: [String]?
    let hiddenGemsPreferred: Bool?
    let popularAttractionsAccepted: Bool?
    let crowdTolerance: String?
    let sunriseActivitiesPreferred: Bool?
    let sunsetActivitiesPreferred: Bool?
}
