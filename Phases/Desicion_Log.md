# wanderAI Product Roadmap

**Version:** 0.1.0  
**Current Phase:** P0 — Alpha  
**Platform:** iOS 17+  
**Primary Source of Truth:** `PRODUCT_SPEC.md`

---

## 1. Purpose

This roadmap defines how wanderAI will evolve from an internally tested Alpha into a complete travel companion.

The roadmap is directional rather than date-based. A phase should advance only after the previous phase has been validated.

The current priority is P0.

Future functionality may be documented and architecturally anticipated, but it must not be implemented unless the project formally moves into that phase.

---

## 2. Product Vision

wanderAI aims to become an all-in-one travel companion that helps people understand, execute, navigate, and experience trips.

The long-term experience may combine:

- AI-assisted trip planning
- Trip execution
- Integrated maps and navigation
- Offline travel support
- Audio tours
- Related podcasts and stories
- Destination reviews
- Traveler tips
- Social and community features
- Dog-friendly travel guidance
- Kid-friendly travel guidance
- Older-adult-friendly travel guidance
- Accessibility information

---

## 3. Phase Summary

| Phase | Product Focus | Primary Validation |
|---|---|---|
| P0 | Trip understanding and execution | Does the app feel like a useful travel companion? |
| P1 | In-app navigation and audio | Can users travel without leaving wanderAI? |
| P2 | Built-in AI planning and adaptation | Can wanderAI create and adjust useful trips? |
| P3 | Community, sharing, and connected travel | Can travelers create value for one another? |

---

# 4. P0 — Alpha: Trip Execution Foundation

## Objective

Validate whether users can understand and execute a structured multi-day itinerary without confusion.

P0 focuses on the experience after a trip has already been created.

The trip may be loaded from:

- A bundled sample JSON file
- An externally generated JSON file
- A manually created valid JSON file

The external LLM workflow is temporary. No LLM is built into P0.

---

## Core P0 Experience

```text
Open App
    ↓
Load or Import Trip
    ↓
View Trip Overview
    ↓
Review Map and Daily Stops
    ↓
Start Trip
    ↓
Enter Trip Execution Mode
    ↓
Complete, Skip, or Move Stops
    ↓
Review Destinations and Trip
    ↓
View Trip Summary
