import Foundation
import SwiftData

/// Manages the active AI conversation lifecycle, local persistence, and context assembly.
/// Acts as the single source of truth for conversation state across tab switches,
/// navigation, and app relaunches.
///
/// Usage:
/// - Call `loadOrCreate(for:)` when the AI Assistant appears.
/// - Call `buildContext()` before sending each message.
/// - Call `applyResponse(_:)` after receiving a response to sync context.
/// - Call `save(messages:)` periodically to persist conversation state.
@MainActor
@Observable
final class AIConversationStore {
    // MARK: - Published State

    private(set) var conversationId: String?
    private(set) var destination: String?
    private(set) var region: String?
    private(set) var country: String?
    private(set) var tripId: String?
    private(set) var tripName: String?
    private(set) var currentStopId: String?
    private(set) var currentStopName: String?
    private(set) var contextStatus: AIContextStatus = .noTrip
    private(set) var lastSyncedAt: Date?

    var selectedPersonaIds: [String] = ["planner"]
    var collectedPlaces: [String] = []

    // MARK: - Private

    private var modelContext: ModelContext?
    private var storedConversation: StoredConversation?

    /// Maximum recent messages to include in context payload (sliding window).
    private let maxRecentMessages = 10

    // MARK: - Init

    init() {}

    /// Attach the SwiftData model context (called once during app setup).
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Lifecycle

