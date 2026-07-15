# wanderAI JSON Contracts

**Version:** 0.1.0  
**Status:** Alpha — P0  
**Platform:** iOS 17+  
**Source of Truth:** `PRODUCT_SPEC.md`

---

## 1. Purpose

This document defines the structured JSON contracts used by wanderAI.

P0 uses JSON for:

1. Importing trips
2. Loading the bundled sample trip
3. Exporting traveler preferences

The contracts are designed to support the current P0 application while remaining extensible for future LLM-generated itineraries, navigation, audio tours, community data, and cloud synchronization.

---

## 2. P0 Data Workflow

```text
External LLM or Manually Created File
                ↓
          Trip JSON File
                ↓
        wanderAI Validation
                ↓
          Local Trip Model
                ↓
            SwiftData
                ↓
         Trip Execution Mode
```

Preference workflow:

```text
Traveler Preferences
        ↓
wanderAI Preference Form
        ↓
Preference JSON Export
        ↓
External LLM
        ↓
Trip JSON
```

In P0, the LLM interaction occurs outside wanderAI.

---

## 3. File Types

### Trip Import

Recommended filename:

```text
wanderai-trip.json
```

Format identifier:

```json
"format": "wanderAI.trip"
```

### Preference Export

Recommended filename:

```text
wanderai-preferences.json
```

Format identifier:

```json
"format": "wanderAI.preferences"
```

---

## 4. Versioning

Every imported and exported document must include:

```json
{
  "format": "wanderAI.trip",
  "formatVersion": "1.0.0"
}
```

The version follows semantic versioning:

```text
MAJOR.MINOR.PATCH
```

### Version Meaning

- **Major:** Breaking structural change
- **Minor:** Backward-compatible field additions
- **Patch:** Clarification or non-structural correction

P0 must support trip format version `1.x.x`.

Unsupported major versions must be rejected with a clear message.

---

## 5. Trip Import Root Structure

```json
{
  "format": "wanderAI.trip",
  "formatVersion": "1.0.0",
  "generatedAt": "2026-07-15T18:00:00Z",
  "generator": {
    "type": "externalLLM",
    "name": "Optional Generator Name",
    "version": null
  },
  "trip": {}
}
```

### Root Fields

| Field | Type | Required | Description |
|---|---|---:|---|
| format | String | Yes | Must equal `wanderAI.trip` |
| formatVersion | String | Yes | Contract version |
| generatedAt | ISO 8601 String | No | Document-generation time |
| generator | Object | No | Source that generated the trip |
| trip | Object | Yes | Complete trip definition |

---

## 6. Trip Object

```json
{
  "id": "olympic-road-trip-001",
  "name": "Olympic National Park Adventure",
  "summary": "A five-day scenic road trip through the Olympic Peninsula.",
  "primaryDestination": "Olympic Peninsula, Washington",
  "startDate": "2026-07-28",
  "endDate": "2026-08-02",
  "timeZone": "America/Los_Angeles",
  "coverImage": {
    "type": "asset",
    "value": "olympic-cover",
    "altText": "Lake and mountains in Olympic National Park"
  },
  "travelGroup": {},
  "suitability": {},
  "statistics": {},
  "highlights": [],
  "days": [],
  "community": {},
  "metadata": {}
}
```

### Required Trip Fields

- `id`
- `name`
- `primaryDestination`
- `days`

### Recommended Trip Fields

- `summary`
- `startDate`
- `endDate`
- `timeZone`
- `coverImage`
- `travelGroup`
- `suitability`
- `statistics`
- `highlights`

---

## 7. Identifier Rules

All identifiers must:

- Be strings
- Be unique within their scope
- Remain stable across imports
- Avoid personally identifiable information
- Prefer lowercase kebab-case

Example:

```json
"id": "lake-crescent"
```

Duplicate trip, day, stop, highlight, review, or tip identifiers must fail validation where uniqueness is required.

---

## 8. Date and Time Rules

### Dates

Use ISO 8601 date format:

```text
YYYY-MM-DD
```

Example:

```json
"startDate": "2026-07-28"
```

### Times

Use 24-hour local time:

