import Foundation
import SwiftData

/// Manages chat state using server-side sessions for persistent context.
/// Flow: create session → send messages (no history needed) → accept stops → build trip.
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

    var selectedPersona: ChatPersona?
    var selectedPersonas: Set<String> = []
    var isMultiMode = false
    var tripContext: ChatTripContext
    private(set) var acceptedUpdates: [TripUpdate] = []

    private let apiService: ChatAPIService

    // MARK: - Init

    init(apiService: ChatAPIService = ChatAPIService(), tripContext: ChatTripContext? = nil) {
        self.apiService = apiService
        self.tripContext = tripContext ?? ChatTripContext(
            destination: nil, region: nil, startDate: nil,
            endDate: nil, travelers: 2, interests: [], existingStops: []
        )
    }

    // MARK: - Computed

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
        let request = CreateSessionRequest(personas: personaIds, tripContext: tripContext)

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
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil

        do {
            // Ensure we have a session
            try await ensureSession()

            guard let sid = sessionId else {
                throw ChatAPIService.ChatError.serverError("No session")
            }

            // Send message — server has all context
            let response = try await apiService.sendSessionMessage(sessionId: sid, message: text)

            // Parse response into chat bubbles
            let responseText = response.responseText
            if !responseText.isEmpty {
                let parsed = parseConsolidated(responseText)
                let stops = response.suggestedStops
                if parsed.count > 2 {
                    addParsedMessage(parsed[0], suggestions: nil, suggestedStops: nil, updates: nil)
                    addParsedMessage(parsed[parsed.count - 1], suggestions: response.combinedSuggestions, suggestedStops: stops, updates: response.combinedTripUpdates)
                } else if parsed.isEmpty {
                    let msg = ChatMessage(
                        role: "assistant", content: responseText,
                        persona: response.persona ?? selectedPersona?.id,
                        suggestions: response.combinedSuggestions,
                        suggestedStops: stops,
                        tripUpdates: response.combinedTripUpdates
                    )
                    messages.append(msg)
                } else {
                    for (index, p) in parsed.enumerated() {
                        let isLast = index == parsed.count - 1
                        addParsedMessage(p,
                            suggestions: isLast ? response.combinedSuggestions : nil,
                            suggestedStops: isLast ? stops : nil,
                            updates: isLast ? response.combinedTripUpdates : nil
                        )
                    }
                }
            }

            // Auto-extract destination
            if tripContext.destination == nil, let updates = response.combinedTripUpdates {
                for update in updates {
                    if let name = update.data?.name {
                        tripContext.destination = name
                        break
                    }
                }
            }
        } catch {
            // Fallback to stateless API
            await sendMessageFallback(text)
        }

        isLoading = false
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

        // Notify server
        if let sid = sessionId {
            let request = AcceptStopRequest(
                stopName: stop.name,
                day: stop.day,
                time: stop.time,
                category: stop.category
            )
            Task { try? await apiService.acceptStop(sessionId: sid, request: request) }
        }
    }

    /// Accepts a suggestion — tells the server to add it to trip context.
    func acceptSuggestion(_ suggestion: String) {
        if tripContext.existingStops == nil { tripContext.existingStops = [] }
        tripContext.existingStops?.append(suggestion)

        // Notify server (fire and forget)
        if let sid = sessionId {
            let request = AcceptStopRequest(stopName: suggestion, day: nil, time: nil, category: nil)
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
                    time: update.data?.time, category: update.data?.category
                )
                Task { try? await apiService.acceptStop(sessionId: sid, request: request) }
            }
        }
    }

    /// Builds the final trip from the session and saves locally.
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
            let tripData = try await apiService.buildTrip(sessionId: sid)
            let importService = TripImportService(context: context)
            let document = try importService.validate(data: tripData)
            try importService.importTrip(document: document, data: tripData)
            didSaveTrip = true
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
    func togglePersona(_ personaId: String) {
        if selectedPersonas.contains(personaId) {
            selectedPersonas.remove(personaId)
        } else {
            selectedPersonas.insert(personaId)
        }
        // Reset session when personas change
        sessionId = nil
    }

    /// Clears the conversation and resets session.
    func clearConversation() {
        messages.removeAll()
        acceptedUpdates.removeAll()
        errorMessage = nil
        didSaveTrip = false
        sessionId = nil
    }

    func setDestination(_ destination: String, region: String? = nil) {
        tripContext.destination = destination
        tripContext.region = region
        sessionId = nil // Reset session to pick up new context
    }

    // MARK: - Fallback (stateless)

    private func sendMessageFallback(_ text: String) async {
        guard let persona = selectedPersona else { return }

        let history = messages.dropLast().map { msg -> [String: String] in
            ["role": msg.role, "content": msg.content]
        }

        let prompt = "\(text)\n\n(Be conversational — 2-3 sentences. End with a question.)"
        let request = ChatRequest(
            message: prompt, persona: persona.id,
            tripContext: tripContext, conversationHistory: Array(history)
        )

        do {
            let response = try await apiService.sendMessage(request: request)
            let msg = ChatMessage(
                role: "assistant", content: response.reply,
                persona: response.persona ?? persona.id,
                suggestions: response.suggestions, tripUpdates: response.tripUpdates
            )
            messages.append(msg)
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
