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
}

struct PersonasResponse: Decodable {
    let personas: [ChatPersona]
}

// MARK: - Chat Message (local UI model)

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: String
    let content: String
    let persona: String?
    let suggestions: [String]?
    let tripUpdates: [TripUpdate]?
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        role: String,
        content: String,
        persona: String? = nil,
        suggestions: [String]? = nil,
        tripUpdates: [TripUpdate]? = nil,
        timestamp: Date = .now
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.persona = persona
        self.suggestions = suggestions
        self.tripUpdates = tripUpdates
        self.timestamp = timestamp
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
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

struct CreateSessionRequest: Encodable {
    let personas: [String]
    let tripContext: ChatTripContext?

    enum CodingKeys: String, CodingKey {
        case personas
        case tripContext = "trip_context"
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
}

struct SessionMessageResponse: Decodable {
    let consolidated: String?
    let reply: String?
    let persona: String?
    let suggestions: [String]?
    let tripUpdates: [TripUpdate]?
    let allSuggestions: [String]?
    let allTripUpdates: [TripUpdate]?

    enum CodingKeys: String, CodingKey {
        case consolidated, reply, persona, suggestions
        case tripUpdates = "trip_updates"
        case allSuggestions = "all_suggestions"
        case allTripUpdates = "all_trip_updates"
    }

    /// The main text content — prefers consolidated (multi), falls back to reply (single).
    var responseText: String {
        consolidated ?? reply ?? ""
    }

    /// All suggestions from any format.
    var combinedSuggestions: [String]? {
        let s = (allSuggestions ?? []) + (suggestions ?? [])
        return s.isEmpty ? nil : s
    }

    /// All trip updates from any format.
    var combinedTripUpdates: [TripUpdate]? {
        let u = (allTripUpdates ?? []) + (tripUpdates ?? [])
        return u.isEmpty ? nil : u
    }
}

struct AcceptStopRequest: Encodable {
    let stopName: String
    let day: Int?
    let time: String?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case stopName = "stop_name"
        case day, time, category
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
