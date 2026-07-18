import Foundation

/// Provides access to the bundled sample trip JSON.
enum SampleTripService {
    /// Returns the raw data of the bundled sample trip.
    static func loadSampleData() -> Data? {
        guard let url = Bundle.main.url(forResource: "sample_trip", withExtension: "json") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}
