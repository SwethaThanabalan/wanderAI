import SwiftUI
import MapKit

/// Displays a map with annotated stops and a route polyline for a single day.
struct DayMapView: View {
    let stops: [StopPayload]
    let height: CGFloat

    @State private var position: MapCameraPosition = .automatic

    private var validStops: [StopPayload] {
        stops.filter { $0.mapReference.latitude != 0 && $0.mapReference.longitude != 0 }
    }

    private var coordinates: [CLLocationCoordinate2D] {
        validStops.map {
            CLLocationCoordinate2D(latitude: $0.mapReference.latitude, longitude: $0.mapReference.longitude)
        }
    }

    var body: some View {
        if validStops.isEmpty {
            EmptyView()
        } else {
            Map(position: $position) {
                // Route polyline
                if coordinates.count >= 2 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(.green, lineWidth: 3)
                }

                // Stop annotations
                ForEach(validStops, id: \.id) { stop in
                    Annotation(
                        stop.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: stop.mapReference.latitude,
                            longitude: stop.mapReference.longitude
                        )
                    ) {
                        ZStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 28, height: 28)
                            Text("\(stop.sequence)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .allowsHitTesting(false)
        }
    }
}