```text
HH:mm
```

Example:

```json
"plannedTime": "10:30"
```

### Timestamps

Use ISO 8601 UTC timestamps:

```json
"generatedAt": "2026-07-15T18:00:00Z"
```

### Time Zone

Use an IANA identifier:

```json
"timeZone": "America/Los_Angeles"
```

---

## 9. Image Reference

P0 should support bundled local images.

```json
{
  "type": "asset",
  "value": "lake-crescent-hero",
  "altText": "Lake Crescent surrounded by forested mountains"
}
```

Future-compatible remote image:

```json
{
  "type": "remote",
  "value": "https://example.com/image.jpg",
  "altText": "Lake Crescent surrounded by forested mountains"
}
```

### Image Fields

| Field | Required | Description |
|---|---:|---|
| type | Yes | `asset` or future `remote` |
| value | Yes | Asset name or URL |
| altText | Recommended | Accessible description |

P0 must not require remote images to function.

---

## 10. Travel Group

```json
{
  "adults": 2,
  "children": 0,
  "olderAdults": 0,
  "pets": [
    {
      "type": "dog",
      "name": "Ferro",
      "size": "small"
    }
  ]
}
```

All fields are optional unless the trip experience depends on them.

---

## 11. Suitability Object

Suitability should support both a status and supporting details.

```json
{
  "dogFriendly": {
    "status": "yes",
    "details": "Dogs are allowed on leash in designated areas."
  },
  "kidFriendly": {
    "status": "yes",
    "details": "Short walks and accessible viewpoints."
  },
  "olderAdultFriendly": {
    "status": "partial",
    "details": "Main viewpoint is accessible, but trails may be uneven."
  },
  "wheelchairAccessible": {
    "status": "partial",
    "details": "Accessible parking and lodge entrance."
  },
  "strollerFriendly": {
    "status": "partial",
    "details": "Suitable near the lodge but not on all trails."
  }
}
```

### Status Values

- `yes`
- `no`
- `partial`
- `unknown`

Do not replace unknown information with assumed values.

---

## 12. Trip Statistics

```json
{
  "plannedDistanceMiles": 412,
  "estimatedDrivingMinutes": 780,
  "estimatedActivityMinutes": 960,
  "totalStops": 14
}
```

These values are planned estimates, not live measurements.

The UI must label them accordingly.

---

## 13. Trip-Level Highlights

```json
[
  {
    "id": "highlight-rainforest",
    "title": "Explore the Hoh Rain Forest",
    "description": "Walk through one of the largest temperate rain forests in the United States.",
    "image": {
      "type": "asset",
      "value": "hoh-rainforest",
      "altText": "Moss-covered trees in Hoh Rain Forest"
    }
  }
]
```

---

## 14. Day Object

```json
{
  "id": "day-1",
  "dayNumber": 1,
  "date": "2026-07-28",
  "title": "Port Angeles and Lake Crescent",
  "summary": "Begin the Olympic Peninsula journey with waterfront and lake destinations.",
  "route": {},
  "statistics": {},
  "stops": [],
  "routeHighlights": []
}
```

### Required Day Fields

- `id`
- `dayNumber`
- `title`
- `stops`

### Day Number Rules

- Must be an integer greater than zero
- Must be unique within the trip
- Should follow chronological order

---

## 15. Day Route

```json
{
  "startLocationId": "port-angeles",
  "endLocationId": "lake-crescent",
  "displayMode": "overview",
  "encodedPolyline": null
}
```

### P0 Rules

- `startLocationId` should reference a valid stop.
- `endLocationId` should reference a valid stop.
- `displayMode` should be `overview`.
- `encodedPolyline` should normally be `null` in P0.

P0 may connect stop coordinates in sequence rather than using a routed road polyline.

---

## 16. Day Statistics

```json
{
  "plannedDistanceMiles": 42,
  "estimatedDrivingMinutes": 75,
  "estimatedActivityMinutes": 240
}
```

Values must be presented as estimates.

---

## 17. Stop Object

