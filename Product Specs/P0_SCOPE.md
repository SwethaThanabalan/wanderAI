# P0 Scope

**Project:** wanderAI

**Version:** 0.1.0

**Status:** Alpha

---

# Purpose

This document defines the scope of the Alpha (P0) release.

The goal of P0 is **not** to build the complete wanderAI vision.

Instead, P0 focuses on validating the core travel execution experience using structured trip data.

If a feature is not listed in this document, it should be considered **out of scope** unless explicitly approved.

---

# Primary Objective

Validate whether users can:

- Understand their itinerary
- Execute their trip confidently
- Feel like wanderAI is a travel companion
- Navigate through their daily plan without confusion

The Alpha is intended for internal testing only.

---

# Included Features

## Home

- View all trips
- Load bundled sample trip
- Import Trip JSON
- Delete Trip
- Export Preferences JSON

---

## Trip Overview

- Trip summary
- Daily overview
- Interactive map
- Planned route
- Destination pins
- Route highlights
- Start Trip button

---

## Trip Execution

- Route overview
- Current destination
- Upcoming destinations
- Progress tracking
- Complete destination
- Skip destination
- Route highlights

Trip Execution **does not include live navigation.**

---

## Destination Details

Each destination should display:

- Hero image
- Description
- History
- Highlights
- Must-do activities
- Estimated visit duration
- Accessibility
- Dog-friendly information
- Kid-friendly information
- Older-adult suitability
- Reviews
- Map reference

---

## Reviews

Support:

- Destination Reviews
- Trip Reviews

Reviews remain local to the device.

---

## Preferences

Allow users to export preferences as JSON.

This JSON will be used by future AI systems to generate trips.

---

# Data

P0 uses:

- Local JSON
- Sample bundled trips
- Local images
- SwiftData

No cloud services.

---

# Out of Scope

The following features should **NOT** be implemented in P0.

## AI

- Built-in AI assistant
- Chat interface
- LLM integration
- AI itinerary generation

---

## Navigation

- Turn-by-turn navigation
- Live GPS
- Route recalculation
- Offline routing
- Voice navigation

---

## Maps

- Live traffic
- Route optimization
- Navigation SDK integration

Map support in P0 is limited to displaying imported map references.

---

## Accounts

- Login
- Authentication
- Profiles
- Cloud Sync

---

## Community

- Public reviews
- Following users
- Comments
- Messaging
- Shared trips

---

## Integrations

- Apple Maps
- Google Maps
- Mapbox Navigation
- Weather APIs
- Spotify
- Podcasts
- Calendar

---

# Success Criteria

P0 is successful if users can:

- Import a trip
- Understand the itinerary
- Understand today's route
- Execute their trip
- Complete destinations
- Skip destinations
- Review destinations
- Export preferences

without confusion.

---

# Future Milestones

## P1

Navigation

- In-app navigation
- GPS
- Offline maps
- Audio tours

---

## P2

AI

- Built-in AI
- AI itinerary generation
- Dynamic trip planning
- Personalized recommendations

---

## P3

Community

- Shared trips
- Cloud sync
- Travel journals
- Social features

---

# Development Rules

When implementing P0:

- Build only what is required for validation.
- Avoid introducing unnecessary complexity.
- Prefer local storage over network services.
- Design future integrations through interfaces, not implementations.
- Do not implement P1 or P2 functionality.
- Keep the architecture extensible.

When in doubt, optimize for validating the travel execution experience rather than adding features.
