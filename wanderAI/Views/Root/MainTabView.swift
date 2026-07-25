import SwiftUI

/// Root tab navigation matching the design mockup.
/// Tabs: Home, My Trips, AI Assistant (center), Profile
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            MyTripsView()
                .tag(1)
                .tabItem {
                    Label("My Trips", systemImage: "map.fill")
                }

            ChatView()
                .tag(2)
                .tabItem {
                    Label("AI Assistant", systemImage: "sparkles")
                }

            ProfileView()
                .tag(3)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.green)
    }
}

#Preview {
    MainTabView()
}