```json
{
  "id": "lake-crescent",
  "sequence": 2,
  "name": "Lake Crescent",
  "category": "naturalAttraction",
  "plannedTime": "10:00",
  "estimatedDurationMinutes": 90,
  "summary": "A deep glacial lake surrounded by forested mountains.",
  "description": "Lake Crescent is known for its clear blue water and scenic shoreline.",
  "history": "The lake was formed by glaciers and later separated from the Elwha River system.",
  "mapReference": {},
  "heroImage": {},
  "gallery": [],
  "mustDo": [],
  "highlights": [],
  "practicalInformation": {},
  "suitability": {},
  "reviews": [],
  "travelerTips": [],
  "tags": []
}
```

### Required Stop Fields

- `id`
- `sequence`
- `name`
- `mapReference`

### Recommended Stop Fields

- `category`
- `plannedTime`
- `estimatedDurationMinutes`
- `summary`
- `description`
- `heroImage`
- `mustDo`
- `suitability`

---

## 18. Stop Categories

Suggested values:

- `city`
- `naturalAttraction`
- `nationalPark`
- `statePark`
- `trail`
- `viewpoint`
- `beach`
- `waterfall`
- `museum`
- `historicSite`
- `restaurant`
- `cafe`
- `lodging`
- `transportation`
- `activity`
- `other`

The JSON Schema should use an enum when the category vocabulary is finalized.

---

## 19. Map Reference

Every planned stop and route highlight must include a map reference.

```json
{
  "latitude": 48.0587,
  "longitude": -123.7898,
  "formattedAddress": "Lake Crescent, Olympic National Park, WA 98363",
  "placeId": null,
  "mapLabel": "Lake Crescent",
  "pinStyle": "primary"
}
```

### Required Fields

- `latitude`
- `longitude`
- `mapLabel`

### Coordinate Rules

Latitude:

```text
-90 through 90
```

Longitude:

```text
-180 through 180
```

### Pin Style Values

- `start`
- `primary`
- `secondary`
- `end`

Execution-state styling such as current, completed, or skipped should normally be controlled by app state rather than imported pin style.

---

## 20. Must-Do Item

```json
{
  "id": "must-do-lodge-viewpoint",
  "title": "Walk to the lodge viewpoint",
  "description": "A short walk provides a classic view across the lake.",
  "priority": "high",
  "estimatedMinutes": 20
}
```

Priority values:

- `high`
- `medium`
- `low`

---

## 21. Destination Highlight

```json
{
  "id": "lake-lodge",
  "title": "Lake Crescent Lodge",
  "description": "A historic lodge with waterfront views.",
  "image": {
    "type": "asset",
    "value": "lake-crescent-lodge",
    "altText": "Historic lodge beside Lake Crescent"
  },
  "popularity": "popular"
}
```

Popularity values:

- `popular`
- `notable`
- `standard`
- `unknown`

Popularity must come from imported data and must not be inferred by the app.

---

## 22. Practical Information

```json
{
  "openingHours": "Open daily; hours vary seasonally.",
  "admission": "No separate admission; park pass may be required.",
  "parking": {
    "available": true,
    "details": "Parking is available near the lodge."
  },
  "restrooms": {
    "available": true,
    "details": "Restrooms are available near the lodge."
  },
  "phone": null,
  "website": null,
  "seasonality": "Best visited from late spring through early fall.",
  "warnings": [
    "Limited cellular coverage"
  ]
}
```

Unknown values should be null or omitted.

Do not use fabricated values.

---

## 23. Route Highlight

```json
{
  "id": "devils-punchbowl",
  "name": "Devil's Punchbowl",
  "category": "photoSpot",
  "description": "A clear swimming area and popular photo location along the trail.",
  "sequenceAfterStopId": "lake-crescent",
  "mapReference": {
    "latitude": 48.0703,
    "longitude": -123.8377,
    "formattedAddress": "Spruce Railroad Trail, Port Angeles, WA",
    "placeId": null,
    "mapLabel": "Devil's Punchbowl",
    "pinStyle": "secondary"
  },
  "image": {
    "type": "asset",
    "value": "devils-punchbowl",
    "altText": "Turquoise water at Devil's Punchbowl"
  },
  "estimatedDetourMinutes": 15,
  "optional": true,
  "popularity": {
    "label": "Popular Photo Stop",
    "score": 0.84
  },
  "suitability": {}
}
```

