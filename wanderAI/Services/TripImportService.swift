import Foundation
import SwiftData

/// Validates and imports trip JSON into local SwiftData storage.
@MainActor
final class TripImportService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    enum ImportError: LocalizedError {
        case invalidJSON(String)
        case invalidFormat
        case unsupportedVersion(String)
        case duplicateTrip(String)
        case missingRequiredField(String)

        var errorDescription: String? {
            switch self {
            case .invalidJSON(let detail):
                return "The selected file could not be read as valid JSON. \(detail)"
            case .invalidFormat:
                return "This file is not a wanderAI trip."
            case .unsupportedVersion(let version):
                return "This trip uses format version \(version), which this version of wanderAI cannot open."
            case .duplicateTrip(let id):
                return "A trip with identifier \"\(id)\" already exists."
            case .missingRequiredField(let field):
                return "\(field) is missing from the imported data."
            }
        }
    }

    enum DuplicateStrategy {
        case replace
        case importAsCopy
        case cancel
    }

    /// Decodes and validates trip JSON data. Returns the parsed document.
    func validate(data: Data) throws -> TripImportDocument {
        // Detect schema version by peeking at the JSON
        let document: TripImportDocument

        if let peek = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           peek["schemaVersion"] != nil {
            // V2 schema
            let v2Root: TripImportV2Root
            do {
                v2Root = try JSONDecoder().decode(TripImportV2Root.self, from: data)
            } catch {
                throw ImportError.invalidJSON(error.localizedDescription)
            }

            guard v2Root.schemaVersion.hasPrefix("2.") else {
                throw ImportError.unsupportedVersion(v2Root.schemaVersion)
            }

            document = v2Root.toV1Document()
        } else {
            // V1 schema
            do {
                document = try JSONDecoder().decode(TripImportDocument.self, from: data)
            } catch {
                throw ImportError.invalidJSON(error.localizedDescription)
            }

            guard document.format == "wanderAI.trip" else {
                throw ImportError.invalidFormat
            }

            guard document.formatVersion.hasPrefix("1.") else {
                throw ImportError.unsupportedVersion(document.formatVersion)
            }
        }

        guard !document.trip.days.isEmpty else {
            throw ImportError.missingRequiredField("At least one day")
        }

        for day in document.trip.days {
            guard !day.stops.isEmpty else {
                throw ImportError.missingRequiredField("Day \"\(day.title)\" requires at least one stop")
            }
        }

        return document
    }

    /// Checks if a trip with the same ID already exists.
    func existingTrip(for tripId: String) -> StoredTrip? {
        let descriptor = FetchDescriptor<StoredTrip>(
            predicate: #Predicate { $0.tripId == tripId }
        )
        return try? context.fetch(descriptor).first
    }

    /// Imports a validated trip document into local storage.
    func importTrip(document: TripImportDocument, data: Data, strategy: DuplicateStrategy = .cancel) throws {
        let trip = document.trip

        if let existing = existingTrip(for: trip.id) {
            switch strategy {
            case .replace:
                context.delete(existing)
            case .importAsCopy:
                break // Will use a modified ID below
            case .cancel:
                throw ImportError.duplicateTrip(trip.id)
            }
        }

        let tripId = strategy == .importAsCopy ? "\(trip.id)-copy-\(UUID().uuidString.prefix(8))" : trip.id

        // Re-encode the (possibly converted) document so rawJSON always decodes as TripImportDocument
        let storedJSON: Data
        if let reEncoded = try? JSONEncoder().encode(document) {
            storedJSON = reEncoded
        } else {
            storedJSON = data
        }

        let stored = StoredTrip(
            tripId: tripId,
            name: trip.name,
            primaryDestination: trip.primaryDestination,
            startDate: trip.startDate,
            endDate: trip.endDate,
            numberOfDays: trip.days.count,
            coverImageAsset: trip.coverImage?.value,
            isSample: document.trip.metadata?.isSample ?? false,
            rawJSON: storedJSON
        )

        context.insert(stored)
        try context.save()
    }
}
