import SwiftUI

/// Resizable bottom sheet overlaying the map.
/// Collapsed: Trip name + day + progress
/// Medium: Today's stops + Start Adventure
/// Expanded: Full trip overview
struct TripBottomSheet: View {
    var viewModel: TripMapViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header — always visible
                headerSection

                // Progress
                progressSection

                // Current day stops
                stopsSection

                // Start Adventure / Resume
                actionButton

                // Route Highlights
                highlightsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.tripName)
                .font(.title3.bold())

            if let day = viewModel.selectedDay {
                Text("Day \(day.dayNumber): \(day.title)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.completedStops)/\(viewModel.totalStops) stops")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: viewModel.progress)
                .tint(.green)
        }
    }

    // MARK: - Stops

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Stops")
                .font(.headline)

            if let day = viewModel.selectedDay {
                ForEach(day.stops, id: \.id) { stop in
                    stopRow(stop)
                }
            }
        }
    }

    private func stopRow(_ stop: StopPayload) -> some View {
        let status = viewModel.stopStatus(for: stop.id)

        return HStack(spacing: 14) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor(status))
                    .frame(width: 36, height: 36)

                if status == "completed" {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Text("\(stop.sequence)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(stop.name)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(status == "skipped")

                HStack(spacing: 6) {
                    if let time = stop.plannedTime {
                        Text(time)
                    }
                    if let duration = stop.estimatedDurationMinutes {
                        Text("• \(duration) min")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if status == "current" {
                Text("Now")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "completed": return .gray
        case "current": return .blue
        case "skipped": return .red.opacity(0.5)
        default: return .green.opacity(0.8)
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            viewModel.startOrResumeTrip()
        } label: {
            Text(viewModel.actionButtonLabel)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    // MARK: - Route Highlights

    private var highlightsSection: some View {
        Group {
            if let highlights = viewModel.selectedDay?.routeHighlights, !highlights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Route Discoveries")
                        .font(.headline)

                    ForEach(highlights, id: \.id) { highlight in
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(.orange)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(highlight.name)
                                    .font(.subheadline.weight(.medium))
                                if let detour = highlight.estimatedDetourMinutes {
                                    Text("+\(detour) min detour")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
