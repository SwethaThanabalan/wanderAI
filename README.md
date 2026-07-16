# 🧭 wanderAI

> Your intelligent travel companion for every journey.

wanderAI is an iPhone travel companion designed to help travelers experience destinations with confidence. It combines trip planning, itinerary execution, integrated navigation, audio storytelling, and personalized recommendations into a single travel experience.

Rather than switching between multiple apps for planning, navigation, reviews, podcasts, and travel information, wanderAI aims to become the one companion travelers rely on before, during, and after every trip.

> **Current Status:** 🚧 Alpha Development

---

# 🌎 Vision

Our vision is to build the ultimate travel companion that seamlessly combines everything a traveler needs into a single experience.

Whether you're traveling solo, with family, older adults, or pets, wanderAI adapts to your travel style and helps you discover places with confidence while learning the stories behind them.

Our long-term goal is to eliminate the need to constantly switch between different travel applications by bringing navigation, travel guidance, community, and AI assistance together.

---

# ❤️ Why wanderAI Exists

Travel is more than simply reaching a destination.

The best memories come from discovering hidden places, understanding local history, making spontaneous stops, and sharing experiences with the people around you.

wanderAI exists to become your travel companion—not just another navigation app.

It helps travelers:

- Discover destinations worth visiting
- Learn the history behind every stop
- Stay organized throughout the trip
- Experience routes instead of simply driving through them
- Travel confidently with family, pets, or older adults
- Capture memories throughout the journey

---

# ✨ Core Features

## P0 (Alpha)

- 📋 Trip execution from imported JSON itineraries
- 🗺 Interactive trip overview map
- 📍 Daily itinerary management
- ⭐ Destination highlights
- ✅ Trip progress tracking
- 🐶 Dog-friendly recommendations
- 👨‍👩‍👧 Kid-friendly recommendations
- 👴 Older-adult-friendly recommendations
- ♿ Accessibility information
- 📝 Local reviews
- 📤 Preference export for AI trip generation

---

## Future Features

- 🧠 AI Travel Companion
- 🧭 Fully integrated in-app navigation
- 🗺 Offline maps
- 🎧 GPS-triggered audio tours
- 🎙 Travel podcasts
- 🌦 Weather-aware itinerary optimization
- 📸 AI travel journal
- 👥 Community reviews
- 🤝 Social travel features
- 🚗 CarPlay support
- ⌚ Apple Watch support

---

# 🚀 How wanderAI Works

Current workflow (P0):

```text
External AI / LLM
        │
        ▼
Trip JSON
        │
        ▼
Import into wanderAI
        │
        ▼
Trip Overview
        │
        ▼
Start Trip
        │
        ▼
Trip Execution
        │
        ▼
Complete Stops
        │
        ▼
Leave Reviews
        │
        ▼
Export Preferences
```

Future workflow:

```text
Plan Trip
        │
        ▼
AI Companion
        │
        ▼
Build Itinerary
        │
        ▼
Navigation
        │
        ▼
Audio Tour
        │
        ▼
Travel Community
        │
        ▼
Travel Journal
```

---

# 📱 Project Status

wanderAI is currently in **Alpha**.

The current milestone focuses on validating the core travel execution experience using structured trip data.

### Current Goals

- Build the core iOS application
- Validate the trip execution workflow
- Design scalable JSON contracts
- Test the experience internally
- Gather feedback before external testing

Features such as AI planning, live navigation, offline routing, and cloud synchronization are intentionally postponed until later milestones.

---

# 🏗 Architecture

Current stack:

- SwiftUI
- Swift
- MVVM Architecture
- SwiftData
- Codable
- Local JSON Import/Export

Future integrations:

- Mapbox Navigation SDK
- Offline Maps
- AI Providers (LLMs)
- Weather APIs
- Cloud Synchronization
- CarPlay

---

# 📁 Repository Structure

```
wanderAI/
├── README.md
├── PRODUCT_SPEC.md
├── P0_SCOPE.md
├── DESIGN_PRINCIPLES.md
├── BRAND_GUIDELINES.md
├── ARCHITECTURE.md
├── DATA_MODEL.md
├── USER_FLOWS.md
├── SCREEN_SPECIFICATIONS.md
├── TRIP_EXECUTION.md
├── JSON_CONTRACTS.md
├── IMPLEMENTATION_PLAN.md
├── ROADMAP.md
├── DECISION_LOG.md
├── Schemas/
└── .kiro/
```

---

# 🚀 Getting Started

### Requirements

- Xcode 16+
- iOS 17+
- macOS Sequoia or later

### Running the project

1. Clone the repository.
2. Open `wanderAI.xcodeproj`.
3. Build and run using an iPhone simulator.
4. The application loads a bundled sample trip for development.

---

# 🗺 Roadmap

### P0 — Alpha

- Trip execution
- Trip overview
- JSON import
- JSON preference export
- Local reviews
- Interactive trip map

### P1

- In-app navigation
- Offline maps
- Route visualization
- GPS-triggered audio

### P2

- AI trip planning
- Personalized recommendations
- Dynamic itinerary optimization
- AI travel companion

### P3

- Community features
- Shared trips
- Cloud sync
- CarPlay
- Apple Watch
- Travel journal

---

# 🤝 Contributing

The project is currently under active development.

Contribution guidelines will be published after the Alpha milestone.

---

# 📄 License

This project is currently proprietary and under active development.

No license has been assigned at this stage.

---

## 🐶 Meet Our Mascot

wanderAI is accompanied by a curious brown toy poodle explorer who represents the spirit of discovery.

Throughout the app, the mascot appears during onboarding, loading states, achievements, and helpful moments—bringing a sense of warmth and companionship to every journey.

---

*"Travel isn't just about reaching your destination. It's about experiencing everything along the way."*
