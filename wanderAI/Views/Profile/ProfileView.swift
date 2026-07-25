import SwiftUI
import SwiftData

/// Profile tab — view past trips, manage preferences, and app settings.
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredTrip.importedAt, order: .reverse) private var trips: [StoredTrip]

    @State private var preferences: PreferencePayload?
    @State private var showPreferenceEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Stats
                    statsSection

                    // Preferences
                    preferencesSection

                    // Past trips
                    pastTripsSection
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showPreferenceEditor) {
                PreferenceEditorSheet(
                    currentPreferences: preferences,
                    onSave: { newPrefs in
                        preferences = newPrefs
                    }
                )
            }
            .onAppear { loadPreferences() }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text("Traveler")
                .font(.title3.bold())

            Text("Adventure awaits")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(value: "\(trips.count)", label: "Trips")
            Divider().frame(height: 36)
            statItem(value: "\(totalStops)", label: "Stops")
            Divider().frame(height: 36)
            statItem(value: "\(completedStops)", label: "Visited")
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 16)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var totalStops: Int {
        trips.reduce(0) { total, trip in
            guard let doc = try? JSONDecoder().decode(TripImportDocument.self, from: trip.rawJSON) else { return total }
            return total + doc.trip.days.flatMap(\.stops).count
        }
    }

    private var completedStops: Int {
        let descriptor = FetchDescriptor<StopExecutionState>(
            predicate: #Predicate { $0.status == "completed" }
        )
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Travel Preferences")
                    .font(.headline)
                Spacer()
                Button {
                    showPreferenceEditor = true
                } label: {
                    Text(preferences == nil ? "Set Up" : "Edit")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            if let prefs = preferences {
                preferenceSummary(prefs)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundStyle(.green.opacity(0.6))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No preferences set")
                            .font(.subheadline.weight(.medium))
                        Text("Set your travel style, pace, and dietary needs.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(.horizontal, 16)
    }

    private func preferenceSummary(_ prefs: PreferencePayload) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let style = prefs.travelStyle {
                if let pace = style.pace {
                    prefRow(icon: "speedometer", label: "Pace", value: pace.capitalized)
                }
                if let maxActs = style.maximumActivitiesPerDay {
                    prefRow(icon: "list.bullet", label: "Max activities/day", value: "\(maxActs)")
                }
            }
            if let food = prefs.foodPreferences {
                if let restrictions = food.dietaryRestrictions, !restrictions.isEmpty {
                    prefRow(icon: "fork.knife", label: "Dietary", value: restrictions.joined(separator: ", "))
                }
            }
            if let driving = prefs.drivingPreferences {
                if let scenic = driving.scenicRoutesPreferred, scenic {
                    prefRow(icon: "road.lanes", label: "Scenic routes", value: "Preferred")
                }
                if let maxDrive = driving.maximumDrivingMinutesPerDay {
                    prefRow(icon: "car.fill", label: "Max driving", value: "\(maxDrive) min/day")
                }
            }
            if let comp = prefs.travelerComposition {
                if let adults = comp.adultCount {
                    prefRow(icon: "person.2.fill", label: "Group", value: "\(adults) adult\(adults == 1 ? "" : "s")")
                }
                if comp.travelsWithPets == true {
                    prefRow(icon: "pawprint.fill", label: "Pets", value: "Travels with pet")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func prefRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.green)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
        }
    }

    // MARK: - Past Trips

    private var pastTripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Trips")
                .font(.headline)
                .padding(.horizontal, 16)

            if trips.isEmpty {
                Text("No trips yet. Import or load a sample trip to get started.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            } else {
                ForEach(trips, id: \.tripId) { trip in
                    pastTripRow(trip)
                }
            }
        }
    }

    private func pastTripRow(_ trip: StoredTrip) -> some View {
        HStack(spacing: 14) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: tripGradient(trip),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if let dest = trip.primaryDestination {
                        Text(dest)
                            .lineLimit(1)
                    }
                    Text("\(trip.numberOfDays) days")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if let date = trip.startDate {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func tripGradient(_ trip: StoredTrip) -> [Color] {
        let sets: [[Color]] = [
            [.green, .teal],
            [.blue, .indigo],
            [.orange, .pink],
            [.purple, .blue],
        ]
        return sets[abs(trip.tripId.hashValue) % sets.count]
    }

    // MARK: - Load

    private func loadPreferences() {
        let service = AppContainer.preferenceService(context: modelContext)
        guard let stored = service.loadPreferences() else { return }
        preferences = try? JSONDecoder().decode(PreferencePayload.self, from: stored.rawJSON)
    }
}
