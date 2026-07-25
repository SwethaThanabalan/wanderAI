import SwiftUI
import SwiftData

/// AI Chat view with persona picker, message bubbles, and places board.
/// Flow: Chat → Discover places → View board → Ask planner to arrange → Save trip.
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @State private var showSaveConfirmation = false
    @State private var showPlacesBoard = false
    @State private var discoveredPlaces: [DiscoveredPlace] = []
    @State private var detailPlaceName: IdentifiableString?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                personaPicker

                // Places bar (when places exist)
                if !discoveredPlaces.isEmpty {
                    placesBar
                }

                Divider()
                messagesArea
                inputBar
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if viewModel.canSaveTrip {
                            Button {
                                Task { await viewModel.buildAndSaveTrip(context: modelContext) }
                                showSaveConfirmation = true
                            } label: {
                                Label("Save", systemImage: "square.and.arrow.down.fill")
                            }
                            .tint(.green)
                            .disabled(viewModel.didSaveTrip)
                        }

                        Menu {
                            if !discoveredPlaces.isEmpty {
                                Button {
                                    showPlacesBoard = true
                                } label: {
                                    Label("View Places (\(discoveredPlaces.count))", systemImage: "rectangle.stack")
                                }
                            }
                            Button(role: .destructive) {
                                viewModel.clearConversation()
                                discoveredPlaces.removeAll()
                            } label: {
                                Label("Clear Chat", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Trip Saved", isPresented: $showSaveConfirmation) {
                Button("OK") {}
            } message: {
                Text("Your trip has been saved as a draft in My Trips.")
            }
            .sheet(isPresented: $showPlacesBoard) {
                PlacesBoardView(
                    places: $discoveredPlaces,
                    onArrangeTrip: { arrangeTrip() },
                    onDismiss: { showPlacesBoard = false }
                )
            }
            .sheet(item: $detailPlaceName) { item in
                PlaceDetailSheet(
                    placeName: item.value,
                    onAdd: {
                        let place = DiscoveredPlace(name: item.value)
                        discoveredPlaces.append(place)
                        viewModel.acceptSuggestion(item.value)
                    },
                    alreadyAdded: discoveredPlaces.contains { $0.name == item.value }
                )
            }
            .task {
                await viewModel.loadPersonas()
            }
        }
    }

    // MARK: - Places Bar

    private var placesBar: some View {
        Button { showPlacesBoard = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("\(discoveredPlaces.count) places collected")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text("View Board")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.06))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Persona Picker

    private var personaPicker: some View {
        VStack(spacing: 0) {
            // Mode toggle + chips
            HStack(spacing: 0) {
                // Multi-mode toggle
                Button {
                    withAnimation { viewModel.isMultiMode.toggle() }
                    if !viewModel.isMultiMode {
                        viewModel.selectedPersonas.removeAll()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isMultiMode ? "person.3.fill" : "person.fill")
                            .font(.caption)
                        if viewModel.isMultiMode {
                            Text("\(viewModel.selectedPersonas.count)")
                                .font(.caption2.bold())
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(viewModel.isMultiMode ? Color.green : Color(.systemGray5))
                    .foregroundStyle(viewModel.isMultiMode ? .white : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)

                // Persona chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.personas) { persona in
                            personaChip(persona)
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .padding(.vertical, 10)

            // Multi-mode hint
            if viewModel.isMultiMode && viewModel.selectedPersonas.isEmpty {
                Text("Tap multiple personas to get their unique perspectives")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
            }
        }
        .background(Color(.systemBackground))
    }

    private func personaChip(_ persona: ChatPersona) -> some View {
        let isSelected: Bool = viewModel.isMultiMode
            ? viewModel.selectedPersonas.contains(persona.id)
            : viewModel.selectedPersona?.id == persona.id

        return Button {
            if viewModel.isMultiMode {
                viewModel.togglePersona(persona.id)
            } else {
                viewModel.selectedPersona = persona
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: persona.systemIcon)
                    .font(.caption2)
                Text(persona.name)
                    .font(.caption.weight(.medium))
                if viewModel.isMultiMode && isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? Color.green : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                        if viewModel.isLoading {
                            typingIndicator
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.green.opacity(0.6))
            Text("Where shall we wander?")
                .font(.title3.bold())
            Text("Discover places, collect them on your board,\nthen arrange into a trip.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 8) {
                quickPrompt("Suggest places to visit in Olympic National Park")
                quickPrompt("Best food spots in Seattle")
                quickPrompt("Photography locations near Hurricane Ridge")
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    private func quickPrompt(_ text: String) -> some View {
        Button {
            inputText = text
            Task { await sendMessage() }
        } label: {
            HStack {
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Message Bubble

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == "user"
        return VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            if !isUser, let persona = message.persona {
                HStack(spacing: 4) {
                    if let p = viewModel.personas.first(where: { $0.id == persona }) {
                        Image(systemName: p.systemIcon).font(.caption2)
                        Text(p.name).font(.caption2.weight(.medium))
                    } else {
                        Image(systemName: "sparkles").font(.caption2)
                        Text(persona.capitalized).font(.caption2.weight(.medium))
                    }
                }
                .foregroundStyle(.secondary)
            }

            // Render markdown content
            markdownText(message.content)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 16).fill(isUser ? Color.green : Color(.systemGray5)))
                .foregroundStyle(isUser ? .white : .primary)

            if let suggestions = message.suggestions, !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        addPlaceRow(name: suggestion, from: message)
                    }
                }
                .padding(.top, 4)
            }

            if let updates = message.tripUpdates, !updates.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(updates.enumerated()), id: \.offset) { _, update in
                        addUpdateRow(update)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private func addPlaceRow(name: String, from message: ChatMessage) -> some View {
        let alreadyAdded = discoveredPlaces.contains { $0.name == name }
        return HStack(spacing: 8) {
            // Tap name area for details
            Button {
                detailPlaceName = IdentifiableString(name)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Add button
            Button {
                guard !alreadyAdded else { return }
                let place = DiscoveredPlace(name: name)
                withAnimation { discoveredPlaces.append(place) }
                viewModel.acceptSuggestion(name)
            } label: {
                Text(alreadyAdded ? "Added" : "Add")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(alreadyAdded ? Color(.systemGray5) : Color.green)
                    .foregroundColor(alreadyAdded ? Color.secondary : Color.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(alreadyAdded)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6).opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }

    private func addUpdateRow(_ update: TripUpdate) -> some View {
        let name = update.data?.name ?? update.description
        let alreadyAdded = discoveredPlaces.contains { $0.name == name }
        return HStack(spacing: 8) {
            // Tap for details
            Button {
                detailPlaceName = IdentifiableString(name)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                        if let data = update.data {
                            HStack(spacing: 6) {
                                if let day = data.day { Text("Day \(day)") }
                                if let time = data.time { Text(time) }
                                if let dur = data.duration { Text(dur) }
                                if let cat = data.category { Text(cat) }
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Add button
            Button {
                guard !alreadyAdded else { return }
                let place = DiscoveredPlace(
                    name: name,
                    category: update.data?.category,
                    day: update.data?.day,
                    time: update.data?.time,
                    duration: update.data?.duration,
                    description: update.description
                )
                withAnimation { discoveredPlaces.append(place) }
                viewModel.acceptTripUpdate(update)
            } label: {
                Text(alreadyAdded ? "Added" : "Add")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(alreadyAdded ? Color(.systemGray5) : Color.green)
                    .foregroundColor(alreadyAdded ? Color.secondary : Color.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(alreadyAdded)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6).opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue.opacity(0.2), lineWidth: 1))
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle().fill(Color.secondary).frame(width: 6, height: 6).opacity(0.5)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray5)))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                TextField("Ask anything...", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))
                    .focused($isInputFocused)
                    .onSubmit { Task { await sendMessage() } }

                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .green)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func sendMessage() async {
        let text = inputText
        inputText = ""
        await viewModel.sendMessage(text)
    }

    /// Sends the collected places to the planner persona to arrange into an itinerary,
    /// then saves the resulting trip.
    private func arrangeTrip() {
        showPlacesBoard = false

        // Switch to planner persona
        if let planner = viewModel.personas.first(where: { $0.id == "planner" }) {
            viewModel.selectedPersona = planner
        }

        // Build the arrange message
        let placeNames = discoveredPlaces.map(\.name).joined(separator: ", ")
        let destination = viewModel.tripContext.destination ?? "the destination"
        let dates = [viewModel.tripContext.startDate, viewModel.tripContext.endDate]
            .compactMap { $0 }
            .joined(separator: " to ")
        let dateClause = dates.isEmpty ? "" : " from \(dates)"

        let arrangeMessage = "Arrange these places into a day-by-day itinerary for \(destination)\(dateClause): \(placeNames). Give me the optimal order with times and durations."

        // Send to the planner, then build trip from session
        Task {
            await viewModel.sendMessage(arrangeMessage)
            await viewModel.buildAndSaveTrip(context: modelContext)
            showSaveConfirmation = true
        }
    }

    // MARK: - Markdown Rendering

    private func markdownText(_ content: String) -> Text {
        if let attributed = try? AttributedString(markdown: content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return Text(attributed)
        } else {
            return Text(content)
        }
    }
}

// MARK: - Identifiable String Wrapper

struct IdentifiableString: Identifiable {
    let id: String
    let value: String
    init(_ value: String) {
        self.id = value
        self.value = value
    }
}
