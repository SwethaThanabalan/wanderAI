import SwiftUI
import SwiftData

/// Trip detail screen — day-by-day plan with inline chat agent for updates.
struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tripPayload: TripPayload?
    @State private var loadError: String?
    @State private var showChat = false
    @State private var showExecution = false
    @State private var executionStartDay = 0
    @State private var isEditingName = false
    @State private var editedName: String = ""

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if isEditingName {
                        TextField("Trip name", text: $editedName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .onSubmit { saveName() }
                    } else {
                        Button { startEditingName() } label: {
                            HStack(spacing: 4) {
                                Text(storedTrip.name)
                                    .font(.headline)
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if isEditingName {
                            Button("Done") { saveName() }
                                .fontWeight(.semibold)
                        } else {
                            Button { showChat = true } label: {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.green)
                            }
                            Button {
                                executionStartDay = 0
                                showExecution = true
                            } label: {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showChat) {
                tripChatSheet
            }
            .fullScreenCover(isPresented: $showExecution) {
                if let trip = tripPayload {
                    TripExecutionView(
                        tripPayload: trip,
                        storedTrip: storedTrip,
                        startingDay: executionStartDay
                    )
                }
            }
        }
        .onAppear { loadTrip() }
    }

    // MARK: - Trip Content

    private func tripContent(_ trip: TripPayload) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Trip header
                tripHeader(trip)

                // Days
                ForEach(trip.days, id: \.id) { day in
                    daySection(day)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Trip Header

    private func tripHeader(_ trip: TripPayload) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let dest = trip.primaryDestination {
                LocationImageView(locationName: dest, height: 180, cornerRadius: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                if let dest = trip.primaryDestination {
                    Label(dest, systemImage: "mappin.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let summary = trip.summary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Stats
                HStack(spacing: 16) {
                    Label("\(trip.days.count) days", systemImage: "sun.horizon")
                    Label("\(trip.days.flatMap(\.stops).count) stops", systemImage: "mappin")
                    if let dist = trip.plannedDistanceMiles {
                        Label("\(Int(dist)) mi", systemImage: "car.fill")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Chat agent button
                Button { showChat = true } label: {
                    Label("Ask AI to update this trip", systemImage: "sparkles")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .padding(.top, 4)

                // Start execution mode
                Button {
                    executionStartDay = 0
                    showExecution = true
                } label: {
                    Label("Start Trip", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Day Section

    private func daySection(_ day: DayPayload) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Day \(day.dayNumber)")
                        .font(.title3.bold())
                    if let date = day.date {
                        Text(fmtDate(date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                Text(day.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    if let driving = day.estimatedDrivingMinutes {
                        Label("\(driving) min", systemImage: "car.fill")
                    }
                    if let dist = day.plannedDistanceMiles {
                        Label("\(Int(dist)) mi", systemImage: "road.lanes")
                    }
                    Label("\(day.stops.count) stops", systemImage: "mappin")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)

            // Day map
            DayMapView(stops: day.stops, height: 140)
                .padding(.horizontal, 16)

            // Stop cards
            ForEach(day.stops, id: \.id) { stop in
                NavigationLink {
                    StopDetailView(
                        stop: stop,
                        tripId: storedTrip.tripId,
                        region: tripPayload?.primaryDestination ?? "",
                        visitDate: day.date ?? tripPayload?.startDate ?? ""
                    )
                } label: {
                    stopCard(stop)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
    }

    // MARK: - Stop Card

    private func stopCard(_ stop: StopPayload) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            LocationImageView(locationName: stop.name, height: 60, cornerRadius: 10)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle().fill(.green).frame(width: 20, height: 20)
                        Text("\(stop.sequence)")
                            .font(.system(size: 9).bold())
                            .foregroundStyle(.white)
                    }
                    Text(stop.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if let time = stop.plannedTime {
                        Label(time, systemImage: "clock")
                    }
                    if let dur = stop.estimatedDurationMinutes {
                        Label("\(dur) min", systemImage: "hourglass")
                    }
                    if let cat = stop.category {
                        Text(cat.replacingOccurrences(of: "_", with: " "))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if let summary = stop.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // MARK: - Chat Sheet

    private var tripChatSheet: some View {
        NavigationStack {
            ChatView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { showChat = false }
                    }
                }
        }
    }

    // MARK: - Name Editing

    private func startEditingName() {
        editedName = storedTrip.name
        isEditingName = true
    }

    private func saveName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && trimmed != storedTrip.name {
            storedTrip.name = trimmed
            try? modelContext.save()
        }
        isEditingName = false
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

    // MARK: - Helpers

    private func fmtDate(_ d: String) -> String {
        let p = d.split(separator: "-")
        guard p.count == 3, let m = Int(p[1]), let day = Int(p[2]) else { return d }
        let ms = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        guard m > 0, m < ms.count else { return d }
        return "\(ms[m]) \(day)"
    }

    private func loadTrip() {
        do {
            let document = try JSONDecoder().decode(TripImportDocument.self, from: storedTrip.rawJSON)
            tripPayload = document.trip
        } catch {
            loadError = error.localizedDescription
        }
    }
}

// MARK: - StopPayload Identifiable for sheet

extension StopPayload: Identifiable {}
