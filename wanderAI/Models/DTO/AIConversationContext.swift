import Foundation

// MARK: - AI Conversation Context

/// Structured context sent with every chat message so the backend can ground
/// follow-up questions against the active trip, destination, and conversation state.
/// This prevents "Best photo spots" from returning Boston when the user is planning North Cascades.
struct AIConversationContext: Codable, Equatable {
    /// Unique conversation identifier (persisted locally and on server).
    var conversationId: String

    // MARK: - Trip Context

    var tripId: String?
    var tripName: String?
    var country: String?
    var state: String?
    var destination: String?

    // MARK: - Current Stop (most local reference)

    var currentStopId: String?
    var currentStopName: String?

    // MARK: - Personas

    var selectedPersonaIds: [String]

    // MARK: - Trip Dates

    var tripDates: TripDates?

    // MARK: - Traveler Preferences

    var travelerPreferences: TravelerPreferences?

    // MARK: - Collected Places & Itinerary

    /// Names of places the user has accepted/added to the trip board.
    var collectedPlaces: [String]

    /// Summary of existing itinerary (day → stop names) for grounding.
    var itinerarySummary: [ItinerarySummaryDay]?

    // MARK: - Recent Conversation (sliding window for grounding)

    /// Last N messages for pronoun/reference resolution. Kept small to avoid
    /// exceeding context window. Server may also have full history by session.
    var recentConversation: [ConversationTurn]?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case tripId = "trip_id"
        case tripName = "trip_name"
        case country, state, destination
        case currentStopId = "current_stop_id"
        case currentStopName = "current_stop_name"
        case selectedPersonaIds = "selected_persona_ids"
        case tripDates = "trip_dates"
        case travelerPreferences = "traveler_preferences"
        case collectedPlaces = "collected_places"
        case itinerarySummary = "itinerary_summary"
        case recentConversation = "recent_conversation"
    }
}

// MARK: - Supporting Types

struct TripDates: Codable, Equatable {
    var start: String?
    var end: String?
}

struct TravelerPreferences: Codable, Equatable {
    var foodPreferences: [String]?
    var accessibilityNeeds: [String]?
    var travelStyle: [String]?
    var mobility: String?
    var travelingWithDog: Bool?
    var travelingWithKids: Bool?
    var travelingWithElders: Bool?

    enum CodingKeys: String, CodingKey {
        case mobility
        case foodPreferences = "food_preferences"
        case accessibilityNeeds = "accessibility_needs"
        case travelStyle = "travel_style"
        case travelingWithDog = "traveling_with_dog"
        case travelingWithKids = "traveling_with_kids"
        case travelingWithElders = "traveling_with_elders"
    }
}

struct ItinerarySummaryDay: Codable, Equatable {
    let day: Int
    let stops: [String]
}

struct ConversationTurn: Codable, Equatable {
    let role: String
    let content: String
    let persona: String?
}

// MARK: - Resolved Context (returned by backend)

/// Backend tells the frontend what context it resolved so the UI stays in sync.
struct ResolvedContext: Decodable, Equatable {
    let destination: String?
    let state: String?
    let currentStopId: String?
    let currentStopName: String?
    let selectedPersonaIds: [String]?

    enum CodingKeys: String, CodingKey {
        case destination, state
        case currentStopId = "current_stop_id"
        case currentStopName = "current_stop_name"
        case selectedPersonaIds = "selected_persona_ids"
    }
}

/// Flags indicating what changed in the backend's resolved context.
struct ContextUpdates: Decodable, Equatable {
    let destinationChanged: Bool?
    let currentStopChanged: Bool?

    enum CodingKeys: String, CodingKey {
        case destinationChanged = "destination_changed"
        case currentStopChanged = "current_stop_changed"
    }
}

// MARK: - Context Status

/// Tracks whether the local conversation context is valid.
enum AIContextStatus: String, Codable {
    /// Context is valid and synced with the active trip.
    case active
    /// Trip was deleted or changed; context needs re-selection.
    case stale
    /// No trip/destination set; user should pick one for travel questions.
    case noTrip
}
