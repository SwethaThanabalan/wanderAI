import SwiftUI
import SwiftData

/// Beautiful trip card gallery with delete and star functionality.
struct MyTripsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredTrip.importedAt, order: .reverse) private var trips: [StoredTrip]

    @State private var showImport = false

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    emptyState
                } else {
                    tripGallery
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            loadSampleTrip()
                        } label: {
                            Label("Load Sample Trip", systemImage: "sparkles")
                        }
                        Button {
                            showImport = true
                        } label: {
                            Label("Import JSON", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showImport) {
                Text("Import Trip — Coming Soon")
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "dog.fill")
                .font(.system(size: 72))
                .foregroundStyle(.brown.opacity(0.5))

            VStack(spacing: 8) {
                Text("Your next adventure starts here.")
                    .font(.title3.weight(.semibold))
                Text("Load a sample trip or import your own.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                loadSampleTrip()
            } label: {
                Label("Load Sample Trip", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 48)

            Spacer()
        }
    }

    // MARK: - Trip Gallery

    private var tripGallery: some View {
        List {
            ForEach(trips, id: \.tripId) { trip in
                NavigationLink(destination: TripDetailView(storedTrip: trip)) {
                    LargeTripCard(trip: trip)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTrip(trip)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        toggleStar(trip)
                    } label: {
                        Label(
                            trip.isSample ? "Unstar" : "Star",
                            systemImage: trip.isSample ? "star.slash.fill" : "star.fill"
                        )
                    }
                    .tint(.yellow)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Actions

    private func loadSampleTrip() {
        guard let data = SampleTripService.loadSampleData() else {
            print("[wanderAI] ❌ Could not load sample_trip.json from bundle")
            return
        }
        print("[wanderAI] ✅ Loaded sample JSON (\(data.count) bytes)")

        let service = AppContainer.tripImportService(context: modelContext)
        do {
            let document = try service.validate(data: data)
            print("[wanderAI] ✅ Validated: \(document.trip.name) (\(document.trip.days.count) days)")

            if service.existingTrip(for: document.trip.id) != nil {
                print("[wanderAI] ⚠️ Trip already exists with id: \(document.trip.id)")
                return
            }
            try service.importTrip(document: document, data: data)
            print("[wanderAI] ✅ Imported successfully")
        } catch {
            print("[wanderAI] ❌ Import failed: \(error.localizedDescription)")
        }
    }

    private func deleteTrip(_ trip: StoredTrip) {
        modelContext.delete(trip)
        try? modelContext.save()
    }

    private func toggleStar(_ trip: StoredTrip) {
        trip.isSample.toggle() // Repurposing isSample as "starred" for now
        try? modelContext.save()
    }
}

// MARK: - Large Trip Card

struct LargeTripCard: View {
    let trip: StoredTrip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image area
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 240)
                .overlay {
                    Image(systemName: heroIcon)
                        .font(.system(size: 72))
                        .foregroundStyle(.white.opacity(0.15))
                        .offset(x: 60, y: -20)
                }

            // Bottom scrim
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 240)

            // Content overlay
            VStack(alignment: .leading, spacing: 8) {
                // Star badge
                if trip.isSample {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("Starred")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.yellow)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }

                Spacer()

                // Destination
                if let destination = trip.primaryDestination {
                    Text(destination)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Title
                Text(trip.name)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                // Date + days
                HStack(spacing: 12) {
                    if let start = trip.startDate {
                        Label(start, systemImage: "calendar")
                    }
                    Label("\(trip.numberOfDays) days", systemImage: "sun.horizon.fill")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

                // Status
                Text("Ready")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 6)
    }

    // MARK: - Visuals

    private var gradientColors: [Color] {
        let sets: [[Color]] = [
            [Color(red: 0.1, green: 0.4, blue: 0.3), Color(red: 0.2, green: 0.6, blue: 0.5)],
            [Color(red: 0.1, green: 0.2, blue: 0.5), Color(red: 0.3, green: 0.4, blue: 0.7)],
            [Color(red: 0.4, green: 0.2, blue: 0.1), Color(red: 0.6, green: 0.4, blue: 0.2)],
            [Color(red: 0.2, green: 0.3, blue: 0.4), Color(red: 0.4, green: 0.5, blue: 0.6)]
        ]
        let index = abs(trip.tripId.hashValue) % sets.count
        return sets[index]
    }

    private var heroIcon: String {
        let icons = ["mountain.2.fill", "water.waves", "leaf.fill", "sun.horizon.fill", "tree.fill"]
        let index = abs(trip.name.hashValue) % icons.count
        return icons[index]
    }
}
