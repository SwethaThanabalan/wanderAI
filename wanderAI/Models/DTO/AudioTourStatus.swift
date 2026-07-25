import Foundation

/// Maps backend job statuses to user-friendly labels.
enum AudioTourStatus: String, CaseIterable {
    case queued
    case researching
    case verifying
    case scripting
    case generatingAudio = "generating_audio"
    case completed
    case failed

    /// Human-readable label for display.
    var friendlyLabel: String {
        switch self {
        case .queued: return "Waiting to begin"
        case .researching: return "Researching destination"
        case .verifying: return "Checking facts"
        case .scripting: return "Creating audio tour"
        case .generatingAudio: return "Generating audio"
        case .completed: return "Audio tour ready"
        case .failed: return "Generation failed"
        }
    }

    /// Whether the job is still in progress (not terminal).
    var isProcessing: Bool {
        switch self {
        case .queued, .researching, .verifying, .scripting, .generatingAudio:
            return true
        case .completed, .failed:
            return false
        }
    }

    /// Whether a duplicate submission should be blocked.
    var blocksDuplicate: Bool {
        switch self {
        case .queued, .researching, .verifying, .scripting, .generatingAudio, .completed:
            return true
        case .failed:
            return false
        }
    }
}
