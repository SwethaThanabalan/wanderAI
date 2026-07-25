import Foundation
import SwiftData

/// Manages chat state using server-side sessions for persistent context.
/// Integrates with AIConversationStore for local persistence and grounded context.
/// Flow: create session → send messages with context → accept stops → generate plan.
@MainActor
@Observable
final class ChatViewModel {
    // MARK: - State

    private(set) var personas: [ChatPersona] = []
    private(set) var messages: [ChatMessage] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var didSaveTrip = false
    private(set) var sessionId: String?

    /// Set to true when the backend signals a destination change, so the UI can confirm.
    private(set) var pendingDestinationChange: String?

    /// Contextual loading indicator text (e.g., "Maya is finding photo spots near North Cascades…").
    private(set) var loadingContextText: String?

    var selectedPersona: ChatPersona?
    var selectedPersonas: Set<String> = []
    var isMultiMode = false
    var tripContext: ChatTripContext
    var currentPlan: [CurrentPlanItem]?
    var userPreferences: UserPreferences?
    private(set) var acceptedUpdates: [TripUpdate] = []

    private let apiService: ChatAPIService

    /// The conversation store manages persistence and context assembly.
    var conversationStore: AIConversationStore?

    // MARK: - Init

    init(apiService: ChatAPIService = ChatAPIService(), tripContext: ChatTripContext? = nil) {
        self.apiService = apiService
        self.tripContext = tripContext ?? ChatTripContext(
            destination: nil, region: nil, startDate: nil,
            endDate: nil, travelers: 2, interests: [], existingStops: []
        )
    }

    /// Attaches the conversation store and restores persisted messages.
    func attach(store: AIConversationStore) {
        self.conversationStore = store
        // Restore messages from persistence
        let restored = store.loadPersistedMessages()
        if !restored.isEmpty && messages.isEmpty {
            messages = restored
        }
        // Sync destination from store to tripContext
        if let dest = store.destination {
            tripContext.destination = dest
        }
        if let region = store.region {
            tripContext.region = region
        }
    }

    // MARK: - Computed

    /// Whether this session is a group chat (multiple personas rotating).
    /// When true, the UI should render avatar/emoji/name on every assistant message.
    var isGroupChat: Bool {
        if isMultiMode { return selectedPersonas.count > 1 }
        // Session-based chats are always group chats — personas rotate server-side
        return hasSession
    }

    /// The distinct personas that have spoken so far in this conversation.
    var activePersonaIds: [String] {
        let ids = messages.compactMap { $0.persona }
        return Array(NSOrderedSet(array: ids)) as? [String] ?? Array(Set(ids))
    }

    var canSaveTrip: Bool {
        // Allow save if there's any conversation happening (user might want to save what they discussed)
        tripContext.destination != nil ||
        !(tripContext.existingStops ?? []).isEmpty ||
        !acceptedUpdates.isEmpty ||
        messages.contains(where: { $0.role == "assistant" })
    }

    var hasSession: Bool { sessionId != nil }

    // MARK: - Session Management

    /// Creates a server-side session (or reuses existing).
    private func ensureSession() async throws {
        guard sessionId == nil else { return }

        let personaIds = isMultiMode ? Array(selectedPersonas) : [selectedPersona?.id ?? "planner"]
        let request = CreateSessionRequest(
            personas: personaIds,
            tripContext: tripContext,
            currentPlan: currentPlan,
            userPreferences: userPreferences
        )

        let response = try await apiService.createSession(request: request)
        sessionId = response.sessionId
    }

    // MARK: - Actions

    /// Loads available personas from the backend.
    func loadPersonas() async {
        guard personas.isEmpty else { return }
        do {
            personas = try await apiService.fetchPersonas()
            if selectedPersona == nil { selectedPersona = personas.first }
        } catch {
            personas = defaultPersonas
            if selectedPersona == nil { selectedPersona = personas.first }
        }
    }

    /// Sends a user message. Uses session if available, creates one if needed.
    /// The API returns one persona response per message (round-robin rotation server-side).
    /// Sends full AIConversationContext so the backend can ground follow-ups.
    /// Also prepends destination context to the message text as a grounding hint
    /// since the server may not fully utilize the structured context field yet.
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil
        pendingDestinationChange = nil

        // Build contextual loading text
        let personaName = selectedPersona?.identity.displayName.components(separatedBy: " the ").first ?? "AI"
        let dest = conversationStore?.destination ?? tripContext.destination
        if let dest {
            loadingContextText = "\(personaName) is thinking about \(dest)…"
        } else {
            loadingContextText = "\(personaName) is thinking…"
        }

