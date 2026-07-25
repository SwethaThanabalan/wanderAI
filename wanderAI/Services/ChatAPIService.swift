import Foundation

/// Handles chat API communication with the WanderAI backend.
/// Uses session-based endpoints — server maintains all conversation context.
/// Base URL: https://wanderai-backend-hf03.onrender.com
final class ChatAPIService {
    private let baseURL = "https://wanderai-backend-hf03.onrender.com"
    private let urlSession: URLSession

    init(session: URLSession = .shared) {
        self.urlSession = session
    }

    /// Fetches available chat personas.
    /// GET /v1/chat/personas
    func fetchPersonas() async throws -> [ChatPersona] {
        guard let url = URL(string: "\(baseURL)/v1/chat/personas") else {
            throw ChatError.invalidURL
        }

        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ChatError.serverError("Failed to fetch personas")
        }

        if let parsed = try? JSONDecoder().decode(PersonasResponse.self, from: data) {
            return parsed.personas
        }
        if let personas = try? JSONDecoder().decode([ChatPersona].self, from: data) {
            return personas
        }
        throw ChatError.decodingError
    }

    // MARK: - Session-Based Chat

    /// Creates a new chat session with selected personas and trip context.
    /// POST /v1/chat/sessions
    func createSession(request: CreateSessionRequest) async throws -> CreateSessionResponse {
        guard let url = URL(string: "\(baseURL)/v1/chat/sessions") else {
            throw ChatError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await urlSession.data(for: urlRequest)
        try validateResponse(response, data: data)
        return try JSONDecoder().decode(CreateSessionResponse.self, from: data)
    }

    /// Sends a message within an existing session. Server maintains all context.
    /// POST /v1/chat/sessions/{sessionId}/message
    func sendSessionMessage(sessionId: String, message: String) async throws -> SessionMessageResponse {
        guard let url = URL(string: "\(baseURL)/v1/chat/sessions/\(sessionId)/message") else {
            throw ChatError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 90

        let body = SessionMessageRequest(message: message)
        urlRequest.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: urlRequest)
        try validateResponse(response, data: data)
        return try JSONDecoder().decode(SessionMessageResponse.self, from: data)
    }

    /// Accepts a suggestion, updating the session's trip context on the server.
    /// POST /v1/chat/sessions/{sessionId}/accept
    func acceptStop(sessionId: String, request: AcceptStopRequest) async throws {
        guard let url = URL(string: "\(baseURL)/v1/chat/sessions/\(sessionId)/accept") else {
            throw ChatError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 15

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await urlSession.data(for: urlRequest)
        try validateResponse(response, data: data)
    }

    /// Builds the final trip JSON from all accepted stops in the session.
    /// POST /v1/chat/sessions/{sessionId}/build-trip
    func buildTrip(sessionId: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/v1/chat/sessions/\(sessionId)/build-trip") else {
            throw ChatError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30

        let (data, response) = try await urlSession.data(for: urlRequest)
        try validateResponse(response, data: data)
        return data
    }

    // MARK: - Legacy (fallback if session creation fails)

    /// Sends a stateless chat message. Used as fallback.
    /// POST /v1/chat
    func sendMessage(request: ChatRequest) async throws -> ChatResponse {
        guard let url = URL(string: "\(baseURL)/v1/chat") else {
            throw ChatError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await urlSession.data(for: urlRequest)
        try validateResponse(response, data: data)
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    /// Sends a multi-persona group chat message (stateless fallback).
    /// POST /v1/chat/multi
    func sendMultiChat(request: MultiChatRequest) async throws -> MultiChatResponse {
        guard let url = URL(string: "\(baseURL)/v1/chat/multi") else {
            throw ChatError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 90

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await urlSession.data(for: urlRequest)
        try validateResponse(response, data: data)
        return try JSONDecoder().decode(MultiChatResponse.self, from: data)
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.serverError("No HTTP response")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw ChatError.serverError("Status \(httpResponse.statusCode): \(body)")
        }
    }

    // MARK: - Errors

    enum ChatError: LocalizedError {
        case invalidURL
        case serverError(String)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .serverError(let detail): return detail
            case .decodingError: return "Failed to parse response"
            }
        }
    }
}
