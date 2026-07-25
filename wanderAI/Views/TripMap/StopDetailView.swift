import SwiftUI
import SwiftData

/// Destination detail screen showing stop information and audio tour controls.
struct StopDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let stop: StopPayload
    let tripId: String
    let region: String
    let visitDate: String

    @State private var viewModel: AudioTourViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stop header
                headerSection

                // Summary & description
                if let summary = stop.summary {
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if let description = stop.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // History
                if let history = stop.history {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("History")
                            .font(.headline)
                        Text(history)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Practical info
                if let practical = stop.practicalInformation {
                    practicalSection(practical)
                }

                Divider()

                // Audio Tour
                if let vm = viewModel {
                    AudioTourCard(viewModel: vm)
                        .sheet(isPresented: Binding(
                            get: { vm.showSetupSheet },
                            set: { vm.showSetupSheet = $0 }
                        )) {
                            AudioTourSetupSheet(destinationName: stop.name) { duration, personas in
                                Task {
                                    await vm.submitJob(durationMinutes: duration, personas: personas)
                                }
                            }
                        }
                }

                // Must Do
                if let mustDo = stop.mustDo, !mustDo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Must Do")
                            .font(.headline)
                        ForEach(mustDo, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .padding(.top, 2)
                                Text(item)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                // Highlights
                if let highlights = stop.highlights, !highlights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Highlights")
                            .font(.headline)
                        ForEach(highlights, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "sparkle")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .padding(.top, 2)
                                Text(item)
                                    .font(.subheadline)
                            }
                        }
                    }
                }

                // Suitability
                if let suit = stop.suitability {
                    suitabilitySection(suit)
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle(stop.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setupViewModel() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hero image from Wikipedia (or gradient placeholder if none found)
            LocationImageView(locationName: stop.name, height: 200, cornerRadius: 16)

            HStack {
                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 36, height: 36)
                    Text("\(stop.sequence)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stop.name)
                        .font(.title3.bold())
                    if let category = stop.category {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                if let time = stop.plannedTime {
                    Label(time, systemImage: "clock")
                }
                if let duration = stop.estimatedDurationMinutes {
                    Label("\(duration) min", systemImage: "hourglass")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Practical Info

    private func practicalSection(_ info: PracticalInformation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Practical Info")
                .font(.headline)

            if let hours = info.openingHours {
                Label(hours, systemImage: "clock.fill")
                    .font(.caption)
            }
            if let admission = info.admission {
                Label(admission, systemImage: "ticket.fill")
                    .font(.caption)
            }
            if let phone = info.phone {
                Label(phone, systemImage: "phone.fill")
                    .font(.caption)
            }
            if let website = info.website {
                Label(website, systemImage: "globe")
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.secondary)
    }

    // MARK: - Suitability

    private func suitabilitySection(_ suit: SuitabilityInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility")
                .font(.headline)

            HStack(spacing: 12) {
                if let dog = suit.dogFriendly {
                    suitBadge(icon: "pawprint.fill", label: "Dogs", status: dog.status)
                }
                if let kid = suit.kidFriendly {
                    suitBadge(icon: "figure.and.child.holdinghands", label: "Kids", status: kid.status)
                }
                if let older = suit.olderAdultFriendly {
                    suitBadge(icon: "figure.walk", label: "Seniors", status: older.status)
                }
                if let wheel = suit.wheelchairAccessible {
                    suitBadge(icon: "figure.roll", label: "Wheelchair", status: wheel.status)
                }
            }
        }
    }

    private func suitBadge(icon: String, label: String, status: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(suitColor(status))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func suitColor(_ status: String) -> Color {
        switch status {
        case "yes": return .green
        case "partial": return .orange
        case "no": return .red
        default: return .gray
        }
    }

    // MARK: - Setup

    private func setupViewModel() {
        guard viewModel == nil else { return }
        viewModel = AppContainer.audioTourViewModel(
            tripId: tripId,
            stopId: stop.id,
            destinationName: stop.name,
            region: region,
            visitDate: visitDate,
            context: modelContext
        )
    }
}
