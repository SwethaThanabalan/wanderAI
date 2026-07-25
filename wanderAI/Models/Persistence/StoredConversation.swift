import Foundation
import SwiftData

/// Persists an AI Assistant conversation so context survives tab switching,
/// navigation, app backgrounding, and relaunch.
/// Keyed by conversationId; optionally linked to a trip via tripId.
@Model
final class StoredConversation {
    @Attribute(.unique) var conversationId: String

    // Trip linkage
    var tripId: String?
    var tripName: String?

    // Active location context
    var destination: String?
    var region: String?
    var country: String?
    var currentStopId: String?
    var currentStopName: String?

    // Session
    var serverSessionId: String?

    // Personas
    var selectedPersonaIds: [String]

    // Trip dates
    var startDate: String?
    var endDate: String?

    // Collected places (names/IDs of accepted stops)
    var collectedPlaces: [String]

    // Messages stored as JSON-encoded array
    var messagesJSON: Data

    // Timestamps
    var createdAt: Date
    var lastUpdatedAt: Date

    // Status
    var isActive: Bool

    init(
        conversationId: String = UUID().uuidString,
        tripId: String? = nil,
        tripName: String? = nil,
        destination: String? = nil,
        region: String? = nil,
        country: String? = nil,
        currentStopId: String? = nil,
        currentStopName: String? = nil,
        serverSessionId: String? = nil,
        selectedPersonaIds: [String] = ["planner"],
        startDate: String? = nil,
        endDate: String? = nil,
        collectedPlaces: [String] = [],
        messagesJSON: Data = Data(),
        createdAt: Date = .now,
        lastUpdatedAt: Date = .now,
        isActive: Bool = true
    ) {
        self.conversationId = conversationId
        self.tripId = tripId
        self.tripName = tripName
        self.destination = destination
        self.region = region
        self.country = country
        self.currentStopId = currentStopId
        self.currentStopName = currentStopName
        self.serverSessionId = serverSessionId
        self.selectedPersonaIds = selectedPersonaIds
        self.startDate = startDate
        self.endDate = endDate
        self.collectedPlaces = collectedPlaces
        self.messagesJSON = messagesJSON
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.isActive = isActive
    }
}

// MARK: - Codable Message for Persistence

/// Lightweight message struct for JSON serialization inside StoredConversation.
struct PersistedMessage: Codable {
    let id: String
    let role: String
    let content: String
    let persona: String?
    let timestamp: Date

    init(from chatMessage: ChatMessage) {
        self.id = chatMessage.id
        self.role = chatMessage.role
        self.content = chatMessage.content
        self.persona = chatMessage.persona
        self.timestamp = chatMessage.timestamp
    }

    func toChatMessage() -> ChatMessage {
        ChatMessage(
            id: id,
            role: role,
            content: content,
            persona: persona,
            timestamp: timestamp
        )
    }
}
