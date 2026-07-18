import SwiftUI
import SwiftData

/// Cinematic intro transition before opening the trip map.
/// P0: Simple state name + fade animation placeholder.
struct TripIntroView: View {
    let storedTrip: StoredTrip
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var phase: IntroPhase = .stateName
    @State private var showMap = false

    enum IntroPhase {
        case stateName
        case ready
        case openingMap
    }

    var body: some View {
        ZStack {
            if showMap {
                // Directly show the trip detail
                TripDetailView(storedTrip: storedTrip)
                    .transition(.opacity)
            } else {
                introContent
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showMap)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                phase = .ready
            }
        }
    }

    private var introContent: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.black, Color(.systemGray6).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // State / Destination
                VStack(spacing: 12) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.6))

                    Text(storedTrip.primaryDestination ?? "Adventure Awaits")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(storedTrip.name)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Ready indicator
                if phase == .ready {
                    VStack(spacing: 16) {
                        Text("Ready to Travel")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))

                        Button {
                            showMap = true
                        } label: {
                            Text("Open Trip")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding(.horizontal, 48)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Dismiss
                Button {
                    dismiss()
                } label: {
                    Text("Back")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 32)
            }
        }
    }
}
