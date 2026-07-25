import SwiftUI

/// Beautiful destination card — real location image with fallback gradient, title, date.
struct TripCard: View {
    let trip: StoredTrip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image from Wikipedia or gradient fallback
            LocationImageView(
                locationName: trip.primaryDestination ?? trip.name,
                height: 220,
                cornerRadius: 20
            )

            // Bottom gradient overlay for text legibility
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.75)],
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
        "Ready"
    }

    private var statusColor: Color {
        .green
    }
}
