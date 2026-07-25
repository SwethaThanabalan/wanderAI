import SwiftUI

/// A place discovered during chat that can be added to the trip.
struct DiscoveredPlace: Identifiable, Equatable {
    let id: String
    let name: String
    let category: String?
    let day: Int?
    let time: String?
    let duration: String?
    let description: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        category: String? = nil,
        day: Int? = nil,
        time: String? = nil,
        duration: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.day = day
        self.time = time
        self.duration = duration
        self.description = description
    }
}

/// Kanban-style board showing all discovered places from the chat.
/// User can remove places they don't want, then tap "Arrange Trip" to
/// ask the planner to organize them into an itinerary.
struct PlacesBoardView: View {
    @Binding var places: [DiscoveredPlace]
    let onArrangeTrip: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if places.isEmpty {
                    emptyState
                } else {
                    boardContent
                }
            }
            .navigationTitle("Places to Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !places.isEmpty {
                        Button {
                            onArrangeTrip()
                        } label: {
                            Label("Arrange Trip", systemImage: "list.number")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(.green)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 44))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("No places yet")
                .font(.title3.bold())
            Text("Chat with the AI assistant to discover\nplaces, then they'll appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    // MARK: - Board Content

    private var boardContent: some View {
        VStack(spacing: 0) {
            // Header stats
            HStack {
                Label("\(places.count) places", systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(role: .destructive) {
                    places.removeAll()
                } label: {
                    Text("Clear All")
                        .font(.caption.weight(.medium))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Places list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(places) { place in
                        placeCard(place)
                    }
                }
                .padding(16)
            }

            // Bottom action bar
            VStack(spacing: 0) {
                Divider()
                Button {
                    onArrangeTrip()
                } label: {
                    Label("Ask Planner to Arrange Trip", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Place Card

    private func placeCard(_ place: DiscoveredPlace) -> some View {
        HStack(spacing: 12) {
            // Color bar
            RoundedRectangle(cornerRadius: 3)
                .fill(categoryColor(place.category))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 8) {
                    if let category = place.category {
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(categoryColor(category).opacity(0.12))
                            .foregroundStyle(categoryColor(category))
                            .clipShape(Capsule())
                    }
                    if let day = place.day {
                        Text("Day \(day)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let time = place.time {
                        Text(time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let dur = place.duration {
                        Text(dur)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let desc = place.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Remove button
            Button {
                withAnimation {
                    places.removeAll { $0.id == place.id }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        )
    }

    private func categoryColor(_ category: String?) -> Color {
        switch category?.lowercased() {
        case "hiking", "nature", "trail": return .green
        case "food", "restaurant", "dining": return .orange
        case "photography", "viewpoint": return .purple
        case "museum", "culture", "history": return .brown
        case "beach", "lake", "water": return .blue
        case "hotel", "stay", "accommodation": return .indigo
        default: return .teal
        }
    }
}
