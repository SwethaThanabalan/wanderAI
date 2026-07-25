import Foundation
import SwiftUI

/// Provides location-specific images using Wikipedia's search + page image APIs.
/// Works with partial names like "Kerry Park skyline stop" → finds "Kerry Park (Seattle)".
/// No API key required.
@MainActor
@Observable
final class LocationImageService {
    static let shared = LocationImageService()

    private var cache: [String: URL] = [:]
    private var inFlight: Set<String> = []
    private var failed: Set<String> = []

    /// Returns cached image URL or nil.
    func cachedURL(for locationName: String) -> URL? {
        cache[locationName]
    }

    /// Fetches a real photo for the location from Wikipedia.
    /// Uses opensearch to handle partial/informal names, then gets page image.
    func fetchImage(for locationName: String) async {
        guard !locationName.isEmpty,
              cache[locationName] == nil,
              !inFlight.contains(locationName),
              !failed.contains(locationName) else { return }

        inFlight.insert(locationName)
        defer { inFlight.remove(locationName) }

        // Clean the name for better search results
        let searchTerm = cleanSearchTerm(locationName)

        // Step 1: Search Wikipedia for the best matching page
        guard let pageTitle = await searchWikipedia(query: searchTerm) else {
            failed.insert(locationName)
            return
        }

        // Step 2: Get the page image
        guard let imageURL = await fetchPageImage(title: pageTitle) else {
            failed.insert(locationName)
            return
        }

        cache[locationName] = imageURL
    }

    // MARK: - Private

    /// Cleans stop names to improve Wikipedia search results.
    /// Removes common suffixes like "skyline stop", "dinner", "departure", etc.
    private func cleanSearchTerm(_ name: String) -> String {
        let lowered = name.lowercased()

        // Skip generic stops that won't have good Wikipedia images
        let genericKinds = ["depart", "check out", "check in", "arrive at", "scheduled event"]
        for generic in genericKinds {
            if lowered.hasPrefix(generic) || lowered.contains(generic) {
                // Use just the location part if possible
                break
            }
        }

        // Remove common suffixes that hurt search
        var cleaned = name
        let suffixes = [
            " skyline stop", " dinner", " sunset", " lunch", " walk",
            " departure", " arrival", " stop", " trail", " trailhead"
        ]
        for suffix in suffixes {
            if cleaned.lowercased().hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count))
            }
        }

        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    /// Searches Wikipedia and returns the best matching page title.
    private func searchWikipedia(query: String) async -> String? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=\(encoded)&srlimit=1&format=json&origin=*"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queryResult = json["query"] as? [String: Any],
                  let search = queryResult["search"] as? [[String: Any]],
                  let first = search.first,
                  let title = first["title"] as? String else {
                return nil
            }
            return title
        } catch {
            return nil
        }
    }

    /// Fetches the main image for a Wikipedia page by title.
    private func fetchPageImage(title: String) async -> URL? {
        let encoded = title
            .replacingOccurrences(of: " ", with: "_")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title

        // Use pageimages API which returns the primary image for a page
        let urlString = "https://en.wikipedia.org/w/api.php?action=query&titles=\(encoded)&prop=pageimages&piprop=original|thumbnail&pithumbsize=800&format=json&origin=*"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let query = json["query"] as? [String: Any],
                  let pages = query["pages"] as? [String: Any],
                  let firstPage = pages.values.first as? [String: Any] else {
                return nil
            }

            // Try original image first
            if let original = firstPage["original"] as? [String: Any],
               let source = original["source"] as? String,
               let imageURL = URL(string: source) {
                return imageURL
            }

            // Fall back to thumbnail
            if let thumbnail = firstPage["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String,
               let imageURL = URL(string: source) {
                return imageURL
            }

            return nil
        } catch {
            return nil
        }
    }
}

// MARK: - Location Image View

/// Async image view that loads a real photo of the location from Wikipedia.
struct LocationImageView: View {
    let locationName: String
    let height: CGFloat
    var cornerRadius: CGFloat = 12

    @State private var imageURL: URL?
    @State private var didFetch = false

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                imageContent
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .task {
                guard !didFetch else { return }
                didFetch = true
                let service = LocationImageService.shared
                if let cached = service.cachedURL(for: locationName) {
                    imageURL = cached
                } else {
                    await service.fetchImage(for: locationName)
                    imageURL = service.cachedURL(for: locationName)
                }
            }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let url = imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderFill
                case .empty:
                    ZStack {
                        placeholderFill
                        ProgressView()
                            .tint(.white)
                    }
                @unknown default:
                    placeholderFill
                }
            }
        } else if didFetch {
            placeholderFill
        } else {
            ZStack {
                placeholderFill
                ProgressView()
                    .tint(.white)
            }
        }
    }

    private var placeholderFill: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            VStack(spacing: 6) {
                Image(systemName: iconForName)
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.4))
                Text(locationName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .padding(.horizontal, 16)
            }
        }
    }

    private var gradientColors: [Color] {
        let sets: [[Color]] = [
            [Color(red: 0.08, green: 0.35, blue: 0.28), Color(red: 0.15, green: 0.55, blue: 0.45)],
            [Color(red: 0.08, green: 0.18, blue: 0.42), Color(red: 0.2, green: 0.38, blue: 0.65)],
            [Color(red: 0.28, green: 0.18, blue: 0.08), Color(red: 0.48, green: 0.35, blue: 0.18)],
            [Color(red: 0.15, green: 0.25, blue: 0.35), Color(red: 0.32, green: 0.45, blue: 0.55)],
            [Color(red: 0.12, green: 0.28, blue: 0.12), Color(red: 0.25, green: 0.48, blue: 0.25)],
        ]
        let index = abs(locationName.hashValue) % sets.count
        return sets[index]
    }

    private var iconForName: String {
        let lower = locationName.lowercased()
        if lower.contains("beach") || lower.contains("coast") || lower.contains("ocean") {
            return "water.waves"
        } else if lower.contains("mountain") || lower.contains("ridge") || lower.contains("peak") || lower.contains("falls") {
            return "mountain.2.fill"
        } else if lower.contains("forest") || lower.contains("park") || lower.contains("trail") || lower.contains("tree") {
            return "leaf.fill"
        } else if lower.contains("hotel") || lower.contains("airport") || lower.contains("city") || lower.contains("market") {
            return "building.2.fill"
        } else if lower.contains("restaurant") || lower.contains("dinner") || lower.contains("lunch") || lower.contains("food") {
            return "fork.knife"
        } else if lower.contains("lake") || lower.contains("river") || lower.contains("ferry") {
            return "water.waves"
        } else {
            let icons = ["mappin.circle.fill", "mountain.2.fill", "leaf.fill", "building.2.fill"]
            return icons[abs(locationName.hashValue) % icons.count]
        }
    }
}
