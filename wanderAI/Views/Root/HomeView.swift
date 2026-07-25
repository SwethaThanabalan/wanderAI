import SwiftUI
import SwiftData

/// Home screen matching the design mockup.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredTrip.importedAt, order: .reverse) private var trips: [StoredTrip]
    @State private var showChat = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    searchBar
                    if let upcoming = trips.first { upcomingTripCard(upcoming) }
                    quickActions
                    if trips.count > 1 { continuePlanningSection }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe.americas.fill").font(.title3).foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("WanderAI").font(.subheadline.bold())
                            Text("Your AI Travel Companion").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LocationImageView(locationName: "Olympic Mountains Washington", height: 220, cornerRadius: 0)
            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom).frame(height: 220)
            VStack(alignment: .leading, spacing: 6) {
                Text("Let's make\nmemories").font(.title.bold()).foregroundStyle(.white)
                Text("Wanderful").font(.title2.italic()).foregroundStyle(.green)
                Text("Smart trips. Real experiences.\nPowered by AI.").font(.caption).foregroundStyle(.white.opacity(0.7))
            }.padding(20)
        }
    }

    private var searchBar: some View {
        Button { showChat = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles").foregroundStyle(.green)
                Text("Where shall we wander next?").foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "arrow.right.circle.fill").foregroundStyle(.green.opacity(0.6))
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 25).fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain).padding(.horizontal, 16)
        .fullScreenCover(isPresented: $showChat) {
            NavigationStack {
                ChatView()
                    .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { showChat = false } } }
            }
        }
    }

    private func upcomingTripCard(_ trip: StoredTrip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Trip").font(.headline)
                Spacer()
                NavigationLink(destination: TripDetailView(storedTrip: trip)) {
                    Text("View Itinerary").font(.caption.weight(.semibold)).foregroundStyle(.green)
                }
            }.padding(.horizontal, 16)
            NavigationLink(destination: TripDetailView(storedTrip: trip)) {
                HStack(spacing: 14) {
                    LocationImageView(locationName: trip.primaryDestination ?? trip.name, height: 110, cornerRadius: 12).frame(width: 130)
                    VStack(alignment: .leading, spacing: 8) {
                        if let s = trip.startDate, let e = trip.endDate {
                            Text("\(fmtDate(s)) - \(fmtDate(e))").font(.caption2).foregroundStyle(.green)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.green.opacity(0.15)).clipShape(Capsule())
                        }
                        Text(trip.name).font(.subheadline.bold()).lineLimit(2)
                        if let dest = trip.primaryDestination {
                            Label(dest, systemImage: "mappin").font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 10) {
                            Label("\(trip.numberOfDays)", systemImage: "sun.horizon").font(.caption2)
                            Label("Days", systemImage: "").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }.padding(12).background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2))
            }.buttonStyle(.plain).padding(.horizontal, 16)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions").font(.headline).padding(.horizontal, 16)
            HStack(spacing: 12) {
                qaBtn(icon: "safari.fill", label: "Browse\nTrips", color: .blue)
                qaBtn(icon: "map.fill", label: "My\nTrips", color: .purple)
                qaBtn(icon: "heart.fill", label: "Favorites", color: .pink)
                qaBtn(icon: "arrow.down.circle.fill", label: "Offline\nMaps", color: .teal)
            }.padding(.horizontal, 16)
        }
    }

    private func qaBtn(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
            Text(label).font(.caption2).multilineTextAlignment(.center).lineLimit(2).frame(height: 28)
        }.frame(maxWidth: .infinity)
    }

    private var continuePlanningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Continue Planning").font(.headline)
                Spacer()
                Text("View All").font(.caption.weight(.semibold)).foregroundStyle(.green)
            }.padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trips.prefix(5), id: \.tripId) { trip in
                        NavigationLink(destination: TripDetailView(storedTrip: trip)) {
                            VStack(alignment: .leading, spacing: 6) {
                                LocationImageView(locationName: trip.primaryDestination ?? trip.name, height: 100, cornerRadius: 10).frame(width: 150)
                                Text(trip.name).font(.caption.weight(.semibold)).lineLimit(1)
                                if let s = trip.startDate, let e = trip.endDate {
                                    Text("\(fmtDate(s)) - \(fmtDate(e))").font(.caption2).foregroundStyle(.secondary)
                                }
                            }.frame(width: 150)
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 16)
            }
        }
    }

    private func fmtDate(_ d: String) -> String {
        let p = d.split(separator: "-")
        guard p.count == 3, let m = Int(p[1]), let day = Int(p[2]) else { return d }
        let ms = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        guard m > 0, m < ms.count else { return d }
        return "\(ms[m]) \(day)"
    }
}
