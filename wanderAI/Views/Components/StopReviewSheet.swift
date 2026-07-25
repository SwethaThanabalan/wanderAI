import SwiftUI
import SwiftData

/// Sheet for submitting a review for a stop after marking it complete.
struct StopReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let stopName: String
    let tripId: String
    let stopId: String

    @State private var rating: Int = 4
    @State private var reviewText: String = ""
    @State private var crowdLevel: String = "moderate"

    private let crowdOptions = ["empty", "light", "moderate", "crowded", "packed"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How was it?")
                            .font(.title2.bold())
                        Text(stopName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Star rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.headline)
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                            }
                        }
                    }

                    // Crowd level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How busy was it?")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(crowdOptions, id: \.self) { level in
                                    Button {
                                        crowdLevel = level
                                    } label: {
                                        Text(level.capitalized)
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                crowdLevel == level
                                                    ? Color.green
                                                    : Color(.systemGray5)
                                            )
                                            .foregroundStyle(crowdLevel == level ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        TextField("What did you think? Any tips for others?", text: $reviewText, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }

                    // Submit
                    Button {
                        saveReview()
                    } label: {
                        Text("Save Review")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveReview() {
        let repo = AppContainer.reviewRepository(context: modelContext)
        let review = LocalDestinationReview(
            tripId: tripId,
            stopId: stopId,
            overallRating: rating,
            reviewText: reviewText.isEmpty ? nil : reviewText,
            crowdLevel: crowdLevel
        )
        try? repo.saveDestinationReview(review)
        dismiss()
    }
}
