import SwiftUI
import SwiftData

@main
struct WanderAIApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: StoredTrip.self,
                TripExecutionState.self,
                StopExecutionState.self,
                LocalDestinationReview.self,
                LocalTripReview.self,
                StoredPreferences.self,
                StoredAudioTour.self,
                StoredConversation.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
        .modelContainer(modelContainer)
    }
}
