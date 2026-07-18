import SwiftUI

/// Root tab navigation. Only My Trips is functional for P0.
struct MainTabView: View {
    @State private var selectedTab = 1 // My Trips

    var body: some View {
        TabView(selection: $selectedTab) {
            PlaceholderTab(icon: "house.fill", title: "Home", message: "Your personalized travel feed is coming soon.")
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            MyTripsView()
                .tag(1)
                .tabItem {
                    Label("My Trips", systemImage: "map.fill")
                }

            PlaceholderTab(icon: "safari.fill", title: "Explore", message: "Discover destinations and routes in a future release.")
                .tag(2)
                .tabItem {
                    Label("Explore", systemImage: "safari.fill")
                }

            PlaceholderTab(icon: "person.crop.circle.fill", title: "Profile", message: "Your traveler profile and preferences are coming soon.")
                .tag(3)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.green)
    }
}

// MARK: - Placeholder Tab

struct PlaceholderTab: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.4))
            Text(title)
                .font(.title2.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            Spacer()
        }
    }
}

#Preview {
    MainTabView()
}
