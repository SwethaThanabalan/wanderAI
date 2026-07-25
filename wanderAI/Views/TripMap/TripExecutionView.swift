import SwiftUI
import SwiftData
import MapKit

/// Execution mode for a trip day — shows current stop with one-click navigation and audio tour.
struct TripExecutionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tripPayload: TripPayload
    let storedTrip: StoredTrip
    @State private var selectedDayIndex: Int

    init(tripPayload: TripPayload, storedTrip: StoredTrip, startingDay: Int = 0) {
        self.tripPayload = tripPayload
        self.storedTrip = storedTrip
        self._selectedDayIndex = State(initialValue: startingDay)
    }

    private var currentDay: DayPayload? {
        guard selectedDayIndex < tripPayload.days.count else { return nil }
        return tripPayload.days[selectedDayIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Day selector
                dayPicker

                if let day = currentDay {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Day map
                            DayMapView(stops: day.stops, height: 200)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)

                            // Day info bar
                            dayInfoBar(day)

                            // Stops in execution order
                            ForEach(day.stops, id: \.id) { stop in
                                ExecutionStopCard(
                                    stop: stop,
                                    tripId: storedTrip.tripId,
                                    region: tripPayload.primaryDestination ?? "",
                                    visitDate: day.date ?? tripPayload.startDate ?? ""
                                )
                            }

                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationTitle("Day \(selectedDayIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Day Picker

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(tripPayload.days.enumerated()), id: \.element.id) { index, day in
                    Button {
                        withAnimation { selectedDayIndex = index }
                    } label: {
                        VStack(spacing: 2) {
                            Text("Day \(day.dayNumber)")
                                .font(.caption.bold())
                            if let date = day.date {
                                Text(shortDate(date))
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedDayIndex == index
                                ? Color.green
                                : Color(.systemGray5)
                        )
                        .foregroundStyle(selectedDayIndex == index ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Day Info Bar

    private func dayInfoBar(_ day: DayPayload) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(day.title)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(day.stops.count) stops", systemImage: "mappin.circle.fill")
                if let driving = day.estimatedDrivingMinutes {
                    Label("\(driving) min drive", systemImage: "car.fill")
                }
                if let dist = day.plannedDistanceMiles {
                    Label("\(Int(dist)) mi", systemImage: "road.lanes")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    private func shortDate(_ dateStr: String) -> String {
        // "2026-07-28" -> "Jul 28"
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3, let month = Int(parts[1]), let day = Int(parts[2]) else {
            return dateStr
        }
        let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        guard month > 0, month < months.count else { return dateStr }
        return "\(months[month]) \(day)"
    }
}
