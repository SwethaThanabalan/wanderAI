import Foundation
import SwiftData

/// Manages user preference storage and export.
@MainActor
final class PreferenceService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadPreferences() -> StoredPreferences? {
        let descriptor = FetchDescriptor<StoredPreferences>()
        return try? context.fetch(descriptor).first
    }

    func savePreferences(_ payload: PreferencePayload) throws {
        let data = try JSONEncoder().encode(payload)

        if let existing = loadPreferences() {
            existing.rawJSON = data
            existing.updatedAt = .now
        } else {
            let stored = StoredPreferences(rawJSON: data)
            context.insert(stored)
        }

        try context.save()
    }

    func exportJSON() throws -> Data {
        guard let stored = loadPreferences() else {
            throw PreferenceError.noPreferences
        }

        let payload = try JSONDecoder().decode(PreferencePayload.self, from: stored.rawJSON)
        let document = PreferenceExportDocument(
            format: "wanderAI.preferences",
            formatVersion: "1.0.0",
            exportedAt: ISO8601DateFormatter().string(from: .now),
            preferences: payload
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(document)
    }

    enum PreferenceError: LocalizedError {
        case noPreferences

        var errorDescription: String? {
            "No preferences have been saved yet."
        }
    }
}
