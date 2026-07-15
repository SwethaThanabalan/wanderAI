# wanderAI Implementation Plan

**Version:** 0.1.0  
**Status:** Alpha — P0  
**Platform:** iOS 17+  
**Primary Source of Truth:** `PRODUCT_SPEC.md`

---

## 1. Purpose

This document defines the implementation sequence for the wanderAI P0 Alpha.

The goal is to build and validate the core trip-execution experience using:

- A bundled sample trip
- JSON-based trip import
- Local trip storage
- Informational map references
- Multi-day itinerary execution
- Destination and trip reviews
- Preference export

This plan is intentionally limited to P0.

It must not introduce P1 or later integrations such as:

- Built-in LLM functionality
- Turn-by-turn navigation
- Live GPS tracking
- Offline route calculation
- Audio tours
- User accounts
- Cloud synchronization
- Live community features

---

# 2. P0 Delivery Objective

P0 is complete when a user can:

1. Launch wanderAI.
2. Load or import a trip.
3. View the trip and daily itinerary.
4. See all destinations and route highlights on a contextual map.
5. Start Trip Execution Mode.
6. Complete, skip, and move stops.
7. Resume their progress later.
8. Review destinations and the overall trip.
9. Export travel preferences as JSON.
10. Use the core trip experience without an account or active internet connection.

---

# 3. Development Principles

During implementation:

- Build the smallest complete version of each experience.
- Keep the application runnable after every milestone.
- Avoid introducing future dependencies early.
- Use reusable SwiftUI components.
- Keep business logic outside SwiftUI views.
- Store imported trip data separately from mutable execution state.
- Validate all JSON before persistence.
- Use the bundled sample trip through the same import pipeline as external JSON.
- Do not hardcode trip content directly inside views.
- Treat `PRODUCT_SPEC.md` and `P0_SCOPE.md` as binding scope documents.

---

# 4. Technical Baseline

## Platform

- iOS 17+
- Swift
- SwiftUI

## Architecture

- MVVM
- Repository and service boundaries where useful
- Dependency injection
- `NavigationStack`

## Persistence

- SwiftData for:
  - Trips
  - Trip execution state
  - Reviews
  - Preferences
  - Helpful-vote state
  - Earned stickers

## Serialization

- `Codable`
- `JSONDecoder`
- `JSONEncoder`

## System Frameworks

- SwiftUI
- SwiftData
- MapKit for P0 map presentation
- Uniform Type Identifiers
- File importer and exporter APIs
- Native share sheet

## Explicitly Excluded Dependencies

Do not add:

- Mapbox
- Google Maps SDK
- LLM SDKs
- Firebase
- Supabase
- Authentication SDKs
- Analytics SDKs
- Networking libraries

---

# 5. Recommended Project Structure

```text
wanderAI/
├── App/
│   ├── WanderAIApp.swift
│   ├── AppContainer.swift
│   └── AppRouter.swift
│
├── Models/
│   ├── Domain/
│   │   ├── Trip.swift
│   │   ├── TripDay.swift
│   │   ├── TripStop.swift
│   │   ├── RouteHighlight.swift
│   │   ├── MapReference.swift
│   │   ├── Suitability.swift
│   │   ├── PracticalInformation.swift
│   │   ├── ImportedReview.swift
│   │   └── TravelerTip.swift
│   │
│   ├── Persistence/
│   │   ├── StoredTrip.swift
│   │   ├── TripExecutionState.swift
│   │   ├── StopExecutionState.swift
│   │   ├── LocalDestinationReview.swift
│   │   ├── LocalTripReview.swift
│   │   └── StoredPreferences.swift
│   │
│   └── DTO/
│       ├── TripImportDocument.swift
│       ├── PreferenceExportDocument.swift
│       └── ImportMetadata.swift
│
├── Views/
│   ├── Home/
│   ├── TripOverview/
│   ├── TripExecution/
│   ├── DestinationDetails/
│   ├── Reviews/
│   ├── Preferences/
│   ├── Completion/
│   └── SharedComponents/
│
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── TripOverviewViewModel.swift
│   ├── TripExecutionViewModel.swift
│   ├── DestinationDetailsViewModel.swift
│   ├── ReviewViewModel.swift
│   └── PreferencesViewModel.swift
│
├── Services/
│   ├── TripImportService.swift
│   ├── TripRepository.swift
│   ├── TripExecutionService.swift
│   ├── ReviewRepository.swift
│   ├── PreferenceService.swift
│   ├── ShareService.swift
│   └── SampleTripService.swift
│
├── Resources/
│   ├── sample-trip.json
│   ├── sample-preferences.json
│   └── LocalImages/
│
└── Assets.xcassets/