### Route Highlight Categories

- `scenicViewpoint`
- `photoSpot`
- `cafe`
- `restaurant`
- `gas`
- `restroom`
- `dogStop`
- `picnicArea`
- `trailhead`
- `localAttraction`
- `other`

---

## 24. Imported Community Data

P0 may display imported social data.

```json
{
  "aggregateRating": 4.7,
  "reviewCount": 284,
  "popularityLabel": "Popular with road trippers",
  "sourceLabel": "Imported trip data"
}
```

Imported values are read-only.

The UI must not imply that they are synchronized live.

---

## 25. Imported Review

```json
{
  "id": "review-001",
  "authorDisplayName": "Maya",
  "authorType": "dogTraveler",
  "rating": 5,
  "title": "Beautiful early-morning stop",
  "text": "Arrive before 9 AM for easier parking and calmer water.",
  "visitSeason": "summer",
  "helpfulCount": 18,
  "source": "imported"
}
```

### Rating Rules

- Minimum: `1`
- Maximum: `5`

### Source Values

- `imported`
- `sample`
- `localUser`

Local user reviews should generally be stored separately from the immutable imported trip payload.

---

## 26. Traveler Tip

```json
{
  "id": "tip-001",
  "authorDisplayName": "Maya",
  "authorType": "dogTraveler",
  "text": "The lodge area is dog friendly, but nearby trails may have restrictions.",
  "visitSeason": "summer",
  "helpfulCount": 18,
  "tags": [
    "dog-friendly",
    "parking"
  ]
}
```

Helpful votes made by the P0 user are local overlays and must not overwrite the imported count.

---

## 27. Tags

Tags are lowercase strings.

Example:

```json
[
  "dog-friendly",
  "photography",
  "scenic-drive",
  "easy-walk",
  "restrooms"
]
```

Tags should not replace structured suitability or practical-information fields.

---

## 28. Local Execution State

Execution state should not modify the original imported JSON.

It should be stored separately.

Conceptual model:

```json
{
  "tripId": "olympic-road-trip-001",
  "status": "inProgress",
  "activeDayId": "day-1",
  "currentStopId": "lake-crescent",
  "stopStates": [
    {
      "stopId": "port-angeles",
      "status": "completed",
      "completedAt": "2026-07-28T16:00:00Z",
      "originalDayId": "day-1",
      "activeDayId": "day-1",
      "activeSequence": 1
    }
  ]
}
```

### Stop Status Values

- `planned`
- `current`
- `completed`
- `skipped`
- `moved`
- `removed`

This state is local application data and does not need to be part of the imported trip schema.

---

## 29. Local Review Data

Local destination reviews should reference trip and stop IDs.

```json
{
  "id": "local-review-001",
  "tripId": "olympic-road-trip-001",
  "stopId": "lake-crescent",
  "overallRating": 5,
  "reviewText": "Beautiful and peaceful in the morning.",
  "dogFriendlinessRating": 4,
  "kidFriendlinessRating": 5,
  "olderAdultSuitabilityRating": 5,
  "accessibilityRating": 4,
  "crowdLevel": "moderate",
  "visitDate": "2026-07-28",
  "createdAt": "2026-07-28T20:00:00Z"
}
```

These records should remain separate from imported community reviews.

---

## 30. Preference Export Root

```json
{
  "format": "wanderAI.preferences",
  "formatVersion": "1.0.0",
  "exportedAt": "2026-07-15T18:00:00Z",
  "preferences": {}
}
```

---

## 31. Preference Object

```json
{
  "travelerComposition": {},
  "travelStyle": {},
  "interests": [],
  "accessibility": {},
  "petPreferences": {},
  "kidPreferences": {},
  "olderAdultPreferences": {},
  "foodPreferences": {},
  "drivingPreferences": {},
  "accommodationPreferences": {},
  "destinationPreferences": {},
  "avoidances": [],
  "notesForPlanner": null
}
```

---