        // Build grounding prefix to inject into the message for context retention.
        // This ensures the LLM sees the active destination even if the server
        // doesn't fully parse the structured context field.
        let groundedMessage = buildGroundedMessage(text)

        do {
            // Ensure we have a session
            try await ensureSession()

            guard let sid = sessionId else {
                throw ChatAPIService.ChatError.serverError("No session")
            }

            // Store the session ID in conversation store
            conversationStore?.setServerSessionId(sid)

            // Build structured context
            let context = conversationStore?.buildContext(messages: messages)

            // Build full conversation history for the backend
            let history = buildConversationHistory()

            // Send message with context + full history — server returns a single persona reply
            let response = try await apiService.sendSessionMessage(sessionId: sid, message: groundedMessage, context: context, conversationHistory: history)

            let replyText = response.responseText
            if !replyText.isEmpty {
                // If backend didn't return structured stops, extract them from the reply text
                let stops = response.suggestedStops ?? extractStopsFromReply(replyText)

                let msg = ChatMessage(
                    role: "assistant",
                    content: replyText,
                    persona: response.persona ?? selectedPersona?.id,
                    suggestedStops: stops.isEmpty ? nil : stops,
                    tripUpdates: response.tripUpdates
                )
                messages.append(msg)
            }

            // Apply resolved context from backend
            if let store = conversationStore {
                let destinationChanged = store.applyResponse(response)
                if destinationChanged, let newDest = response.resolvedContext?.destination {
                    pendingDestinationChange = newDest
                }
                // Sync back to tripContext
                if let d = store.destination { tripContext.destination = d }
                if let r = store.region { tripContext.region = r }
            }

            // Auto-extract destination from first response or trip updates
            if tripContext.destination == nil {
                // Try from trip updates
                if let updates = response.tripUpdates {
                    for update in updates {
                        if let name = update.data?.name {
                            tripContext.destination = name
                            conversationStore?.setDestination(name)
                            break
                        }
                    }
                }
                // Try to extract from the reply text
                if tripContext.destination == nil {
                    if let extracted = extractDestinationFromMessages() {
                        tripContext.destination = extracted
                        conversationStore?.setDestination(extracted)
                    }
                }
            }

            // Persist conversation
            conversationStore?.save(messages: messages)

        } catch let error as ChatAPIService.ChatError where error.requiresNewSession {
            // Session expired — reset and retry once with a fresh session
            sessionId = nil
            do {
                try await ensureSession()
                guard let sid = sessionId else { throw error }
                conversationStore?.setServerSessionId(sid)
                let context = conversationStore?.buildContext(messages: messages)
                let history = buildConversationHistory()
                let response = try await apiService.sendSessionMessage(sessionId: sid, message: groundedMessage, context: context, conversationHistory: history)
                let replyText = response.responseText
                if !replyText.isEmpty {
                    let stops = response.suggestedStops ?? extractStopsFromReply(replyText)
                    let msg = ChatMessage(
                        role: "assistant",
                        content: replyText,
                        persona: response.persona ?? selectedPersona?.id,
                        suggestedStops: stops.isEmpty ? nil : stops,
                        tripUpdates: response.tripUpdates
                    )
                    messages.append(msg)
                }
                if let store = conversationStore {
                    store.applyResponse(response)
                    store.save(messages: messages)
                }
            } catch {
                await sendMessageFallback(text)
            }
        } catch {
            // Fallback to stateless API
            await sendMessageFallback(text)
        }

