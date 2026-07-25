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

    // MARK: - Audio Tour

    static let audioTourAPIService = AudioTourAPIService()

    // MARK: - Chat

    static let chatAPIService = ChatAPIService()

    /// Creates a conversation store configured with the given model context.
    static func conversationStore(context: ModelContext) -> AIConversationStore {
        let store = AIConversationStore()
        store.configure(modelContext: context)
        return store
    }

    static var audioTourDownloadService: AudioTourDownloadService {
        AudioTourDownloadService(apiService: audioTourAPIService)
    }

    static func audioTourPlayerService() -> AudioTourPlayerService {
        AudioTourPlayerService()
    }

    static func audioTourViewModel(
        tripId: String,
        stopId: String,
        destinationName: String,
        region: String,
        visitDate: String,
        context: ModelContext
    ) -> AudioTourViewModel {
        AudioTourViewModel(
            tripId: tripId,
            stopId: stopId,
            destinationName: destinationName,
            region: region,
            visitDate: visitDate,
            context: context,
            apiService: audioTourAPIService,
            downloadService: audioTourDownloadService,
            playerService: audioTourPlayerService()
        )
    }
}
