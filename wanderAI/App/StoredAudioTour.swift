// StoredAudioTour.swift
// Minimal placeholder to unblock builds and allow importer work
import Foundation
import SwiftData

@Model
final class StoredAudioTour {
    @Attribute(.unique) var id: UUID
    var stableUUID: UUID?
    var title: String?
    var createdAt: Date

    init(id: UUID = UUID(), stableUUID: UUID? = nil, title: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.stableUUID = stableUUID
        self.title = title
        self.createdAt = createdAt
    }
}
