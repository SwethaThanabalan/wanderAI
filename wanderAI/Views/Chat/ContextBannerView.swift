import SwiftUI

/// Compact banner showing the active destination and trip context.
/// Displayed below the navigation title and above the conversation.
/// Tapping opens a context-change action (future: destination picker).
struct ContextBannerView: View {
    let destination: String?
    let currentStop: String?
    let tripName: String?
    let contextStatus: AIContextStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 1) {
                    if let stop = currentStop {
                        Text(stop)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if let dest = destination {
                            Text(dest)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else if let dest = destination {
                        Text(dest)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if let trip = tripName {
                            Text(trip)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text(noContextLabel)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if contextStatus == .noTrip {
                    Text("Choose trip")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(bannerBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Tap to change destination context")
    }

    // MARK: - Computed

    private var statusIcon: String {
        switch contextStatus {
        case .active: return "mappin.circle.fill"
        case .stale: return "exclamationmark.triangle.fill"
        case .noTrip: return "mappin.slash"
        }
    }

    private var statusColor: Color {
        switch contextStatus {
        case .active: return .green
        case .stale: return .orange
        case .noTrip: return .secondary
        }
    }

    private var bannerBackground: some ShapeStyle {
        switch contextStatus {
        case .active: return Color.green.opacity(0.06)
        case .stale: return Color.orange.opacity(0.06)
        case .noTrip: return Color(.systemGray6)
        }
    }

    private var noContextLabel: String {
        "No trip selected"
    }

    private var accessibilityText: String {
        if let stop = currentStop, let dest = destination {
            return "Currently at \(stop) in \(dest)"
        } else if let dest = destination {
            return "Active destination: \(dest)"
        } else {
            return "No trip selected"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ContextBannerView(
            destination: "North Cascades National Park, WA",
            currentStop: nil,
            tripName: "Washington Adventure",
            contextStatus: .active,
            onTap: {}
        )
        Divider()
        ContextBannerView(
            destination: "North Cascades National Park, WA",
            currentStop: "Maple Pass Loop",
            tripName: "Washington Adventure",
            contextStatus: .active,
            onTap: {}
        )
        Divider()
        ContextBannerView(
            destination: nil,
            currentStop: nil,
            tripName: nil,
            contextStatus: .noTrip,
            onTap: {}
        )
        Divider()
        ContextBannerView(
            destination: "Deleted Trip",
            currentStop: nil,
            tripName: nil,
            contextStatus: .stale,
            onTap: {}
        )
    }
}