## 32. Traveler Composition Preferences

```json
{
  "defaultGroupType": "couple",
  "adultCount": 2,
  "childCount": 0,
  "olderAdultCount": 0,
  "travelsWithPets": true
}
```

Group type values may include:

- `solo`
- `couple`
- `family`
- `friends`
- `mixedAgeGroup`
- `other`

---

## 33. Travel Style

```json
{
  "pace": "balanced",
  "spontaneity": "moderate",
  "preferredDailyStartTime": "08:00",
  "preferredDailyEndTime": "19:00",
  "maximumActivitiesPerDay": 5
}
```

Pace values:

- `relaxed`
- `balanced`
- `active`

---

## 34. Interests

```json
[
  {
    "name": "scenic drives",
    "priority": "high"
  },
  {
    "name": "photography",
    "priority": "high"
  },
  {
    "name": "history",
    "priority": "medium"
  }
]
```

---

## 35. Accessibility Preferences

```json
{
  "wheelchairAccessRequired": false,
  "avoidStairs": false,
  "minimalWalking": false,
  "frequentSeating": false,
  "frequentRestroomStops": true,
  "maximumWalkingMilesPerDay": null,
  "additionalNotes": null
}
```

---

## 36. Pet Preferences

```json
{
  "travelingWithDog": true,
  "dogSize": "small",
  "leashFriendlyLocationsAccepted": true,
  "dogFriendlyTrailsPreferred": true,
  "dogParksPreferred": true,
  "petFriendlyDiningPreferred": true,
  "avoidPetRestrictedStops": true
}
```

---

## 37. Kid Preferences

```json
{
  "travelingWithChildren": false,
  "childAgeRanges": [],
  "strollerAccessRequired": false,
  "playgroundsPreferred": false,
  "familyRestroomsPreferred": false,
  "napFriendlySchedule": false
}
```

---

## 38. Older-Adult Preferences

```json
{
  "travelingWithOlderAdults": false,
  "minimalStairsPreferred": true,
  "benchesPreferred": true,
  "pavedPathsPreferred": true,
  "accessibleParkingPreferred": true,
  "frequentRestroomsPreferred": true
}
```

---

## 39. Food Preferences

```json
{
  "dietaryRestrictions": [],
  "preferredCuisines": [],
  "avoidedFoods": [],
  "diningStyle": [
    "casual",
    "local"
  ],
  "localCoffeePreferred": true
}
```

---

## 40. Driving Preferences

```json
{
  "maximumDrivingMinutesPerDay": 300,
  "scenicRoutesPreferred": true,
  "avoidTolls": false,
  "avoidFerries": false,
  "avoidUnpavedRoads": true,
  "comfortableWithMountainRoads": true,
  "frequentDrivingBreaks": true
}
```

---

## 41. Accommodation Preferences

```json
{
  "preferredTypes": [
    "hotel",
    "vacationRental",
    "cabin"
  ],
  "minimumNightsPerBase": 2,
  "petFriendlyRequired": true,
  "parkingRequired": true,
  "kitchenPreferred": false
}
```

---

## 42. Destination Preferences

```json
{
  "preferredDestinationTypes": [
    "national parks",
    "waterfalls",
    "mountains",
    "coastal drives"
  ],
  "hiddenGemsPreferred": true,
  "popularAttractionsAccepted": true,
  "crowdTolerance": "low",
  "sunriseActivitiesPreferred": false,
  "sunsetActivitiesPreferred": true
}
```

---

## 43. LLM Contract Expectations

A future or external LLM using the preference JSON should:

1. Respect all required accessibility and pet constraints.
2. Produce output matching the trip-import schema.
3. Include map references for every stop and route highlight.
4. Separate planned stops from optional route highlights.
5. Include suitability details rather than only boolean values.
6. Avoid inventing current hours, restrictions, ratings, or reviews.
7. Mark uncertain information as unknown.
8. Include source metadata when applicable.
9. Produce valid JSON without Markdown formatting.
10. Use the supported schema version.

---

## 44. Import Validation

The app must validate:

### Document-Level Rules

- Valid JSON
- Correct `format`
- Supported `formatVersion`
- Required trip object

