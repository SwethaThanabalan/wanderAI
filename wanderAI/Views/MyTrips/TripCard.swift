import SwiftUI

/// Beautiful destination card — hero image, state, title, date.
struct TripCard: View {
    let trip: StoredTrip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image placeholder
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay {
                    Image(systemName: heroIcon)
                        .font(.system(size: 56))
                        .foregroundStyle(.white.opacity(0.2))
                }

            // Bottom gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .frame(height: 220)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Status badge
                Text(statusLabel)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                Text(trip.primaryDestination ?? "Adventure")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Text(trip.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if let date = trip.startDate {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(20)
        }
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    // MARK: - Status

    private var statusLabel: String {
        "Ready" // TODO: Check execution state
    }

    private var statusColor: Color {
        .green
    }

    // MARK: - Visual Variation

    private var gradientColors: [Color] {
        let sets: [[Color]] = [
            [.green.opacity(0.6), .teal.opacity(0.8)],
            [.blue.opacity(0.5), .indigo.opacity(0.7)],
            [.orange.opacity(0.5), .pink.opacity(0.6)],
            [.purple.opacity(0.5), .blue.opacity(0.7)]
        ]
        let index = abs(trip.tripId.hashValue) % sets.count
        return sets[index]
    }

    private var heroIcon: String {
        let icons = ["mountain.2.fill", "water.waves", "leaf.fill", "sun.horizon.fill"]
        let index = abs(trip.tripId.hashValue) % icons.count
        return icons[index]
    }
}