        isLoading = false
        loadingContextText = nil
    }

    /// Builds a grounded message that includes destination/trip context inline
    /// so the LLM never loses track of what location the user is asking about.
    private func buildGroundedMessage(_ userText: String) -> String {
        let dest = conversationStore?.destination ?? tripContext.destination
        let stop = conversationStore?.currentStopName
        let places = conversationStore?.collectedPlaces ?? tripContext.existingStops ?? []

        // Only add grounding if we have context and the message is short/ambiguous
        // (doesn't already mention a specific location)
        guard let destination = dest else { return userText }

        var contextHint = "[Context: Active destination is \(destination)"
        if let region = conversationStore?.region ?? tripContext.region {
            contextHint += ", \(region)"
        }
        if let currentStop = stop {
            contextHint += ". Currently discussing: \(currentStop)"
        }
        if !places.isEmpty {
            contextHint += ". Collected places: \(places.prefix(10).joined(separator: ", "))"
        }
        contextHint += ". Interpret follow-up questions relative to this destination.]"

        return "\(contextHint)\n\n\(userText)"
    }

    /// Builds the full conversation history array to send with every message.
    /// This ensures the backend always has complete context for follow-ups,
    /// even if server-side session state is lost.
    private func buildConversationHistory() -> [[String: String]] {
        // Send all messages except the last one (which is the current user message
        // being sent as the `message` field)
        let historyMessages = messages.dropLast()
        return historyMessages.map { msg in
            var entry: [String: String] = ["role": msg.role, "content": msg.content]
            if let persona = msg.persona {
                entry["persona"] = persona
            }
            return entry
        }
    }

    /// Extracts place names from the assistant's reply text when the backend
    /// doesn't return structured `suggested_stops`.
    /// Detects common patterns: numbered lists, bullet points, bold **names**, markdown headers.
    private func extractStopsFromReply(_ text: String) -> [SuggestedStop] {
        var stops: [SuggestedStop] = []
        var seenNames = Set<String>()

        let lines = text.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            var placeName: String?
            var description: String?

            // Pattern 1: Numbered list "1. **Place Name** — description" or "1. Place Name - description"
            if let match = trimmed.range(of: #"^\d+[\.\)]\s+"#, options: .regularExpression) {
                let afterNumber = String(trimmed[match.upperBound...])
                let extracted = extractBoldOrLeading(from: afterNumber)
                placeName = extracted.name
                description = extracted.description
            }
            // Pattern 2: Bullet point "- **Place Name** — description" or "• Place Name"
            else if let match = trimmed.range(of: #"^[-•*]\s+"#, options: .regularExpression) {
                let afterBullet = String(trimmed[match.upperBound...])
                let extracted = extractBoldOrLeading(from: afterBullet)
                placeName = extracted.name
                description = extracted.description
            }
            // Pattern 3: Markdown header "### Place Name"
            else if let match = trimmed.range(of: #"^#{1,4}\s+"#, options: .regularExpression) {
                placeName = String(trimmed[match.upperBound...]).trimmingCharacters(in: .whitespaces)
            }

            // Validate and add
            if let name = placeName,
               !name.isEmpty,
               name.count >= 3,
               name.count <= 80,
               !seenNames.contains(name.lowercased()),
               !isGenericPhrase(name) {
                seenNames.insert(name.lowercased())
                stops.append(SuggestedStop(
                    name: name,
                    description: description,
                    category: nil,
                    latitude: nil,
                    longitude: nil,
                    day: nil,
                    time: nil,
                    durationMinutes: nil,
                    highlights: nil,
                    rating: nil,
                    priceLevel: nil,
                    address: nil,
                    sourceUrl: nil,
                    imageUrl: nil
                ))
            }
        }

        return stops
    }

    /// Extracts a place name from text, preferring **bold** names.
    private func extractBoldOrLeading(from text: String) -> (name: String?, description: String?) {
        // Try bold markdown: **Name** or __Name__
        if let boldMatch = text.range(of: #"\*\*(.+?)\*\*"#, options: .regularExpression) {
            let fullMatch = String(text[boldMatch])
            let name = fullMatch.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
            let afterBold = String(text[boldMatch.upperBound...])
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "—–-:"))
                .trimmingCharacters(in: .whitespaces)
            return (name, afterBold.isEmpty ? nil : afterBold)
        }

        // No bold — take text before first separator (—, -, :, ()
        let separators = CharacterSet(charactersIn: "—–:(")
        let parts = text.components(separatedBy: separators)
        if let first = parts.first {
            let name = first.trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: ".,!?"))
            let rest = parts.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
            return (name.isEmpty ? nil : name, rest.isEmpty ? nil : rest)
        }

        return (text.trimmingCharacters(in: .whitespaces), nil)
    }

    /// Filters out generic phrases that aren't actual place names.
    private func isGenericPhrase(_ text: String) -> Bool {
        let lower = text.lowercased()
        let genericStarts = ["here's", "here are", "i'd suggest", "you could", "consider", "try", "also", "day ", "morning", "afternoon", "evening", "option", "tip", "note"]
        return genericStarts.contains(where: { lower.hasPrefix($0) }) || lower.count < 3
    }

    /// Accepts a suggested stop — notifies the server and adds to local context.
    func acceptSuggestedStop(_ stop: SuggestedStop) {
        if tripContext.existingStops == nil { tripContext.existingStops = [] }
        tripContext.existingStops?.append(stop.name)

        // Track as an accepted update with full data
        let update = TripUpdate(
            action: "add_stop",
            description: stop.description ?? stop.name,
            data: TripUpdateData(
                name: stop.name,
                day: stop.day,
                time: stop.time,
                duration: stop.durationMinutes.map { "\($0) minutes" },
                category: stop.category
            )
        )
        acceptedUpdates.append(update)

        // Sync with conversation store
        conversationStore?.addCollectedPlace(stop.name)

        // Notify server
        if let sid = sessionId {
            let request = AcceptStopRequest(
                stopName: stop.name,
                day: stop.day,
                time: stop.time,
                durationMinutes: stop.durationMinutes,
                category: stop.category
            )
            Task { try? await apiService.acceptStop(sessionId: sid, request: request) }
        }
    }

    /// Accepts a suggestion — tells the server to add it to trip context.
    func acceptSuggestion(_ suggestion: String) {
        if tripContext.existingStops == nil { tripContext.existingStops = [] }
        tripContext.existingStops?.append(suggestion)

        // Sync with conversation store
        conversationStore?.addCollectedPlace(suggestion)

        // Notify server (fire and forget)
        if let sid = sessionId {
            let request = AcceptStopRequest(stopName: suggestion, day: nil, time: nil, durationMinutes: nil, category: nil)
            Task { try? await apiService.acceptStop(sessionId: sid, request: request) }
        }
    }

    /// Accepts a trip update from the assistant.
    func acceptTripUpdate(_ update: TripUpdate) {
        acceptedUpdates.append(update)
        if let name = update.data?.name {
            if tripContext.existingStops == nil { tripContext.existingStops = [] }
            tripContext.existingStops?.append(name)

            // Notify server
            if let sid = sessionId {
                let request = AcceptStopRequest(
                    stopName: name, day: update.data?.day,
                    time: update.data?.time, durationMinutes: parseDuration(update.data?.duration),
                    category: update.data?.category
                )
                Task { try? await apiService.acceptStop(sessionId: sid, request: request) }
            }
        }
    }

    /// Builds the final trip from the session and saves locally.
    /// Updates an existing StoredTrip with new/modified stops from the chat session.
    func updateExistingTrip(_ storedTrip: StoredTrip, context: ModelContext) async {
        if tripContext.destination == nil {
            tripContext.destination = extractDestinationFromMessages()
        }

        // Try server-side generate-plan first
        if let sid = sessionId {
            isLoading = true
            do {
                let tripData = try await apiService.generatePlan(sessionId: sid)
                let importService = TripImportService(context: context)
                let document = try importService.validate(data: tripData)

                // Update existing trip's rawJSON and metadata
                storedTrip.rawJSON = try JSONEncoder().encode(document)
                storedTrip.name = document.trip.name.isEmpty ? storedTrip.name : document.trip.name
                storedTrip.primaryDestination = document.trip.primaryDestination ?? storedTrip.primaryDestination
                storedTrip.numberOfDays = document.trip.days.count
                storedTrip.startDate = document.trip.startDate ?? storedTrip.startDate
                storedTrip.endDate = document.trip.endDate ?? storedTrip.endDate
                try? context.save()
                didSaveTrip = true
                isLoading = false
                return
            } catch let error as ChatAPIService.ChatError {
                handleSessionError(error)
            } catch {
                // Fall through to local update
            }
            isLoading = false
        }

        // Fallback: merge new stops into the existing trip locally
        updateTripLocally(storedTrip, context: context)
    }

    /// Merges accepted/suggested stops into an existing trip's rawJSON.
    private func updateTripLocally(_ storedTrip: StoredTrip, context: ModelContext) {
        // Decode existing trip
        guard var document = try? JSONDecoder().decode(TripImportDocument.self, from: storedTrip.rawJSON) else {
            // Can't decode existing trip — mark as saved without creating a duplicate
            didSaveTrip = true
            errorMessage = "Could not parse the existing trip data."
            return
        }

        // Collect new stops to add
        var newStops: [StopPayload] = []
        let existingStopNames = Set(document.trip.days.flatMap(\.stops).map { $0.name.lowercased() })
        var nextSequence = (document.trip.days.last?.stops.last?.sequence ?? 0) + 1

        // From accepted updates
        for update in acceptedUpdates {
            guard let data = update.data, let name = data.name else { continue }
            guard !existingStopNames.contains(name.lowercased()) else { continue }
            newStops.append(StopPayload(
                id: "stop-\(UUID().uuidString.prefix(8))", sequence: nextSequence, name: name,
                category: data.category, plannedTime: data.time,
                estimatedDurationMinutes: parseDuration(data.duration),
                summary: update.description, description: nil, history: nil,
                mapReference: MapReference(latitude: 0, longitude: 0, formattedAddress: nil, placeId: nil, mapLabel: name, pinStyle: "primary"),
                heroImage: nil, gallery: nil, mustDo: nil, highlights: nil,
                practicalInformation: nil, suitability: nil, reviews: nil,
                travelerTips: nil, tags: nil, community: nil
            ))
            nextSequence += 1
        }

        // From suggested stops in messages
        let allSuggested = messages.compactMap(\.suggestedStops).flatMap { $0 }
        for stop in allSuggested {
            guard !existingStopNames.contains(stop.name.lowercased()) else { continue }
            guard !newStops.contains(where: { $0.name.lowercased() == stop.name.lowercased() }) else { continue }
            newStops.append(StopPayload(
                id: "stop-\(UUID().uuidString.prefix(8))", sequence: nextSequence, name: stop.name,
                category: stop.category, plannedTime: stop.time,
                estimatedDurationMinutes: stop.durationMinutes,
                summary: stop.description, description: nil, history: nil,
                mapReference: MapReference(latitude: stop.latitude ?? 0, longitude: stop.longitude ?? 0, formattedAddress: nil, placeId: nil, mapLabel: stop.name, pinStyle: "primary"),
                heroImage: nil, gallery: nil, mustDo: nil, highlights: stop.highlights,
                practicalInformation: nil, suitability: nil, reviews: nil,
                travelerTips: nil, tags: nil, community: nil
            ))
            nextSequence += 1
        }

        guard !newStops.isEmpty else {
            didSaveTrip = true // Nothing new to add, but consider it "saved"
            return
        }

        // Add new stops to the last day (or create a new day if needed)
        var days = document.trip.days
        if var lastDay = days.last {
            let updatedStops = lastDay.stops + newStops
            lastDay = DayPayload(
                id: lastDay.id, dayNumber: lastDay.dayNumber, date: lastDay.date,
                title: lastDay.title, summary: lastDay.summary,
                plannedDistanceMiles: lastDay.plannedDistanceMiles,
                estimatedDrivingMinutes: lastDay.estimatedDrivingMinutes,
                stops: updatedStops, routeHighlights: lastDay.routeHighlights
            )
            days[days.count - 1] = lastDay
        } else {
            days.append(DayPayload(
                id: "day-new", dayNumber: 1, date: nil, title: "Day 1",
                summary: nil, plannedDistanceMiles: nil, estimatedDrivingMinutes: nil,
                stops: newStops, routeHighlights: nil
            ))
        }

        // Rebuild document
        let updatedTrip = TripPayload(
            id: document.trip.id, name: document.trip.name,
            summary: document.trip.summary, primaryDestination: document.trip.primaryDestination,
            startDate: document.trip.startDate, endDate: document.trip.endDate,
            timeZone: document.trip.timeZone, coverImage: document.trip.coverImage,
            travelGroup: document.trip.travelGroup, suitability: document.trip.suitability,
            plannedDistanceMiles: document.trip.plannedDistanceMiles,
            highlights: document.trip.highlights, days: days,
            community: document.trip.community, metadata: document.trip.metadata
        )
        let updatedDoc = TripImportDocument(
            format: document.format, formatVersion: document.formatVersion,
            generatedAt: ISO8601DateFormatter().string(from: .now),
            generator: document.generator, trip: updatedTrip
        )

        // Save back to the stored trip
        if let encoded = try? JSONEncoder().encode(updatedDoc) {
            storedTrip.rawJSON = encoded
            storedTrip.numberOfDays = days.count
            try? context.save()
            didSaveTrip = true
        }
    }

    func buildAndSaveTrip(context: ModelContext) async {
        // Extract destination from conversation if not set
        if tripContext.destination == nil {
            tripContext.destination = extractDestinationFromMessages()
        }

        guard let sid = sessionId else {
            saveTripAsDraft(context: context)
            return
        }

        isLoading = true

        do {
            let tripData = try await apiService.generatePlan(sessionId: sid)
            let importService = TripImportService(context: context)
            let document = try importService.validate(data: tripData)
            try importService.importTrip(document: document, data: tripData)
            didSaveTrip = true
        } catch let error as ChatAPIService.ChatError {
            handleSessionError(error)
            if !didSaveTrip {
                saveTripAsDraft(context: context)
            }
        } catch {
            // Fallback to local draft
            saveTripAsDraft(context: context)
        }

        isLoading = false
    }

    /// Extracts a destination name from the conversation messages.
    private func extractDestinationFromMessages() -> String? {
        // Check suggested stops first
        for msg in messages.reversed() {
            if let stops = msg.suggestedStops, let first = stops.first {
                return first.name
            }
        }
        // Check user messages for location hints
        for msg in messages where msg.role == "user" {
            let text = msg.content.lowercased()
            // Common patterns: "trip to X", "visit X", "going to X"
            for prefix in ["trip to ", "visit ", "going to ", "plan for "] {
                if let range = text.range(of: prefix) {
                    let after = String(text[range.upperBound...])
                    let destination = after.components(separatedBy: CharacterSet(charactersIn: ".,!?\n")).first ?? after
                    if !destination.trimmingCharacters(in: .whitespaces).isEmpty {
                        return destination.trimmingCharacters(in: .whitespaces).capitalized
                    }
                }
            }
        }
        return "Untitled Trip"
    }

    /// Toggles a persona in multi-select mode.
    /// Does NOT reset destination context — only persona instructions change.
    func togglePersona(_ personaId: String) {
        if selectedPersonas.contains(personaId) {
            selectedPersonas.remove(personaId)
        } else {
            selectedPersonas.insert(personaId)
        }
        // Reset server session to pick up new persona config, but preserve conversation context
        sessionId = nil
        conversationStore?.selectedPersonaIds = Array(selectedPersonas)
    }

    /// Clears the conversation and resets session.
    func clearConversation() {
        messages.removeAll()
        acceptedUpdates.removeAll()
        errorMessage = nil
        didSaveTrip = false
        sessionId = nil
        pendingDestinationChange = nil
        conversationStore?.clearConversation()
    }

    func setDestination(_ destination: String, region: String? = nil) {
        tripContext.destination = destination
        tripContext.region = region
        sessionId = nil // Reset session to pick up new context
        conversationStore?.setDestination(destination, region: region)
    }

    /// Confirms the pending destination change (user tapped "Switch").
    func confirmDestinationChange() {
        guard let newDest = pendingDestinationChange else { return }
        setDestination(newDest)
        pendingDestinationChange = nil
    }

    /// Dismisses the pending destination change (user tapped "Keep current").
    func dismissDestinationChange() {
        pendingDestinationChange = nil
    }

    // MARK: - Session Error Handling

    /// Surfaces structured session errors to the UI via errorMessage.
    /// Resets sessionId when the session has expired so the next action creates a fresh one.
    private func handleSessionError(_ error: ChatAPIService.ChatError) {
        switch error {
        case .sessionExpired:
            errorMessage = "Session expired. Starting a new conversation."
            sessionId = nil
        case .badRequest(let detail):
            if detail.lowercased().contains("no stops") || detail.lowercased().contains("accept") {
                errorMessage = "Accept some suggestions first before generating your trip."
            } else {
                errorMessage = detail
            }
        case .serviceUnavailable:
            errorMessage = "Service temporarily unavailable. Please try again."
        default:
            errorMessage = error.localizedDescription
        }
    }

    /// Whether the last error is retryable (UI can show a retry button).
    var canRetry: Bool {
        guard let msg = errorMessage else { return false }
        return msg.contains("try again") || msg.contains("unavailable")
    }

    // MARK: - Fallback (stateless)

    private func sendMessageFallback(_ text: String) async {
        guard let persona = selectedPersona else { return }

        // Include full conversation history for context retention
        let history = messages.dropLast().map { msg -> [String: String] in
            ["role": msg.role, "content": msg.content]
        }

        // Ground the fallback message with destination context
        let groundedMessage = buildGroundedMessage(text)

        let request = ChatRequest(
            message: groundedMessage, persona: persona.id,
            tripContext: tripContext, conversationHistory: Array(history)
        )

        do {
            let response = try await apiService.sendMessage(request: request)
            // Extract stops from reply text if none provided structurally
            let extractedStops = extractStopsFromReply(response.reply)
            let msg = ChatMessage(
                role: "assistant", content: response.reply,
                persona: response.persona ?? persona.id,
                suggestions: response.suggestions,
                suggestedStops: extractedStops.isEmpty ? nil : extractedStops,
                tripUpdates: response.tripUpdates
            )
            messages.append(msg)

            // Auto-extract destination if not set
            if tripContext.destination == nil {
                if let extracted = extractDestinationFromMessages() {
                    tripContext.destination = extracted
                    conversationStore?.setDestination(extracted)
                }
            }

            conversationStore?.save(messages: messages)
        } catch {
            errorMessage = error.localizedDescription
            messages.append(ChatMessage(
                role: "assistant",
                content: "Hmm, connection hiccup. What were you thinking for the trip?",
                persona: persona.id
            ))
        }
    }

    // MARK: - Draft Save (fallback when build-trip unavailable)

    func saveTripAsDraft(context: ModelContext) {
        let tripName = tripContext.destination ?? extractDestinationFromMessages() ?? "Untitled Trip"
        let tripId = "draft-\(UUID().uuidString.prefix(8))"

        var stops: [StopPayload] = []
        var sequence = 1

        // Pull from accepted updates first
        for update in acceptedUpdates {
            if let data = update.data, let name = data.name {
                stops.append(StopPayload(
                    id: "stop-\(UUID().uuidString.prefix(8))", sequence: sequence, name: name,
                    category: data.category, plannedTime: data.time,
                    estimatedDurationMinutes: parseDuration(data.duration),
                    summary: update.description, description: nil, history: nil,
                    mapReference: MapReference(latitude: 0, longitude: 0, formattedAddress: nil, placeId: nil, mapLabel: name, pinStyle: "primary"),
                    heroImage: nil, gallery: nil, mustDo: nil, highlights: nil,
                    practicalInformation: nil, suitability: nil, reviews: nil,
                    travelerTips: nil, tags: nil, community: nil
                ))
                sequence += 1
            }
        }

        // If no accepted updates, pull suggested_stops from messages
        if stops.isEmpty {
            let allSuggested = messages.compactMap(\.suggestedStops).flatMap { $0 }
            for stop in allSuggested {
                let lat = stop.latitude ?? 0
                let lng = stop.longitude ?? 0
                stops.append(StopPayload(
                    id: "stop-\(UUID().uuidString.prefix(8))", sequence: sequence, name: stop.name,
                    category: stop.category, plannedTime: stop.time,
                    estimatedDurationMinutes: stop.durationMinutes,
                    summary: stop.description, description: nil, history: nil,
                    mapReference: MapReference(latitude: lat, longitude: lng, formattedAddress: nil, placeId: nil, mapLabel: stop.name, pinStyle: sequence == 1 ? "start" : "primary"),
                    heroImage: nil, gallery: nil, mustDo: nil, highlights: stop.highlights,
                    practicalInformation: nil, suitability: nil, reviews: nil,
                    travelerTips: nil, tags: nil, community: nil
                ))
                sequence += 1
            }
        }

        let updateNames = Set(acceptedUpdates.compactMap { $0.data?.name })
        for stopName in (tripContext.existingStops ?? []) where !updateNames.contains(stopName) {
            stops.append(StopPayload(
                id: "stop-\(UUID().uuidString.prefix(8))", sequence: sequence, name: stopName,
                category: nil, plannedTime: nil, estimatedDurationMinutes: nil,
                summary: nil, description: nil, history: nil,
                mapReference: MapReference(latitude: 0, longitude: 0, formattedAddress: nil, placeId: nil, mapLabel: stopName, pinStyle: "primary"),
                heroImage: nil, gallery: nil, mustDo: nil, highlights: nil,
                practicalInformation: nil, suitability: nil, reviews: nil,
                travelerTips: nil, tags: nil, community: nil
            ))
            sequence += 1
        }

        if stops.isEmpty {
            stops.append(StopPayload(
                id: "stop-placeholder", sequence: 1, name: tripName,
                category: nil, plannedTime: nil, estimatedDurationMinutes: nil,
                summary: "Draft — add stops via the AI assistant.", description: nil, history: nil,
                mapReference: MapReference(latitude: 0, longitude: 0, formattedAddress: nil, placeId: nil, mapLabel: tripName, pinStyle: "start"),
                heroImage: nil, gallery: nil, mustDo: nil, highlights: nil,
                practicalInformation: nil, suitability: nil, reviews: nil,
                travelerTips: nil, tags: nil, community: nil
            ))
        }

        let stopsPerDay = 5
        var days: [DayPayload] = []
        let chunks = stride(from: 0, to: stops.count, by: stopsPerDay).map { Array(stops[$0..<min($0 + stopsPerDay, stops.count)]) }
        for (i, chunk) in chunks.enumerated() {
            let reseq = chunk.enumerated().map { (j, s) in
                StopPayload(id: s.id, sequence: j+1, name: s.name, category: s.category, plannedTime: s.plannedTime, estimatedDurationMinutes: s.estimatedDurationMinutes, summary: s.summary, description: s.description, history: s.history, mapReference: s.mapReference, heroImage: s.heroImage, gallery: s.gallery, mustDo: s.mustDo, highlights: s.highlights, practicalInformation: s.practicalInformation, suitability: s.suitability, reviews: s.reviews, travelerTips: s.travelerTips, tags: s.tags, community: s.community)
            }
            days.append(DayPayload(id: "day-\(i+1)", dayNumber: i+1, date: computeDate(startDate: tripContext.startDate, dayOffset: i), title: "Day \(i+1)", summary: nil, plannedDistanceMiles: nil, estimatedDrivingMinutes: nil, stops: reseq, routeHighlights: nil))
        }

        let trip = TripPayload(id: tripId, name: tripName, summary: "Draft from AI assistant.", primaryDestination: tripContext.destination ?? tripContext.region, startDate: tripContext.startDate, endDate: tripContext.endDate, timeZone: nil, coverImage: nil, travelGroup: nil, suitability: nil, plannedDistanceMiles: nil, highlights: nil, days: days, community: nil, metadata: TripMetadata(isSample: nil, notes: "draft"))
        let document = TripImportDocument(format: "wanderAI.trip", formatVersion: "1.0.0", generatedAt: ISO8601DateFormatter().string(from: .now), generator: GeneratorInfo(type: "chat", name: "WanderAI Chat", version: "1.0"), trip: trip)

        guard let data = try? JSONEncoder().encode(document) else { return }
        let stored = StoredTrip(tripId: tripId, name: tripName, primaryDestination: tripContext.destination ?? tripContext.region, startDate: tripContext.startDate, endDate: tripContext.endDate, numberOfDays: days.count, coverImageAsset: nil, isSample: false, rawJSON: data)
        context.insert(stored)
        try? context.save()
        didSaveTrip = true
    }

    // MARK: - Parsing

    /// Parses [persona] tagged text into segments.
    func parseConsolidated(_ text: String) -> [(persona: String, content: String)] {
        var results: [(persona: String, content: String)] = []
        var currentPersona: String?
        var currentLines: [String] = []

        for line in text.components(separatedBy: "\n") {
            if let match = line.range(of: #"^\[(\w+)\]\s*"#, options: .regularExpression) {
                if let persona = currentPersona, !currentLines.isEmpty {
                    results.append((persona: persona, content: currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                let tag = String(line[match]).trimmingCharacters(in: .whitespaces)
                currentPersona = tag.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").trimmingCharacters(in: .whitespaces)
                let remainder = String(line[match.upperBound...])
                currentLines = remainder.isEmpty ? [] : [remainder]
            } else if currentPersona != nil {
                currentLines.append(line)
            } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                currentLines.append(line)
            }
        }

        if let persona = currentPersona, !currentLines.isEmpty {
            results.append((persona: persona, content: currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
        } else if !currentLines.isEmpty {
            results.append((persona: selectedPersona?.id ?? "assistant", content: currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return results
    }

    private func addParsedMessage(_ parsed: (persona: String, content: String), suggestions: [String]?, suggestedStops: [SuggestedStop]?, updates: [TripUpdate]?) {
        let msg = ChatMessage(role: "assistant", content: parsed.content, persona: parsed.persona, suggestions: suggestions, suggestedStops: suggestedStops, tripUpdates: updates)
        messages.append(msg)
    }

    // MARK: - Helpers

    private func parseDuration(_ duration: String?) -> Int? {
        guard let d = duration else { return nil }
        let lower = d.lowercased()
        if lower.contains("hour") {
            let num = lower.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
            if let hours = Double(num) { return Int(hours * 60) }
        }
        if lower.contains("min") {
            let num = lower.components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted).joined()
            if let mins = Int(num) { return mins }
        }
        return nil
    }

    private func computeDate(startDate: String?, dayOffset: Int) -> String? {
        guard let start = startDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: start),
              let newDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: date) else { return nil }
        return formatter.string(from: newDate)
    }

    private var defaultPersonas: [ChatPersona] {
        [
            ChatPersona(id: "planner", name: "Trip Planner", description: "Expert at building itineraries", icon: nil, color: nil),
            ChatPersona(id: "foodie", name: "Foodie", description: "Local food recommendations", icon: nil, color: nil),
            ChatPersona(id: "photographer", name: "Photographer", description: "Best spots for photos", icon: nil, color: nil),
            ChatPersona(id: "historian", name: "Historian", description: "Historical context", icon: nil, color: nil),
            ChatPersona(id: "geologist", name: "Geologist", description: "Geological features", icon: nil, color: nil),
            ChatPersona(id: "storyteller", name: "Storyteller", description: "Local legends", icon: nil, color: nil),
        ]
    }
}
