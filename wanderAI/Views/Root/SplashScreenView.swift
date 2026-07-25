import SwiftUI

/// Splash screen shown on app launch with the loading image.
/// Fades out after a brief delay to reveal the main app.
struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            if isActive {
                AppRouter()
                    .transition(.opacity)
            } else {
                splashContent
                    .opacity(opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isActive)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation {
                    isActive = true
                }
            }
        }
    }

    private var splashContent: some View {
        GeometryReader { geo in
            Image("LoadingScreenImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
