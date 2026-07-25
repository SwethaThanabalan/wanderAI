import SwiftUI

/// Shows details about a place: Wikipedia summary, images, and an add button.
struct PlaceDetailSheet: View {
    let placeName: String
    let onAdd: () -> Void
    let alreadyAdded: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var summary: String?
    @State private var imageURLs: [URL] = []
    @State private var isLoading = true
    @State private var coordinates: (lat: Double, lng: Double)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero image
                    if let firstImage = imageURLs.first {
                        AsyncImage(url: firstImage) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 220)
                                    .clipped()
                            default:
                                placeholderImage
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        LocationImageView(locationName: placeName, height: 200, cornerRadius: 16)
                    }

                    // Title
                    Text(placeName)
                        .font(.title2.bold())

                    // Loading / Summary
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading info...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else if let summary, !summary.isEmpty {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No additional information available.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    // Image gallery
                    if imageURLs.count > 1 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photos")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(imageURLs.dropFirst().prefix(6).enumerated()), id: \.offset) { _, url in
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 140, height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            default:
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: 140, height: 100)
                                            }
                                        }
                                        .frame(width: 140, height: 100)
                                    }
                                }
                            }
                        }
                    }

                    // Add to trip button
                    if !alreadyAdded {
                        Button {
                            onAdd()
                            dismiss()
                        } label: {
                            Label("Add to Trip", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding(.top, 8)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Added to your trip")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 8)
                    }
                }
                .padding(16)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadPlaceInfo() }
        }
    }

    // MARK: - Placeholder

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .frame(maxWidth: .infinity, maxHeight: 220)
            .overlay {
                ProgressView()
            }
    }

    // MARK: - Data Loading

    private func loadPlaceInfo() async {
        isLoading = true

        // Fetch Wikipedia summary
        await fetchWikipediaSummary()

        // Fetch images from Wikimedia Commons
        await fetchImages()

        isLoading = false
    }

    private func fetchWikipediaSummary() async {
        // Search for the page
        let query = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeName
        let searchURL = "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=\(query)&srlimit=1&format=json&origin=*"

        guard let url = URL(string: searchURL) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queryResult = json["query"] as? [String: Any],
                  let search = queryResult["search"] as? [[String: Any]],
                  let first = search.first,
                  let title = first["title"] as? String else { return }

            // Get the page extract
            let encoded = title.replacingOccurrences(of: " ", with: "_")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
            let extractURL = "https://en.wikipedia.org/w/api.php?action=query&titles=\(encoded)&prop=extracts|pageimages&exintro=true&explaintext=true&piprop=original|thumbnail&pithumbsize=800&format=json&origin=*"

            guard let eURL = URL(string: extractURL) else { return }
            let (eData, _) = try await URLSession.shared.data(from: eURL)

            guard let eJson = try? JSONSerialization.jsonObject(with: eData) as? [String: Any],
                  let eQuery = eJson["query"] as? [String: Any],
                  let pages = eQuery["pages"] as? [String: Any],
                  let page = pages.values.first as? [String: Any] else { return }

            if let extract = page["extract"] as? String, !extract.isEmpty {
                summary = extract
            }

            // Get page image
            if let original = page["original"] as? [String: Any],
               let source = original["source"] as? String,
               let imgURL = URL(string: source) {
                imageURLs.insert(imgURL, at: 0)
            } else if let thumbnail = page["thumbnail"] as? [String: Any],
                      let source = thumbnail["source"] as? String,
                      let imgURL = URL(string: source) {
                imageURLs.insert(imgURL, at: 0)
            }
        } catch {
            // Silently fail
        }
    }

    private func fetchImages() async {
        let query = placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeName
        let searchURL = "https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=\(query)&gsrlimit=6&prop=imageinfo&iiprop=url&iiurlwidth=400&format=json&origin=*"

        guard let url = URL(string: searchURL) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queryResult = json["query"] as? [String: Any],
                  let pages = queryResult["pages"] as? [String: Any] else { return }

            for (_, pageData) in pages {
                guard let page = pageData as? [String: Any],
                      let imageinfo = page["imageinfo"] as? [[String: Any]],
                      let first = imageinfo.first,
                      let thumburl = first["thumburl"] as? String,
                      let imgURL = URL(string: thumburl) else { continue }
                if !imageURLs.contains(imgURL) {
                    imageURLs.append(imgURL)
                }
            }
        } catch {
            // Silently fail
        }
    }
}
