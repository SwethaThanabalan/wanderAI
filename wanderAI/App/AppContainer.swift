import SwiftUI
import SwiftData

/// Provides access to shared services throughout the app.
/// Services are resolved using the SwiftData modelContext from the environment.
@MainActor
enum AppContainer {
    static func tripImportService(context: ModelContext) -> TripImportService {
        TripImportService(context: context)
    }

    static func tripRepository(context: ModelContext) -> TripRepository {
        TripRepository(context: context)
    }

    static func tripExecutionService(context: ModelContext) -> TripExecutionService {
        TripExecutionService(context: context)
    }

    static func reviewRepository(context: ModelContext) -> ReviewRepository {
        ReviewRepository(context: context)
    }

    static func preferenceService(context: ModelContext) -> PreferenceService {
        PreferenceService(context: context)
    }
}
