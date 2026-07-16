# wanderAI Technical Design

Implementation must follow:

- branding/ARCHITECTURE.md
- boundaries/DESIGN_PRINCIPLES.md
- boundaries/BRAND_GUIDELINES.md

Architecture:

- SwiftUI
- MVVM
- SwiftData
- Codable
- Dependency Injection

Use MapKit only for contextual maps.

No Mapbox.

No networking.

No AI.

No authentication.

No cloud.

Future services should be abstracted behind protocols.

All imported data must conform to JSON_CONTRACTS.md.
