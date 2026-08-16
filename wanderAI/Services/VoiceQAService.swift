import Foundation
import AVFoundation

/// Handles the voice Q&A flow: record user question → send to backend → play spoken answer.
/// Pauses the audio tour during the interaction, resumes after.
@MainActor
@Observable
final class VoiceQAService {
    enum State: Equatable {
        case idle
        case recording
        case processing
        case playingAnswer
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var transcription: String?
    private(set) var answerText: String?

    private let baseURL = "https://wanderai-backend-hf03.onrender.com"
    private var audioRecorder: AVAudioRecorder?
    private var answerPlayer: AVAudioPlayer?
    private var recordingURL: URL?

    // MARK: - Recording

    /// Starts recording the user's voice question.
    func startRecording() {
        state = .recording
        transcription = nil
        answerText = nil

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error("Microphone access failed")
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice_qa_\(UUID().uuidString.prefix(8)).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.record()
        } catch {
            state = .error("Could not start recording")
        }
    }

    /// Stops recording and sends the question to the backend.
    func stopRecordingAndAsk(
        persona: String?,
        destination: String?,
        tripName: String?,
        state stateRegion: String?,
        currentStop: String?
    ) async {
        audioRecorder?.stop()
        audioRecorder = nil

        guard let url = recordingURL, let audioData = try? Data(contentsOf: url) else {
            state = .error("No recording captured")
            return
        }

        // Clean up temp file
        try? FileManager.default.removeItem(at: url)

        state = .processing

        do {
            let result = try await sendVoiceQuestion(
                audioData: audioData,
                persona: persona,
                destination: destination,
                tripName: tripName,
                state: stateRegion,
                currentStop: currentStop
            )

            transcription = result.transcription
            answerText = result.answerText

            // Play the spoken answer
            state = .playingAnswer
            try playAnswerAudio(data: result.audioData)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// Cancels the current recording without sending.
    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        state = .idle
    }

    /// Stops answer playback and returns to idle.
    func dismiss() {
        answerPlayer?.stop()
        answerPlayer = nil
        state = .idle
    }

    // MARK: - Network

    private struct VoiceQAResult {
        let audioData: Data
        let transcription: String?
        let answerText: String?
    }

    private func sendVoiceQuestion(
        audioData: Data,
        persona: String?,
        destination: String?,
        tripName: String?,
        state: String?,
        currentStop: String?
    ) async throws -> VoiceQAResult {
        var components = URLComponents(string: "\(baseURL)/v1/voice-qa")!
        var queryItems: [URLQueryItem] = []

        if let persona { queryItems.append(URLQueryItem(name: "persona", value: persona)) }
        if let destination { queryItems.append(URLQueryItem(name: "destination", value: destination)) }
        if let tripName { queryItems.append(URLQueryItem(name: "trip_name", value: tripName)) }
        if let state { queryItems.append(URLQueryItem(name: "state", value: state)) }
        if let currentStop { queryItems.append(URLQueryItem(name: "current_stop", value: currentStop)) }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw VoiceQAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("audio/m4a", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw VoiceQAError.serverError("Status \(statusCode)")
        }

        let transcription = httpResponse.value(forHTTPHeaderField: "X-Transcription")
        let answerText = httpResponse.value(forHTTPHeaderField: "X-Answer-Text")

        return VoiceQAResult(audioData: data, transcription: transcription, answerText: answerText)
    }

    // MARK: - Playback

    private func playAnswerAudio(data: Data) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        answerPlayer = try AVAudioPlayer(data: data)
        answerPlayer?.delegate = AnswerPlaybackDelegate { [weak self] in
            Task { @MainActor in
                self?.state = .idle
            }
        }
        answerPlayer?.play()
    }

    // MARK: - Errors

    enum VoiceQAError: LocalizedError {
        case invalidURL
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid request URL"
            case .serverError(let detail): return detail
            }
        }
    }
}

// MARK: - Playback Delegate

private class AnswerPlaybackDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
