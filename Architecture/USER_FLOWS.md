# wanderAI User Flows

**Version:** 0.1.0  
**Status:** Alpha — P0  
**Platform:** iOS 17+

---

## Purpose

This document defines the primary end-to-end user flows for the wanderAI P0 application.

P0 focuses on helping users view, understand, and execute an existing trip generated from structured JSON.

P0 does not include:

- Built-in AI trip planning
- Turn-by-turn navigation
- Live GPS tracking
- Offline route calculation
- Community or cloud features

If this document conflicts with `PRODUCT_SPEC.md`, the product specification is the source of truth.

---

# 1. Application Launch Flow

```text
Launch App
    ↓
Load Local Data
    ↓
Are Trips Available?
    ├── Yes → Home With Trip List
    └── No  → Empty Home State
                    ↓
             Load Sample Trip
             or Import Trip JSON
```

## Expected Behavior

On launch, the app must:

1. Initialize local persistence.
2. Retrieve previously saved trips.
3. Retrieve saved trip progress and reviews.
4. Display the Home screen.
5. Offer a bundled sample trip when no trips exist.

## Failure Behavior

If local data cannot be loaded:

- Show a user-friendly error state.
- Do not crash.
- Offer a retry action.
- Preserve access to the bundled sample trip where possible.

---

# 2. Load Sample Trip Flow

```text
Empty Home State
    ↓
Tap "Load Sample Trip"
    ↓
Read Bundled sample-trip.json
    ↓
Validate JSON
    ↓
Is JSON Valid?
    ├── Yes → Save Trip Locally
    │           ↓
    │        Open Trip Overview
    └── No  → Show Import Error
```

## Requirements

- The sample trip must be stored as a bundled JSON resource.
- The sample must use the same schema as imported trips.
- Loading the sample must not create duplicate copies without confirmation.
- The sample trip must include map references for every stop and route highlight.

---

# 3. Home to Trip Overview Flow

```text
Home
    ↓
Tap Trip Card
    ↓
Trip Overview
```

## Trip Card Information

Each trip card should display:

- Trip name
- Primary destination
- Date range
- Cover image
- Number of days
- Progress status
- Suitability indicators where relevant

## Trip States

A trip may be:

- Not Started
- In Progress
- Completed

---

# 4. Import Trip Flow

```text
Home
    ↓
Tap Import
    ↓
Open iOS File Picker
    ↓
Select JSON File
    ↓
Read File
    ↓
Validate Schema
    ↓
Is Trip Valid?
    ├── Yes → Check for Existing Trip ID
    │           ├── New Trip → Save Trip
    │           └── Existing Trip → Show Conflict Options
    └── No  → Show Validation Error
```

## Existing Trip Conflict Options

When a matching trip ID already exists, provide:

- Replace Existing Trip
- Import as Copy
- Cancel

## Validation Errors

The app should identify useful errors such as:

- Invalid JSON
- Missing required property
- Unsupported format version
- Invalid latitude or longitude
- Missing map reference
- Duplicate stop identifier
- Invalid day or stop order

Do not expose raw decoder errors as the primary user-facing message.

---

# 5. Delete Trip Flow

```text
Home
    ↓
Open Trip Context Menu or Swipe Action
    ↓
Tap Delete
    ↓
Confirmation Dialog
    ↓
Confirm?
    ├── Yes → Delete Trip and Related Local Data
    └── No  → Return to Home
```

## Related Data

Deleting a trip should also delete:

- Trip progress
- Destination reviews associated only with that trip
- Trip review
- Rescheduled stop state

The bundled sample JSON file must remain available for reloading.

---

# 6. Trip Overview Flow

```text
Home
    ↓
Trip Overview
    ├── View Route Map
    ├── Browse Days
    ├── View Highlights
    ├── Open Destination
    └── Start or Resume Trip
```

## User Goal

The user should understand:

- Where the trip takes place
- How many days it contains
- The broad route
- Major destinations
- Important highlights
- Whether the trip fits the group
- What happens when the trip begins

## Map Interaction

The map must display:

- Planned destinations
- Ordered pins
- Start and end states
- Route highlights
- A simple line connecting planned stops
- A viewport that fits visible locations