### Trip-Level Rules

- Unique trip ID
- At least one day
- Valid date range where supplied

### Day-Level Rules

- Unique day ID
- Unique day number
- At least one stop, unless empty days are explicitly supported

### Stop-Level Rules

- Unique stop ID
- Valid sequence
- Required name
- Required map reference
- Valid coordinates

### Reference Rules

- Route start and end IDs reference valid stops
- `sequenceAfterStopId` references a valid stop
- IDs referenced by other objects exist

---

## 45. Import Error Messages

User-facing errors should be actionable.

Examples:

### Invalid Format

> This file is not a wanderAI trip.

### Unsupported Version

> This trip uses a newer format that this version of wanderAI cannot open.

### Missing Coordinates

> Lake Crescent is missing the map coordinates required for the trip overview.

### Duplicate Stop ID

> Two locations use the identifier “lake-crescent.” Each location needs a unique ID.

### Invalid JSON

> The selected file could not be read as valid JSON.

Raw decoding errors may be logged for development but should not be the main user-facing message.

---

## 46. Duplicate Trip Import

When an imported `trip.id` already exists, the app must offer:

- Replace Existing Trip
- Import as Copy
- Cancel

### Replace

Replace imported trip content while preserving local user data only when references remain valid.

If preservation cannot be guaranteed, warn the user.

### Import as Copy

Generate a new local trip ID while preserving source metadata.

---

## 47. Original and Mutable Data

The application must distinguish:

### Imported Source Data

- Trip structure
- Destination information
- Route highlights
- Imported reviews
- Imported tips
- Imported statistics

### Local Mutable Data

- Progress
- Stop status
- Stop rescheduling
- User reviews
- Helpful votes
- Preferences
- Favorite destination
- Earned stickers

The original imported payload should remain recoverable.

---

## 48. Privacy

Preference exports must not include:

- Device identifiers
- Exact current location
- Account credentials
- Unrelated personal data
- Hidden app analytics
- Health details not explicitly entered as travel requirements

Users should be able to preview preference information before exporting.

---

## 49. Schema Files

The repository should contain:

```text
Schemas/
├── trip-import.schema.json
├── preferences-export.schema.json
├── sample-trip.json
└── sample-preferences.json
```

Both sample files must validate against their corresponding schemas.

---

## 50. Future Contract Extensions

Future versions may add:

### P1

- Navigation profiles
- Encoded road polylines
- Offline-map region definitions
- Audio trigger coordinates
- Audio files and transcripts
- Navigation instructions
- Route alternatives

### P2

- AI conversation metadata
- Itinerary-generation rationale
- Recommendation confidence
- User-approved itinerary revisions
- Weather-aware alternatives

### P3

- User profiles
- Public reviews
- Community routes
- Shared trips
- Social activity
- Moderation status

Future additions should remain backward-compatible whenever practical.

---

## 51. Minimal Valid Trip Example

```json
{
  "format": "wanderAI.trip",
  "formatVersion": "1.0.0",
  "trip": {
    "id": "sample-trip",
    "name": "Sample Adventure",
    "primaryDestination": "Washington",
    "days": [
      {
        "id": "day-1",
        "dayNumber": 1,
        "title": "Sample Day",
        "stops": [
          {
            "id": "sample-stop",
            "sequence": 1,
            "name": "Sample Destination",
            "mapReference": {
              "latitude": 47.6062,
              "longitude": -122.3321,
              "mapLabel": "Sample Destination",
              "pinStyle": "primary"
            }
          }
        ],
        "routeHighlights": []
      }
    ]
  }
}
```

---

## 52. P0 Acceptance Criteria

The JSON contract is ready for P0 when:

- A valid sample trip can be decoded.
- Every stop includes a valid map reference.
- Every route highlight includes a valid map reference.
- Invalid documents produce actionable errors.
- Trips can be saved locally.
- Execution state remains separate from imported data.
- Destination and trip reviews can be stored locally.
- Preferences can be exported as valid JSON.
- Sample files validate against their schemas.
- Future navigation and LLM fields can be added without replacing the core trip model.
