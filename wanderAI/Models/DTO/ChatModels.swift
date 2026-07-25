import Foundation

// MARK: - Persona

struct ChatPersona: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String?
    let color: String?

    var systemIcon: String {
        switch id {
        case "planner": return "map.fill"
        case "foodie": return "fork.knife"
        case "photographer": return "camera.fill"
        case "historian": return "book.fill"
        case "geologist": return "mountain.2.fill"
        case "storyteller": return "text.book.closed.fill"
        default: return "sparkles"
        }
    }

    /// Returns the known identity metadata for this persona (display name, emoji, voice).
    var identity: PersonaIdentity {
        PersonaIdentity.lookup(id: id)
    }
}

struct PersonasResponse: Decodable {
    let personas: [ChatPersona]
}

// MARK: - Persona Identity (static rendering metadata)

/// Display metadata for rendering persona avatars and names in chat bubbles.
/// Matches the fixed set of personas returned by GET /v1/chat/personas.
struct PersonaIdentity: Equatable {
    let id: String
    let displayName: String
    let emoji: String
    let voice: String

    /// All known persona identities.
    static let all: [PersonaIdentity] = [
        PersonaIdentity(id: "planner", displayName: "Alex the Planner", emoji: "🗺️", voice: "Warm, organized, practical"),
        PersonaIdentity(id: "photographer", displayName: "Maya the Photographer", emoji: "📸", voice: "Passionate, dramatic about light"),
        PersonaIdentity(id: "historian", displayName: "Prof. Raj the Historian", emoji: "📜", voice: "Gossipy, dramatic storytelling"),
        PersonaIdentity(id: "geologist", displayName: "Dr. Sam the Geologist", emoji: "🪨", voice: "Giddy, nerdy, British energy"),
        PersonaIdentity(id: "foodie", displayName: "Priya the Foodie", emoji: "🍜", voice: "Unreasonably excited about food"),
        PersonaIdentity(id: "storyteller", displayName: "Ghost the Storyteller", emoji: "🌙", voice: "Atmospheric, builds suspense"),
    ]

    /// Look up a persona identity by ID. Returns a generic fallback for unknown IDs.
    static func lookup(id: String) -> PersonaIdentity {
        all.first(where: { $0.id == id }) ?? PersonaIdentity(
            id: id,
            displayName: id.capitalized,
            emoji: "✨",
            voice: "Friendly and helpful"
        )
    }
}

// MARK: - Chat Message (local UI model)

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: String
    let content: String
    let persona: String?
    let suggestions: [String]?
    let suggestedStops: [SuggestedStop]?
    let tripUpdates: [TripUpdate]?
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        role: String,
        content: String,
        persona: String? = nil,
        suggestions: [String]? = nil,
        suggestedStops: [SuggestedStop]? = nil,
        tripUpdates: [TripUpdate]? = nil,
        timestamp: Date = .now
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.persona = persona
        self.suggestions = suggestions
        self.suggestedStops = suggestedStops
        self.tripUpdates = tripUpdates
        self.timestamp = timestamp
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Group Chat Rendering Helpers

    /// Whether this message is from an assistant persona (vs. the user).
    var isAssistant: Bool { role == "assistant" }

    /// The persona identity for rendering avatar/emoji/name in group chat.
    /// Returns nil for user messages.
    var personaIdentity: PersonaIdentity? {
        guard isAssistant, let personaId = persona else { return nil }
        return PersonaIdentity.lookup(id: personaId)
    }

    /// Display label for the message sender: emoji + short name (e.g. "🍜 Priya").
    var senderLabel: String? {
        guard let identity = personaIdentity else { return nil }
        let shortName = identity.displayName.components(separatedBy: " the ").first
            ?? identity.displayName.components(separatedBy: " ").first
            ?? identity.displayName
        return "\(identity.emoji) \(shortName)"
    }
}

// MARK: - Trip Update

struct TripUpdate: Codable, Equatable {
    let action: String
    let description: String
    let data: TripUpdateData?
}

struct TripUpdateData: Codable, Equatable {
    let name: String?
    let day: Int?
    let time: String?
    let duration: String?
    let category: String?
}

// MARK: - Trip Context

struct ChatTripContext: Codable {
    var destination: String?
    var region: String?
    var startDate: String?
    var endDate: String?
    var travelers: Int?
    var interests: [String]?
    var existingStops: [String]?

    enum CodingKeys: String, CodingKey {
        case destination, region, travelers, interests
        case startDate = "start_date"
        case endDate = "end_date"
        case existingStops = "existing_stops"
    }
}

// MARK: - Session API Models

/// A planned stop entry for session creation (existing itinerary items).
struct CurrentPlanItem: Encodable {
    let name: String
    let day: Int?
    let time: String?
    let category: String?
}

/// User preferences sent with session creation for persona tuning.
struct UserPreferences: Encodable {
    var travelStyle: String?
    var pace: String?
    var budgetLevel: String?
    var groupType: String?
    var dietaryRestrictions: [String]?
    var fitnessLevel: String?
    var photographySkill: String?

