// TripImportService.swift
// Decodes TripExport JSON and maps to SwiftData models
import Foundation
import SwiftData

enum TripImportError: Error {
    case decodingFailed(Error)
    case mappingNotImplemented(String)
}

@MainActor
final class TripImportService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func importTrip(from jsonData: Data) throws {
        let decoder = JSONDecoder.tripImportDecoder()
        let export: TripExport
        do {
            export = try decoder.decode(TripExport.self, from: jsonData)
        } catch {
            throw TripImportError.decodingFailed(error)
        }

        // Map TripDTO to your SwiftData models. The following is a scaffold with TODOs.
        // Example: create a StoredTrip and related entities.
        // Replace with your actual model types and relationships.

        // TODO: Implement mapping from TripDTO to StoredTrip and related models
        throw TripImportError.mappingNotImplemented("Map TripDTO to StoredTrip and child entities.")
    }
}