Tapping a pin should open a location preview sheet.

---

# 7. Map Pin Preview Flow

```text
Trip Overview Map
    ↓
Tap Pin
    ↓
Location Preview Bottom Sheet
    ├── View Summary
    ├── View Suitability
    ├── View Planned Time
    ├── Open Full Details
    └── Dismiss
```

## Preview Content

The preview sheet should include:

- Name
- Image where available
- Destination or highlight category
- Estimated duration
- Rating
- Must-do summary
- Dog-friendly status
- Kid-friendly status
- Older-adult suitability
- Accessibility status

The map should remain visible behind the sheet.

---

# 8. Start Trip Flow

```text
Trip Overview
    ↓
Tap "Start Trip"
    ↓
Has Trip Already Started?
    ├── No  → Initialize Trip Progress
    └── Yes → Restore Existing Progress
                    ↓
             Trip Execution Mode
```

## Start Trip Behavior

Starting the trip must:

- Preserve the complete itinerary.
- Set the first unfinished stop as current.
- Open Trip Execution Mode.
- Show the full route and stops.
- Not begin live navigation.
- Not request location permission in P0.

## Button Labels

Use:

- `Start Trip` for unstarted trips
- `Resume Trip` for in-progress trips
- `View Completed Trip` for completed trips

---

# 9. Trip Execution Flow

```text
Trip Execution
    ├── View Route
    ├── View Current Stop
    ├── View Upcoming Stops
    ├── View Route Highlights
    ├── Open Destination
    ├── Complete Stop
    ├── Skip Stop
    ├── Reschedule Stop
    ├── Switch Day
    └── End or Pause Session
```

## User Goal

The user should always understand:

- Which trip and day are active
- What has already been completed
- What the current stop is
- What comes next
- What is available along the route
- How much of the day and trip remains

---

# 10. Complete Stop Flow

```text
Current Stop
    ↓
Tap "Complete Stop"
    ↓
Save Completion State
    ↓
Optional Quick Rating Prompt
    ↓
Are More Stops Available Today?
    ├── Yes → Advance to Next Unfinished Stop
    └── No  → Open End-of-Day Summary
```

## Completion Feedback

The app should provide:

- Clear visual state change
- Progress update
- Subtle success feedback
- Next-stop preview

Completion should not rely only on color.

---

# 11. Skip Stop Flow

```text
Current or Upcoming Stop
    ↓
Tap "Skip"
    ↓
Choose Reason — Optional
    ↓
Choose Outcome
    ├── Move to Another Day
    ├── Leave Unscheduled
    ├── Remove From This Trip
    └── Cancel
```

## P0 Rescheduling Rules

The app does not need AI to reschedule a stop.

The user may manually:

- Move the stop to another existing day.
- Place it at the end of the selected day.
- Leave it skipped.
- Restore it later.

The app should not claim that a moved stop is route-optimized.

---

# 12. Move Stop to Another Day Flow

```text
Skipped Stop
    ↓
Tap "Move to Another Day"
    ↓
Choose Eligible Day
    ↓
Preview New Placement
    ↓
Confirm
    ↓
Update Day Itinerary
```

## Requirements

- The original imported trip must remain recoverable.
- The active itinerary may differ from the original itinerary.
- The app should mark user-modified stops clearly.
- Rescheduling must persist locally.
- The user should be able to undo the move.

---

# 13. Destination Details Flow

```text
Trip Overview or Trip Execution
    ↓
Tap Destination
    ↓
Destination Details
    ├── View Description
    ├── View History
    ├── View Must-Do Activities
    ├── View Highlights
    ├── View Practical Details
    ├── View Suitability
    ├── View Map Reference
    ├── Read Reviews
    └── Write Review
```

## Exit Behavior

Returning from Destination Details should restore:

- Selected day
- Map position where practical
- Current stop
- Execution progress
- Scroll position where practical

---

# 14. Route Highlight Flow

```text
Trip Overview or Execution Map
    ↓
Tap Route Highlight
    ↓
Highlight Preview Sheet
    ├── View Image
    ├── View Description
    ├── View Category
    ├── View Detour Estimate
    └── Open Details
```

## Route Highlight Categories

Examples include:

- Scenic viewpoint
- Photo spot
- Café
- Restaurant
- Gas
- Restroom
- Dog-friendly stop
- Picnic area
- Trailhead
- Local attraction

Route highlights are informational in P0.

---

# 15. Destination Review Flow

```text
Destination Details
    ↓
Tap "Write Review"
    ↓
Review Form
    ↓
Enter Ratings and Notes
    ↓
Save Review
    ↓
Return to Destination Details
```

## Destination Review Fields

Support:

- Overall rating
- Written review
- Dog friendliness
- Kid friendliness
- Older-adult suitability
- Accessibility
- Crowd level
- Visit date
- Optional visit notes

Reviews are stored locally in P0.

---

# 16. Trip Review Flow

```text
Trip Summary
    ↓
Tap "Review Trip"
    ↓
Trip Review Form
    ↓
Rate Overall Trip
    ↓
Add Notes
    ↓
Save
```

## Trip Review Fields

Support:

- Overall trip rating
- Itinerary quality
- Pace
- Route quality
- Suitability for travel group
- Favorite destination
- Written summary

---

# 17. End-of-Day Flow

```text
Complete Final Stop of Day
    ↓
End-of-Day Summary
    ├── View Completed Stops
    ├── View Skipped Stops
    ├── Move Missed Stops
    ├── View Statistics
    └── Continue to Next Day
```

## End-of-Day Statistics

Where data is available, display:

- Stops completed
- Stops skipped
- Planned distance
- Estimated experience time
- Number of highlights viewed
- Ratings submitted

Do not claim actual distance traveled without location tracking.

---

# 18. Trip Completion Flow

```text
Complete Final Required Stop
    ↓
Trip Completion Summary
    ├── Trip Statistics
    ├── Favorite Locations
    ├── New Sticker
    ├── Review Trip
    └── Return Home
```

## P0 Completion Content

Show:

- Destinations completed
- Days completed
- Planned route distance, if provided in JSON
- Reviews submitted
- Highlights visited or marked
- Earned sticker

## Community Comparison

P0 must not show real community rankings because no backend exists.

A comparison feature may only appear as:

- A clearly labeled prototype
- Static sample data
- Or a disabled future feature

The app must not imply that fictional comparison data is real.

---

# 19. Export Preferences Flow

```text
Home or Preferences
    ↓
Tap "Export Preferences"
    ↓
Review Preference Summary
    ↓
Generate JSON
    ↓
Open iOS Share Sheet
```

## Requirements

The exported JSON should:

- Follow the preferences schema.
- Include a schema version.
- Exclude private device information.
- Be readable by an external LLM.
- Represent the current travel preferences.

---

# 20. Edit Preferences Flow

```text
Home
    ↓
Open Preferences
    ↓
Edit Sections
    ├── Travel Group
    ├── Interests
    ├── Pace
    ├── Mobility
    ├── Pet Needs
    ├── Food
    ├── Driving
    └── Accommodation
            ↓
         Save Locally
```

---

# 21. Restore Original Itinerary Flow

```text
Modified Trip
    ↓
Open Trip Options
    ↓
Tap "Restore Original Plan"
    ↓
Confirmation
    ↓
Choose Scope
    ├── Restore Current Day
    └── Restore Entire Trip
```

Trip completion and reviews should not be removed unless explicitly requested.

---

# 22. P0 Navigation Hierarchy

```text
Home
├── Preferences
├── Import Trip
└── Trip Overview
    ├── Destination Details
    │   └── Review Form
    └── Trip Execution
        ├── Location Preview Sheet
        ├── Destination Details
        ├── Reschedule Stop
        ├── End-of-Day Summary
        └── Trip Completion Summary
```

---

# 23. Future Flow Extensions

The following are future workflows and must not be implemented in P0:

## P1

```text
Trip Execution
    ↓
Start Navigation
    ↓
Live In-App Navigation
    ↓
GPS Audio Trigger
    ↓
Arrival
```

## P2

```text
AI Conversation
    ↓
Generated Itinerary Draft
    ↓
User Review and Edit
    ↓
Save Trip
    ↓
Trip Overview
```

## P3

```text
Completed Trip
    ↓
Publish to Community
    ↓
Comments, Saves, and Shared Routes
```