    enum CodingKeys: String, CodingKey {
        case pace
        case travelStyle = "travel_style"
        case budgetLevel = "budget_level"
        case groupType = "group_type"
        case dietaryRestrictions = "dietary_restrictions"
        case fitnessLevel = "fitness_level"
        case photographySkill = "photography_skill"
    }
}

struct CreateSessionRequest: Encodable {
    let personas: [String]
    let tripContext: ChatTripContext?
    let currentPlan: [CurrentPlanItem]?
    let userPreferences: UserPreferences?

    enum CodingKeys: String, CodingKey {
        case personas
        case tripContext = "trip_context"
        case currentPlan = "current_plan"
        case userPreferences = "user_preferences"
    }
}

struct CreateSessionResponse: Decodable {
    let sessionId: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
    }
}

struct SessionMessageRequest: Encodable {
    let message: String
    let conversationId: String?
    let context: AIConversationContext?
    /// Full conversation history so the backend always has context for follow-ups.
    let conversationHistory: [[String: String]]?

    enum CodingKeys: String, CodingKey {
        case message
        case conversationId = "conversation_id"
        case context
        case conversationHistory = "conversation_history"
    }

    /// Convenience init for backward compatibility (message-only).
    init(message: String) {
        self.message = message
        self.conversationId = nil
        self.context = nil
        self.conversationHistory = nil
    }

    /// Full init with conversation context and history for grounded follow-ups.
    init(message: String, conversationId: String?, context: AIConversationContext?, conversationHistory: [[String: String]]?) {
        self.message = message
        self.conversationId = conversationId
        self.context = context
        self.conversationHistory = conversationHistory
    }
}

struct SessionMessageResponse: Decodable {
    /// The session this response belongs to.
    let sessionId: String?
    /// Conversation identifier for context continuity.
    let conversationId: String?
    /// Which persona is speaking (round-robin rotation handled server-side).
    let persona: String?
    /// The persona's expressive reply text.
    let reply: String?
    /// LocationCard suggestions rendered as tappable cards below the message.
    let suggestedStops: [SuggestedStop]?
    /// Trip modifications only present when user explicitly accepts something.
    let tripUpdates: [TripUpdate]?
    /// Backend-resolved context so the frontend stays aligned.
    let resolvedContext: ResolvedContext?
    /// Flags indicating which context fields changed.
    let contextUpdates: ContextUpdates?

    enum CodingKeys: String, CodingKey {
        case persona, reply
        case sessionId = "session_id"
        case conversationId = "conversation_id"
        case suggestedStops = "suggested_stops"
        case tripUpdates = "trip_updates"
        case resolvedContext = "resolved_context"
        case contextUpdates = "context_updates"
    }

    /// The main text content of the response.
    var responseText: String {
        reply ?? ""
    }
}

/// A fully-formed stop suggestion (LocationCard) from the backend with coordinates and metadata.
struct SuggestedStop: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let description: String?
    let category: String?
    let latitude: Double?
    let longitude: Double?
    let day: Int?
    let time: String?
    let durationMinutes: Int?
    let highlights: [String]?
    let rating: Double?
    let priceLevel: String?
    let address: String?
    let sourceUrl: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, description, category, latitude, longitude, day, time, highlights, rating, address
        case durationMinutes = "duration_minutes"
        case priceLevel = "price_level"
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
    }
}

struct AcceptStopRequest: Encodable {
    let stopName: String
    let day: Int?
    let time: String?
    let durationMinutes: Int?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case stopName = "stop_name"
        case day, time, category
        case durationMinutes = "duration_minutes"
    }
}

// MARK: - Legacy Models (fallback)

struct ChatRequest: Encodable {
    let message: String
    let persona: String
    let tripContext: ChatTripContext?
    let conversationHistory: [[String: String]]

    enum CodingKeys: String, CodingKey {
        case message, persona
        case tripContext = "trip_context"
        case conversationHistory = "conversation_history"
    }
}

struct ChatResponse: Decodable {
    let reply: String
    let persona: String?
    let suggestions: [String]?
    let tripUpdates: [TripUpdate]?

    enum CodingKeys: String, CodingKey {
        case reply, persona, suggestions
        case tripUpdates = "trip_updates"
    }
}

struct MultiChatRequest: Encodable {
    let message: String
    let personas: [String]
    let tripContext: ChatTripContext?
    let maxExchanges: Int

    enum CodingKeys: String, CodingKey {
        case message, personas
        case tripContext = "trip_context"
        case maxExchanges = "max_exchanges"
    }

    init(message: String, personas: [String], tripContext: ChatTripContext?, maxExchanges: Int = 2) {
        self.message = message
        self.personas = personas
        self.tripContext = tripContext
        self.maxExchanges = maxExchanges
    }
}

struct MultiChatResponse: Decodable {
    let consolidated: String
    let personaReplies: [PersonaReplyLine]?
    let allSuggestions: [String]?
    let allTripUpdates: [TripUpdate]?

    enum CodingKeys: String, CodingKey {
        case consolidated
        case personaReplies = "persona_replies"
        case allSuggestions = "all_suggestions"
        case allTripUpdates = "all_trip_updates"
    }
}

struct PersonaReplyLine: Decodable {
    let persona: String?
    let content: String?
}
