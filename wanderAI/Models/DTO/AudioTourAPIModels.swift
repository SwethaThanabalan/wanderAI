import Foundation
import CommonCrypto

// MARK: - Request

struct AudioTourJobRequest: Encodable {
    let tripId: String
    let stopId: String
    let destinationName: String
    let region: String
    let visitDate: String
    let episodeMinutes: Int
    let personas: [String]

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case stopId = "stop_id"
        case destinationName = "destination_name"
        case region
        case visitDate = "visit_date"
        case episodeMinutes = "episode_minutes"
        case personas
    }
}

// MARK: - Responses

struct AudioTourJobResponse: Decodable {
    let jobId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
    }
}

struct AudioTourStatusResponse: Decodable {
    let jobId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
    }
}

// MARK: - Errors

enum AudioTourError: LocalizedError {
    case invalidID
    case networkError(String)
    case invalidResponse
    case downloadFailed(String)
    case fileSystemError(String)

    var errorDescription: String? {
        switch self {
        case .invalidID:
            return "Trip or stop ID is missing."
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .downloadFailed(let detail):
            return "Download failed: \(detail)"
        case .fileSystemError(let detail):
            return "File system error: \(detail)"
        }
    }
}

// MARK: - Deterministic UUID

/// Converts any string ID into a valid UUID using UUID v5 (SHA-1 name-based).
/// If the string is already a valid UUID, it is returned as-is.
/// Otherwise, a deterministic UUID is generated from the string using a fixed namespace.
enum DeterministicUUID {
    /// Fixed namespace UUID for wanderAI ID hashing.
    private static let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")! // URL namespace

    /// Returns a valid UUID string for any input string.
    static func from(_ input: String) -> String {
        // If already a valid UUID, return it directly
        if UUID(uuidString: input) != nil {
            return input
        }

        // Generate UUID v5 from the input string
        let namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        let nameBytes = Array(input.utf8)

        var data = namespaceBytes + nameBytes

        // SHA-1 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1(&data, CC_LONG(data.count), &hash)

        // Set version (5) and variant bits
        hash[6] = (hash[6] & 0x0F) | 0x50  // Version 5
        hash[8] = (hash[8] & 0x3F) | 0x80  // Variant 10

        // Format as UUID string
        let uuid = String(format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                          hash[0], hash[1], hash[2], hash[3],
                          hash[4], hash[5],
                          hash[6], hash[7],
                          hash[8], hash[9],
                          hash[10], hash[11], hash[12], hash[13], hash[14], hash[15])
        return uuid
    }
}
