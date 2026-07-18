import SwiftUI
import SwiftData

/// Trip detail screen — lists destinations by day.
/// Map is disabled until we confirm data is loading correctly.
struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tripPayload: TripPayload?
    @State private var loadError: String?

    let storedTrip: StoredTrip

    var body: some View {
        NavigationStack {
            Group {
                if let trip = tripPayload {
                    tripContent(trip)
                } else if let error = loadError {
                    errorView(error)
                } else {
                    ProgressView("Loading trip...")
                }
            }
            .navigationTitle(storedTrip.name)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { loadTrip() }
    }

    // MARK: - Trip Content

    private func tripContent(_ trip: TripPayload) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Trip header
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.name)
                        .font(.title2.bold())

                    if let dest = trip.primaryDestination {
                        Text(dest)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let summary = trip.summary {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        Label("\(trip.days.count) days", systemImage: "sun.horizon")
                        Label("\(trip.days.flatMap(\.stops).count) stops", systemImage: "mappin.circle.fill")
                        if let dist = trip.plannedDistanceMiles {
                            Label("\(Int(dist)) mi", systemImage: "car.fill")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                }
                .padding(.horizontal)

                // Days
                ForEach(trip.days, id: \.id) { day in
                    daySection(day)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Day Section

    private func daySection(_ day: DayPayload) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(day.dayNumber)")
                        .font(.headline)
                    Text(day.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let dist = day.plannedDistanceMiles {
                    Text("\(Int(dist)) mi")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)

            // Stops
            ForEach(day.stops, id: \.id) { stop in
                stopCard(stop)
            }

            // Route highlights
            if let highlights = day.routeHighlights, !highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Along the Route")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal)

                    ForEach(highlights, id: \.id) { hl in
                        highlightRow(hl)
                    }
                }
            }

            Divider()
                .padding(.horizontal)
        }
    }

    // MARK: - Stop Card

    private func stopCard(_ stop: StopPayload) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Sequence badge
            ZStack {
                Circle()
                    .fill(.green)
                    .frame(width: 36, height: 36)
                Text("\(stop.sequence)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.subheadline.weight(.semibold))

                if let summary = stop.summary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let time = stop.plannedTime {
                        Label(time, systemImage: "clock")
                    }
                    if let duration = stop.estimatedDurationMinutes {
                        Label("\(duration) min", systemImage: "hourglass")
                    }
                    if let category = stop.category {
                        Text(category)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                // Suitability badges
                if let suit = stop.suitability {
                    suitabilityRow(suit)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func suitabilityRow(_ suit: SuitabilityInfo) -> some View {
        HStack(spacing: 6) {
            if let dog = suit.dogFriendly {
                badge(icon: "pawprint.fill", status: dog.status)
            }
            if let kid = suit.kidFriendly {
                badge(icon: "figure.and.child.holdinghands", status: kid.status)
            }
            if let older = suit.olderAdultFriendly {
                badge(icon: "figure.walk", status: older.status)
            }
            if let wheel = suit.wheelchairAccessible {
                badge(icon: "figure.roll", status: wheel.status)
            }
        }
        .padding(.top, 2)
    }

    private func badge(icon: String, status: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 10))
            .foregroundStyle(badgeColor(status))
    }

    private func badgeColor(_ status: String) -> Color {
        switch status {
        case "yes": return .green
        case "partial": return .orange
        case "no": return .red
        default: return .gray
        }
    }

    // MARK: - Route Highlight Row

    private func highlightRow(_ hl: RouteHighlightPayload) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(hl.name)
                    .font(.caption.weight(.medium))
                if let desc = hl.description {
                    Text(desc)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let detour = hl.estimatedDetourMinutes {
                Text("+\(detour) min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Unable to load trip")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Load

    private func loadTrip() {
        print("[wanderAI] Loading trip: \(storedTrip.tripId), rawJSON size: \(storedTrip.rawJSON.count) bytes")

        do {
            let document = try JSONDecoder().decode(TripImportDocument.self, from: storedTrip.rawJSON)
            tripPayload = document.trip
            print("[wanderAI] ✅ Decoded: \(document.trip.name), \(document.trip.days.count) days")
        } catch {
            loadError = error.localizedDescription
            print("[wanderAI] ❌ Decode failed: \(error)")
        }
    }
}