    /// Loads an existing conversation for the given trip, or creates a new one.
    /// Pass nil tripId for the global "no trip" assistant tab.
    func loadOrCreate(tripId: String? = nil, tripName: String? = nil, destination: String? = nil, region: String? = nil, startDate: String? = nil, endDate: String? = nil) {
        guard let ctx = modelContext else { return }

        // Try to find an active conversation for this trip
        let targetTripId = tripId
        let predicate: Predicate<StoredConversation>

        if let tid = targetTripId {
            predicate = #Predicate<StoredConversation> { $0.tripId == tid && $0.isActive == true }
        } else {
            predicate = #Predicate<StoredConversation> { $0.tripId == nil && $0.isActive == true }
        }

        var descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.lastUpdatedAt, order: .reverse)])
        descriptor.fetchLimit = 1

        if let existing = try? ctx.fetch(descriptor).first {
            restoreFrom(existing)
            return
        }

        // Create new conversation
        let conversation = StoredConversation(
            tripId: tripId,
            tripName: tripName,
            destination: destination,
            region: region,
            selectedPersonaIds: ["planner"],
            startDate: startDate,
            endDate: endDate
        )
        ctx.insert(conversation)
        try? ctx.save()

        restoreFrom(conversation)
    }

    /// Restores local state from a persisted conversation.
    private func restoreFrom(_ stored: StoredConversation) {
        storedConversation = stored
        conversationId = stored.conversationId
        tripId = stored.tripId
        tripName = stored.tripName
        destination = stored.destination
        region = stored.region
        country = stored.country
        currentStopId = stored.currentStopId
        currentStopName = stored.currentStopName
        selectedPersonaIds = stored.selectedPersonaIds
        collectedPlaces = stored.collectedPlaces
        lastSyncedAt = stored.lastUpdatedAt

        if stored.destination != nil || stored.tripId != nil {
            contextStatus = .active
        } else {
            contextStatus = .noTrip
        }
    }

    /// Loads persisted messages for the current conversation.
    func loadPersistedMessages() -> [ChatMessage] {
        guard let stored = storedConversation,
              !stored.messagesJSON.isEmpty,
              let persisted = try? JSONDecoder().decode([PersistedMessage].self, from: stored.messagesJSON) else {
            return []
        }
        return persisted.map { $0.toChatMessage() }
    }

    // MARK: - Context Assembly

    /// Builds the structured context payload to send with the next message.
    func buildContext(messages: [ChatMessage]) -> AIConversationContext? {
        guard let convId = conversationId else { return nil }

        // Recent conversation turns (sliding window)
        let recentTurns: [ConversationTurn] = messages.suffix(maxRecentMessages).map { msg in
            ConversationTurn(role: msg.role, content: msg.content, persona: msg.persona)
        }

        return AIConversationContext(
            conversationId: convId,
            tripId: tripId,
            tripName: tripName,
            country: country,
            state: region,
            destination: destination,
            currentStopId: currentStopId,
            currentStopName: currentStopName,
            selectedPersonaIds: selectedPersonaIds,
            tripDates: TripDates(
                start: storedConversation?.startDate,
                end: storedConversation?.endDate
            ),
            travelerPreferences: nil, // TODO: load from StoredPreferences when available
            collectedPlaces: collectedPlaces,
            itinerarySummary: nil, // Populated by ChatViewModel from trip payload if editing
            recentConversation: recentTurns.isEmpty ? nil : recentTurns
        )
    }

    // MARK: - Context Updates

    /// Applies the backend's resolved context to keep local state in sync.
    /// Returns true if the destination changed (UI should show confirmation or update banner).
    @discardableResult
    func applyResponse(_ response: SessionMessageResponse) -> Bool {
        var destinationChanged = false

        if let resolved = response.resolvedContext {
            if let newDest = resolved.destination, newDest != destination {
                destination = newDest
                destinationChanged = true
            }
            if let newState = resolved.state {
                region = newState
            }
            if let newStopId = resolved.currentStopId {
                currentStopId = newStopId
            }
            if let newStopName = resolved.currentStopName {
                currentStopName = newStopName
            }
            if let newPersonas = resolved.selectedPersonaIds, !newPersonas.isEmpty {
                selectedPersonaIds = newPersonas
            }
        }

        // Also check contextUpdates flags
        if let updates = response.contextUpdates {
            if updates.destinationChanged == true {
                destinationChanged = true
            }
        }

        if destination != nil {
            contextStatus = .active
        }

        lastSyncedAt = .now
        return destinationChanged
    }

    /// Updates the destination explicitly (e.g., user confirmed a switch).
    func setDestination(_ newDestination: String, region newRegion: String? = nil) {
        destination = newDestination
        if let r = newRegion { region = r }
        contextStatus = .active
        persistState()
    }

    /// Updates the current stop context (e.g., user navigated to a stop detail).
    func setCurrentStop(id: String?, name: String?) {
        currentStopId = id
        currentStopName = name
        persistState()
    }

    /// Adds a place to the collected list.
    func addCollectedPlace(_ name: String) {
        guard !collectedPlaces.contains(name) else { return }
        collectedPlaces.append(name)
        persistState()
    }

    /// Records the server session ID for session recovery.
    func setServerSessionId(_ sid: String) {
        storedConversation?.serverSessionId = sid
        persistState()
    }

    /// Marks context as stale (e.g., trip was deleted).
    func markStale() {
        contextStatus = .stale
        persistState()
    }

    // MARK: - Persistence

    /// Persists the current conversation state and messages to SwiftData.
    func save(messages: [ChatMessage]) {
        guard let stored = storedConversation else { return }

        stored.destination = destination
        stored.region = region
        stored.country = country
        stored.currentStopId = currentStopId
        stored.currentStopName = currentStopName
        stored.selectedPersonaIds = selectedPersonaIds
        stored.collectedPlaces = collectedPlaces
        stored.lastUpdatedAt = .now

        // Persist messages (keep last 50 to avoid bloating storage)
        let recentMessages = Array(messages.suffix(50))
        let persisted = recentMessages.map { PersistedMessage(from: $0) }
        stored.messagesJSON = (try? JSONEncoder().encode(persisted)) ?? Data()

        try? modelContext?.save()
    }

    /// Persists just the state fields (no messages).
    private func persistState() {
        guard let stored = storedConversation else { return }

        stored.destination = destination
        stored.region = region
        stored.country = country
        stored.currentStopId = currentStopId
        stored.currentStopName = currentStopName
        stored.selectedPersonaIds = selectedPersonaIds
        stored.collectedPlaces = collectedPlaces
        stored.lastUpdatedAt = .now

        try? modelContext?.save()
    }

    /// Clears the active conversation (user tapped "Clear Chat").
    func clearConversation() {
        storedConversation?.isActive = false
        try? modelContext?.save()

        storedConversation = nil
        conversationId = nil
        destination = nil
        region = nil
        country = nil
        currentStopId = nil
        currentStopName = nil
        collectedPlaces = []
        contextStatus = .noTrip
        lastSyncedAt = nil
    }

    // MARK: - Display Helpers

    /// Formatted destination string for the context banner.
    var bannerText: String? {
        guard let dest = destination else { return nil }
        if let r = region {
            return "\(dest), \(r)"
        }
        return dest
    }

    /// Whether the conversation has an active destination set.
    var hasDestination: Bool {
        destination != nil && !destination!.isEmpty
    }
}
