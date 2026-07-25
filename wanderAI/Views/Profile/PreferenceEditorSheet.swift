import SwiftUI
import SwiftData

/// Sheet for editing travel preferences.
struct PreferenceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let currentPreferences: PreferencePayload?
    let onSave: (PreferencePayload) -> Void

    // Travel style
    @State private var pace: String = "balanced"
    @State private var maxActivities: Double = 5
    @State private var startTime: String = "08:00"
    @State private var endTime: String = "21:00"

    // Group
    @State private var adultCount: Double = 2
    @State private var childCount: Double = 0
    @State private var travelsWithPets = false

    // Food
    @State private var dietaryRestrictions: String = ""
    @State private var preferredCuisines: String = ""
    @State private var avoidedFoods: String = ""

    // Driving
    @State private var maxDriving: Double = 240
    @State private var scenicRoutes = true
    @State private var avoidTolls = false

    // Interests
    @State private var selectedInterests: Set<String> = []

    private let paceOptions = ["relaxed", "balanced", "active", "intensive"]
    private let interestOptions = [
        "Nature", "History", "Food", "Photography", "Art",
        "Architecture", "Wildlife", "Beaches", "Mountains", "Markets"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Travel Style
                Section("Travel Style") {
                    Picker("Pace", selection: $pace) {
                        ForEach(paceOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Max activities per day: \(Int(maxActivities))")
                            .font(.subheadline)
                        Slider(value: $maxActivities, in: 2...10, step: 1)
                            .tint(.green)
                    }

                    HStack {
                        Text("Start time")
                        Spacer()
                        TextField("08:00", text: $startTime)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("End time")
                        Spacer()
                        TextField("21:00", text: $endTime)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Travel Group
                Section("Travel Group") {
                    VStack(alignment: .leading) {
                        Text("Adults: \(Int(adultCount))")
                            .font(.subheadline)
                        Slider(value: $adultCount, in: 1...6, step: 1)
                            .tint(.green)
                    }

                    VStack(alignment: .leading) {
                        Text("Children: \(Int(childCount))")
                            .font(.subheadline)
                        Slider(value: $childCount, in: 0...5, step: 1)
                            .tint(.green)
                    }

                    Toggle("Travels with pets", isOn: $travelsWithPets)
                }

                // Food
                Section("Food & Dietary") {
                    TextField("Dietary restrictions (comma-separated)", text: $dietaryRestrictions)
                    TextField("Preferred cuisines", text: $preferredCuisines)
                    TextField("Foods to avoid", text: $avoidedFoods)
                }

                // Driving
                Section("Driving") {
                    VStack(alignment: .leading) {
                        Text("Max driving: \(Int(maxDriving)) min/day")
                            .font(.subheadline)
                        Slider(value: $maxDriving, in: 60...480, step: 30)
                            .tint(.green)
                    }

                    Toggle("Prefer scenic routes", isOn: $scenicRoutes)
                    Toggle("Avoid tolls", isOn: $avoidTolls)
                }

                // Interests
                Section("Interests") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                        ForEach(interestOptions, id: \.self) { interest in
                            Button {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            } label: {
                                Text(interest)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        selectedInterests.contains(interest)
                                            ? Color.green
                                            : Color(.systemGray5)
                                    )
                                    .foregroundStyle(selectedInterests.contains(interest) ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Actions

    private func loadExisting() {
        guard let prefs = currentPreferences else { return }

        if let style = prefs.travelStyle {
            pace = style.pace ?? "balanced"
            maxActivities = Double(style.maximumActivitiesPerDay ?? 5)
            startTime = style.preferredDailyStartTime ?? "08:00"
            endTime = style.preferredDailyEndTime ?? "21:00"
        }

        if let comp = prefs.travelerComposition {
            adultCount = Double(comp.adultCount ?? 2)
            childCount = Double(comp.childCount ?? 0)
            travelsWithPets = comp.travelsWithPets ?? false
        }

        if let food = prefs.foodPreferences {
            dietaryRestrictions = food.dietaryRestrictions?.joined(separator: ", ") ?? ""
            preferredCuisines = food.preferredCuisines?.joined(separator: ", ") ?? ""
            avoidedFoods = food.avoidedFoods?.joined(separator: ", ") ?? ""
        }

        if let driving = prefs.drivingPreferences {
            maxDriving = Double(driving.maximumDrivingMinutesPerDay ?? 240)
            scenicRoutes = driving.scenicRoutesPreferred ?? true
            avoidTolls = driving.avoidTolls ?? false
        }

        if let interests = prefs.interests {
            selectedInterests = Set(interests.map(\.name))
        }
    }

    private func saveAndDismiss() {
        let payload = PreferencePayload(
            travelerComposition: TravelerComposition(
                defaultGroupType: nil,
                adultCount: Int(adultCount),
                childCount: Int(childCount),
                olderAdultCount: nil,
                travelsWithPets: travelsWithPets
            ),
            travelStyle: TravelStylePrefs(
                pace: pace,
                spontaneity: nil,
                preferredDailyStartTime: startTime,
                preferredDailyEndTime: endTime,
                maximumActivitiesPerDay: Int(maxActivities)
            ),
            interests: selectedInterests.map { InterestItem(name: $0, priority: nil) },
            accessibility: nil,
            petPreferences: travelsWithPets ? PetPrefs(
                travelingWithDog: true,
                dogSize: nil,
                leashFriendlyLocationsAccepted: true,
                dogFriendlyTrailsPreferred: true,
                dogParksPreferred: nil,
                petFriendlyDiningPreferred: true,
                avoidPetRestrictedStops: nil
            ) : nil,
            kidPreferences: Int(childCount) > 0 ? KidPrefs(
                travelingWithChildren: true,
                childAgeRanges: nil,
                strollerAccessRequired: nil,
                playgroundsPreferred: nil,
                familyRestroomsPreferred: nil,
                napFriendlySchedule: nil
            ) : nil,
            olderAdultPreferences: nil,
            foodPreferences: FoodPrefs(
                dietaryRestrictions: splitList(dietaryRestrictions),
                preferredCuisines: splitList(preferredCuisines),
                avoidedFoods: splitList(avoidedFoods),
                diningStyle: nil,
                localCoffeePreferred: nil
            ),
            drivingPreferences: DrivingPrefs(
                maximumDrivingMinutesPerDay: Int(maxDriving),
                scenicRoutesPreferred: scenicRoutes,
                avoidTolls: avoidTolls,
                avoidFerries: nil,
                avoidUnpavedRoads: nil,
                comfortableWithMountainRoads: nil,
                frequentDrivingBreaks: nil
            ),
            accommodationPreferences: nil,
            destinationPreferences: nil,
            avoidances: nil,
            notesForPlanner: nil
        )

        let service = AppContainer.preferenceService(context: modelContext)
        try? service.savePreferences(payload)
        onSave(payload)
        dismiss()
    }

    private func splitList(_ text: String) -> [String]? {
        let items = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return items.isEmpty ? nil : items
    }
}
