import SwiftUI

/// Sheet for configuring audio tour duration and personas before submission.
struct AudioTourSetupSheet: View {
    let destinationName: String
    let onSubmit: (Int, [String]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var durationMinutes: Double = 8
    @State private var historianSelected = true
    @State private var photographerSelected = false
    @State private var showValidationError = false

    private var selectedPersonas: [String] {
        var personas: [String] = []
        if historianSelected { personas.append("historian") }
        if photographerSelected { personas.append("photographer") }
        return personas
    }

    private var isValid: Bool {
        !selectedPersonas.isEmpty
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
                            onSubmit(Int(durationMinutes), selectedPersonas)
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
        .presentationDetents([.medium])
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
            Text("Personas")
                .font(.headline)

            Text("Choose who narrates your tour.")
                .font(.caption)
                .foregroundStyle(.secondary)

            personaToggle(
                title: "Historian",
                subtitle: "Deep historical context and stories",
                icon: "book.fill",
                isSelected: $historianSelected
            )

            personaToggle(
                title: "Photographer",
                subtitle: "Visual insights and composition tips",
                icon: "camera.fill",
                isSelected: $photographerSelected
            )
        }
        .onChange(of: historianSelected) { _, _ in showValidationError = false }
        .onChange(of: photographerSelected) { _, _ in showValidationError = false }
    }

    private func personaToggle(title: String, subtitle: String, icon: String, isSelected: Binding<Bool>) -> some View {
        Button {
            isSelected.wrappedValue.toggle()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 36)
                    .foregroundStyle(isSelected.wrappedValue ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected.wrappedValue ? .green : .secondary.opacity(0.5))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected.wrappedValue ? Color.green.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected.wrappedValue ? Color.green.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
