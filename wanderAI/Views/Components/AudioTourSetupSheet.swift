import SwiftUI

/// Sheet for configuring audio tour duration and personas before submission.
/// Supports all 6 WanderAI personas as narrators.
struct AudioTourSetupSheet: View {
    let destinationName: String
    let onSubmit: (Int, [String]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var durationMinutes: Double = 8
    @State private var selectedPersonaIds: Set<String> = ["historian"]
    @State private var showValidationError = false

    private var isValid: Bool {
        !selectedPersonaIds.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Audio Tour")
                            .font(.title2.bold())
                        Text(destinationName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Duration
                    durationSection

                    // Personas
                    personasSection

                    // Validation error
                    if showValidationError {
                        Text("Select at least one persona.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // Submit
                    Button {
                        if isValid {
                            onSubmit(Int(durationMinutes), Array(selectedPersonaIds))
                        } else {
                            showValidationError = true
                        }
                    } label: {
                        Text("Generate Audio Tour")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.headline)

            Text("\(Int(durationMinutes)) minutes")
                .font(.title3.bold())
                .foregroundStyle(.green)

            Slider(
                value: $durationMinutes,
                in: 3...20,
                step: 1
            )
            .tint(.green)

            HStack {
                Text("3 min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("20 min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Personas

    private var personasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Narrators")
                .font(.headline)

            Text("Choose who narrates your tour. Select multiple for a richer experience.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(allPersonaOptions, id: \.id) { persona in
                personaToggle(persona: persona)
            }
        }
        .onChange(of: selectedPersonaIds) { _, _ in showValidationError = false }
    }

    private func personaToggle(persona: AudioTourPersonaOption) -> some View {
        let isSelected = selectedPersonaIds.contains(persona.id)

        return Button {
            if isSelected {
                selectedPersonaIds.remove(persona.id)
            } else {
                selectedPersonaIds.insert(persona.id)
            }
        } label: {
            HStack(spacing: 14) {
                Text(persona.emoji)
                    .font(.title2)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(persona.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(persona.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .green : .secondary.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Persona Data

    private var allPersonaOptions: [AudioTourPersonaOption] {
        [
            AudioTourPersonaOption(
                id: "historian",
                displayName: "Prof. Raj the Historian",
                emoji: "📜",
                subtitle: "Deep historical context, dramatic storytelling"
            ),
            AudioTourPersonaOption(
                id: "photographer",
                displayName: "Maya the Photographer",
                emoji: "📸",
                subtitle: "Visual insights, composition tips, best light"
            ),
            AudioTourPersonaOption(
                id: "geologist",
                displayName: "Dr. Sam the Geologist",
                emoji: "🪨",
                subtitle: "Geological formations, landscape science"
            ),
            AudioTourPersonaOption(
                id: "foodie",
                displayName: "Priya the Foodie",
                emoji: "🍜",
                subtitle: "Local food scene, restaurants, markets"
            ),
            AudioTourPersonaOption(
                id: "planner",
                displayName: "Alex the Planner",
                emoji: "🗺️",
                subtitle: "Logistics, timing, practical tips"
            ),
            AudioTourPersonaOption(
                id: "storyteller",
                displayName: "Ghost the Storyteller",
                emoji: "🌙",
                subtitle: "Local legends, myths, atmospheric narratives"
            ),
        ]
    }
}

// MARK: - Supporting Type

private struct AudioTourPersonaOption: Identifiable {
    let id: String
    let displayName: String
    let emoji: String
    let subtitle: String
}
