import Foundation

/// Handles audio tour backend API communication.
/// Base URL: https://wanderai-backend-hf03.onrender.com
final class AudioTourAPIService {
    private let baseURL = "https://wanderai-backend-hf03.onrender.com"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Submits a new podcast generation job.
    /// POST /v1/podcast-jobs
    func submitJob(request: AudioTourJobRequest) async throws -> AudioTourJobResponse {
        guard let url = URL(string: "\(baseURL)/v1/podcast-jobs") else {
            throw AudioTourError.networkError("Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AudioTourError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw AudioTourError.networkError("Status \(httpResponse.statusCode): \(body)")
        }

        let decoded = try JSONDecoder().decode(AudioTourJobResponse.self, from: data)
        return decoded
    }

    /// Checks current status of a job.
    /// GET /v1/podcast-jobs/{jobId}
    func checkStatus(jobId: String) async throws -> AudioTourStatusResponse {
        guard let url = URL(string: "\(baseURL)/v1/podcast-jobs/\(jobId)") else {
            throw AudioTourError.networkError("Invalid URL")
        }

        let urlRequest = URLRequest(url: url)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AudioTourError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw AudioTourError.networkError("Status \(httpResponse.statusCode): \(body)")
        }

        let decoded = try JSONDecoder().decode(AudioTourStatusResponse.self, from: data)
        return decoded
    }

    /// Returns the audio download URL for a completed job.
    func audioURL(for jobId: String) -> URL? {
        URL(string: "\(baseURL)/v1/episodes/\(jobId)/audio")
    }
}
