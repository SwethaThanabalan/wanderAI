# Architecture

**Project:** wanderAI

**Version:** 0.1.0

**Status:** Alpha (P0)

---

# Purpose

This document defines the technical architecture for wanderAI.

The goal is to build a maintainable, scalable, and modular iOS application while limiting implementation to the Alpha (P0) scope.

Future integrations such as AI, navigation, offline routing, and cloud synchronization should be designed as extension points rather than implemented today.

This document should be used together with:

- PRODUCT_SPEC.md
- P0_SCOPE.md
- DATA_MODEL.md
- JSON_CONTRACTS.md

If there is a conflict, **PRODUCT_SPEC.md is the source of truth.**

---

# Architectural Principles

The architecture should prioritize:

- Simplicity
- Maintainability
- Scalability
- Testability
- Native iOS development
- Separation of concerns

The project should avoid premature optimization while remaining extensible for future releases.

---

# Technology Stack

## Platform

- iOS 17+
- Swift 6
- SwiftUI

## Architecture Pattern

MVVM

Each screen should consist of:

- View
- ViewModel
- Model

Business logic should never live inside SwiftUI Views.

---

## Persistence

SwiftData

Stores:

- Imported Trips
- User Reviews
- Trip Progress
- Preferences

No cloud synchronization in P0.

---

## JSON

Codable

All imported trips and exported preferences use Codable models.

The JSON contract is documented in:

JSON_CONTRACTS.md

---

## Images

Local Assets

Sample images may be bundled inside the application during development.

Future versions may support remote image loading.

---

## Maps

P0

Map previews only.

Maps should display:

- destination pins
- route overview
- highlighted locations

Maps are informational.

No live navigation.

No GPS.

---

# Project Structure

```
wanderAI/
│
├── App/
│
├── Models/
│
├── Views/
│
├── ViewModels/
│
├── Services/
│
├── Resources/
│
├── Assets.xcassets/
│
└── Supporting Files/
```

---

# Folder Responsibilities

## App

Application entry point.

Contains:

- App.swift
- Dependency registration
- Navigation setup

---

## Models

Contains all domain models.

Examples:

- Trip
- Day
- Destination
- RouteHighlight
- Review
- Preferences

Models should remain independent from SwiftUI.

---

## Views

Contains SwiftUI screens.

Views should only:

- display UI
- observe ViewModels
- send user actions

Views should not contain business logic.

---

## ViewModels

Responsible for:

- screen state
- user actions
- presentation logic
- communication with Services

---

## Services

Encapsulate business logic.

Examples:

TripService

ReviewService

PreferenceService

ImportService

ExportService

Future services:

NavigationService

AudioService

AIService

WeatherService

---

## Resources

Contains:

- sample JSON
- local images
- bundled assets

---

# Data Flow

```
JSON

↓

Import Service

↓

Trip Model

↓

SwiftData

↓

ViewModel

↓

SwiftUI View
```

Views should never read JSON directly.

---

# Navigation

P0 uses standard SwiftUI NavigationStack.

```
Home

↓

Trip Overview

↓

Trip Execution

↓

Destination Details

↓

Review
```

Navigation should remain simple.

---

# State Management

Each screen owns its own ViewModel.

Shared application state should be minimized.

Examples of shared state:

- current trip
- current day
- preferences

Avoid large global state objects.

---

# Dependency Injection

Services should be injected into ViewModels.

Avoid creating services directly inside Views.

Example:

```
TripOverviewViewModel

↓

TripService

↓

SwiftData
```

This improves testing and future extensibility.

---

# Error Handling

All import operations should be validated.

Possible errors:

- Invalid JSON
- Unsupported schema version
- Missing required fields
- Corrupted data

Errors should display user-friendly messages.

---

# Offline Strategy

P0 is offline-first.

The following should work without internet:

- viewing trips
- viewing destinations
- reviews
- preferences
- progress tracking
- bundled sample trip

No online services are required.

---

# Future Integrations

The architecture should allow future support for:

## P1

- Mapbox Maps SDK
- Mapbox Navigation
- Offline routing
- GPS
- Audio tours

## P2

- AI itinerary generation
- Built-in travel companion
- Weather APIs
- Dynamic recommendations

## P3

- Cloud synchronization
- Community
- Shared trips
- Apple Watch
- CarPlay

These integrations should be added through new Services without requiring major architectural changes.

---

# Development Guidelines

Always:

- Follow MVVM.
- Keep Views lightweight.
- Reuse components.
- Use protocol-oriented design where appropriate.
- Favor composition over inheritance.

Never:

- Put business logic inside Views.
- Hardcode sample data inside Views.
- Couple UI directly to JSON parsing.
- Introduce unnecessary dependencies.

---

# Testing Strategy

P0 should support:

- Unit tests for Services
- ViewModel tests
- JSON validation tests
- Import/export tests

UI testing can be expanded in future releases.

---

# Architecture Goals

The architecture should allow the project to evolve from:

Sample JSON

↓

Imported Trips

↓

AI Generated Trips

↓

Cloud-Synchronized Trips

without requiring major structural changes.
