# wanderAI Trip Execution Specification

**Version:** 0.1.0  
**Status:** Alpha — P0  
**Platform:** iOS 17+  
**Source of Truth:** `PRODUCT_SPEC.md`

---

## 1. Purpose

Trip Execution Mode is the central experience of wanderAI.

It helps travelers understand and follow an existing itinerary while keeping the route, current destination, upcoming stops, route highlights, progress, and practical travel information in one place.

In P0, Trip Execution Mode is an itinerary execution companion.

It does not provide:

- Turn-by-turn navigation
- Live GPS positioning
- Live ETA calculations
- Traffic-aware routing
- Route recalculation
- GPS-triggered audio
- Background location tracking

These features are planned for P1.

---

## 2. P0 Product Objective

Trip Execution Mode should help users feel that wanderAI is actively guiding their trip rather than simply displaying a static itinerary.

When users enter Trip Execution Mode, they should immediately understand:

- Which trip is active
- Which day is selected
- Where the day's destinations are located
- What the current stop is
- What comes next
- Which stops have been completed
- Which stops were skipped or moved
- What points of interest are available along the route
- How much of the day and overall trip remains

---

## 3. Entry Points

Users may enter Trip Execution Mode through:

- `Start Trip` from Trip Overview
- `Resume Trip` from Home
- `Resume Trip` from Trip Overview
- `Continue to Next Day` from End-of-Day Summary
- `View Completed Trip` for a finished itinerary

---

## 4. Start Trip Behavior

When a user taps `Start Trip`, the app must:

1. Create a local execution state for the trip.
2. Set the first itinerary day as the active day.
3. Set the first unfinished stop as the current stop.
4. Preserve the original imported itinerary.
5. Open Trip Execution Mode.
6. Display the current day's map, stops, and route highlights.
7. Save execution progress locally.

The app must not:

- Request location permission
- Start navigation
- Display the user’s live position
- Claim that the displayed line follows actual roads
- Present imported travel time as live travel time

### Trip Button States

| Trip state | Button label |
|---|---|
| Not started | Start Trip |
| In progress | Resume Trip |
| Completed | View Completed Trip |

---

## 5. Trip Execution Information Architecture

The primary screen should contain the following sections:

1. Trip and day header
2. Route overview map
3. Day and trip progress
4. Current stop
5. Upcoming stops
6. Along-the-route highlights
7. Quick trip controls

Suggested hierarchy:

```text
Trip Execution
├── Header
├── Day Selector
├── Map Overview
├── Progress Summary
├── Current Stop
├── Upcoming Stops
├── Along the Route
└── Trip Controls
```

---

## 6. Header

The header must display:

- Trip name
- Current or selected day
- Day title
- Day number
- Total number of days
- Trip status
- Access to Trip Overview
- Access to trip options

Example:

```text
Olympic National Park Adventure

Day 2 of 5
Lake Crescent and Sol Duc
```

### Trip Options

The trip options menu may contain:

- View Trip Overview
- Switch Day
- Pause Trip
- Restore Original Plan
- End Trip
- Delete Trip

Destructive actions must require confirmation.

---

## 7. Day Selector

Multi-day trips must allow users to review and manage each day.

Each day item should display:

- Day number
- Short day title
- Completion status
- Number of unfinished stops
- User-modified indicator, when applicable

### Day States

- Upcoming
- Active
- Partially completed
- Completed
- Modified

Selecting another day must update:

- Map pins
- Connecting route line
- Current stop context
- Upcoming-stop list
- Route highlights
- Day progress

The UI must distinguish between:

- The **active execution day**
- The **day currently being previewed**

Previewing another day must not automatically change the active execution day.

---

## 8. Map Overview

The P0 map is an informational route overview.

It must display:

- Start location
- Planned destination stops
- End location
- Route highlights
- Stop order
- Stop status
- A simple line connecting planned stops
- A viewport that includes all locations for the selected day

### Map Data Source

Every displayed location must come from the imported trip JSON and include a valid map reference.

Required coordinates:

- Latitude
- Longitude

### Pin Types

| Pin type | Purpose |
|---|---|
| Start | First location of the selected day |
| Current | Active stop |
| Planned | Upcoming planned stop |
| Completed | Completed stop |
| Skipped | Skipped stop |
| Moved | Stop moved from its original day |
| End | Final planned stop |
| Route highlight | Optional point of interest |

### Map Selection

Tapping a map pin must open a preview sheet.

The preview must allow the user to:

- Read the location summary
- View suitability
- View planned time and duration
- Open full details
- Complete or skip the stop when applicable

### P0 Map Limitations

The map must not imply:

- Live location
- Turn-by-turn guidance
- Accurate road routing
- Live traffic
- Real-time proximity
- Live arrival estimates

The line between locations may be a simple geographic connection based on itinerary order.

---

## 9. Journey Timeline

The Journey Timeline visually combines planned destinations and optional route highlights.

Example:

```text
Start of Day
│
● Port Angeles
│
◦ Scenic overlook
│
◦ Dog-friendly café
│
● Lake Crescent
│
◦ Photo spot
│
● Marymere Falls
│
● Sol Duc Falls
│
End of Day
```

### Visual Hierarchy

- Planned stops use larger numbered milestones.
- Route highlights use smaller category icons.
- Current stop receives the highest visual emphasis.
- Completed stops show a clear completion state.
- Skipped and moved stops must use text or icons in addition to color.

---

## 10. Progress Tracking

Progress must be tracked at three levels:

### Stop Progress

Each stop may be:

- Planned
- Current
- Completed
- Skipped
- Moved
- Removed from active itinerary

### Day Progress

Display:

- Completed stops
- Remaining stops
- Skipped stops
- Moved stops
- Percentage based on active stops

### Trip Progress

Display:

- Completed days
- Current day
- Completed stops across all days
- Remaining active stops

Progress calculations must exclude stops removed from the active itinerary.

Skipped stops must remain visible in summary statistics.

---

## 11. Current Stop

The Current Stop card is the primary actionable element in Trip Execution Mode.

It should display:

- Destination name
- Image
- Category
- Planned time
- Estimated visit duration
- Short description
- Top must-do activity
- Rating
- Dog-friendly status
- Kid-friendly status
- Older-adult suitability
- Accessibility status
- Parking and restroom indicators where available

### Primary Actions

- View Destination
- Complete Stop
- Skip

### Secondary Actions

- Move to Another Day
- View on Overview Map
- Write or edit review
- Restore stop, when skipped

P0 must not display a functional `Navigate` action.

---

## 12. Upcoming Stops

Upcoming stops must appear in itinerary order.

Each row should display:

- Sequence number
- Stop name
- Planned time
- Estimated duration
- Status
- Key suitability badges
- User-modified indicator

Users may:

- Open stop details
- Skip a stop
- Move a stop to another day
- Restore a skipped stop

Manual drag-and-drop reordering is not required for the initial P0 release unless explicitly approved.

---

## 13. Completing a Stop

When the user selects `Complete Stop`, the app must:

1. Mark the stop as completed.
2. Record the local completion timestamp.
3. Update day progress.
4. Update trip progress.
5. Select the next unfinished active stop.
6. Save the new state locally.
7. Provide subtle completion feedback.

### Optional Review Prompt

After completion, the app may display a lightweight prompt:

```text
How was Lake Crescent?

[Not Now] [Rate Stop]
```

The review prompt must not block progress.

### Completion Feedback

Feedback may include:

- Checkmark animation
- Haptic feedback
- Progress update
- Mascot celebration for major milestones

Animations must respect Reduce Motion.

---

## 14. Skipping a Stop

A skipped stop must not disappear without context.

When selecting `Skip`, the user should be offered:

- Move to Another Day
- Keep as Skipped
- Remove From Active Plan
- Cancel

An optional reason may be recorded:

- Not enough time
- Weather
- Closed
- Too crowded
- Travel-group needs
- No longer interested
- Other

Skip reasons remain local in P0.

---

## 15. Rescheduling a Stop

P0 supports manual stop movement without AI or route optimization.

### Rescheduling Flow

```text
Select Stop
    ↓
Move to Another Day
    ↓
Choose Destination Day
    ↓
Preview Placement
    ↓
Confirm
```

### P0 Placement Rule

By default, the moved stop should be placed:

- At the end of the selected day, or
- At a user-selected position when simple positioning is implemented

The UI must not claim that the new placement is geographically optimized.

### Rescheduling Requirements

- The original day and sequence must remain stored.
- The modified itinerary must persist locally.
- Moved stops must show a modified indicator.
- The user must be able to undo the latest change.
- The user must be able to restore the original itinerary.

---

## 16. Along-the-Route Highlights

Route highlights are optional locations between or near planned stops.

Examples:

- Scenic overlooks
- Photo spots
- Cafés
- Restaurants
- Dog-friendly stops
- Restrooms
- Gas stations
- Picnic areas
- Trailheads
- Local attractions

### P0 Behavior

Route highlights are informational.

Users may:

- View the highlight on the map
- Open a preview
- Read details
- Mark the highlight as viewed
- Mark a traveler tip as helpful

P0 does not require:

- Adding highlights to the active itinerary
- Navigating to highlights
- Live detour calculation
- Real-time distance measurement

### Popular Highlight Presentation

When popularity data exists, the UI may show:

- Small image thumbnail
- Popular Stop label
- Imported rating
- Imported review count

Imported popularity data must not be presented as live data.

---

## 17. Destination Details During Execution

Opening a destination from Trip Execution Mode must preserve execution context.

When the user returns, the app should restore:

- Selected day
- Current stop
- Map state where practical
- Scroll position where practical
- Trip progress

Destination Details may include:

- Description
- History
- Must-do activities
- Highlights
- Images
- Practical information
- Suitability
- Reviews
- Traveler tips
- Map reference

---

## 18. Reviews During Execution

Users may review:

- Individual destinations
- The full trip

Destination reviews may include:

- Overall rating
- Written review
- Dog friendliness
- Kid friendliness
- Older-adult suitability
- Accessibility
- Crowd level
- Visit date

Trip reviews may include:

- Overall trip rating
- Itinerary quality
- Trip pace
- Route quality
- Travel-group suitability
- Favorite destination
- Written summary

All user-created reviews remain local in P0.

Imported community reviews and traveler tips are read-only.

---

## 19. Social Elements in Trip Execution

P0 may include lightweight, social-ready experiences.

### Included

- Imported traveler tips
- Imported community ratings
- Popular-with-travelers labels
- Local helpful votes
- Share Trip action
- Share Completed Journey action
- Stickers and achievements

### Excluded

- Accounts
- Public posting
- Live social feed
- Following
- Comments
- Messaging
- Real leaderboards
- Public profiles

The app must clearly distinguish:

- Local user content
- Imported community content
- Prototype or future-only content

---

## 20. End-of-Day Experience

When no active stops remain for the day, show an End-of-Day Summary.

Display:

- Stops completed
- Stops skipped
- Stops moved
- Planned distance
- Estimated activity time
- Reviews submitted
- Favorite-stop prompt
- Earned sticker, when applicable

### Actions

- Continue to Next Day
- Review Missed Stops
- Move Skipped Stops
- Review Destination
- Return to Trip Overview

Do not present planned distance as actual distance traveled.

---

## 21. Trip Completion Experience

When the final active stop is completed, show the Trip Completion Summary.

Display:

- Trip name
- Days completed
- Destinations completed
- Destinations skipped
- Planned route distance
- Reviews submitted
- Favorite destination
- New sticker
- Short travel summary

### Actions

- Review Trip
- Share Journey
- View Completed Route
- Return Home

### Community Comparison

P0 must not generate fake rankings.

If community comparison is represented, it must be:

- Clearly labeled as a prototype, or
- Shown as a disabled future feature

---

## 22. Pause and Resume

Trip progress must persist when:

- The app is closed
- The device restarts
- The user switches trips
- The user returns to Home

Resuming a trip must restore:

- Active day
- Current stop
- Completion states
- Skipped states
- Moved stops
- User reviews
- Selected itinerary modifications

---

## 23. Restore Original Plan

Users must be able to restore:

- The selected day, or
- The entire trip

Restoring the itinerary must reset:

- Stop placement
- User ordering modifications
- Skipped state when explicitly included in restoration

It should not automatically delete:

- Reviews
- Completed-stop history
- Trip review

The confirmation screen must explain exactly what will change.

---

## 24. Offline Behavior

Trip Execution must work without internet after the trip is available locally.

Offline functionality includes:

- Trip data
- Destination information
- Map reference rendering using available map data
- Progress tracking
- Reviews
- Traveler tips
- Preferences
- Local images
- Sample trip

P0 does not include downloadable offline navigation maps.

If the base map cannot load offline, the app must still provide:

- The journey timeline
- Stop list
- Coordinates
- Destination order
- Route-highlight list

The core execution experience must not depend entirely on map availability.

---

## 25. Accessibility Requirements

Trip Execution must support:

- Dynamic Type
- VoiceOver
- Minimum 44 × 44 point tap targets
- Reduce Motion
- Sufficient contrast
- Text and icon status indicators
- Accessible non-map route list

VoiceOver labels should include status.

Example:

> Stop two, Lake Crescent, current stop, planned for 10 AM, estimated duration one hour and thirty minutes.

---

## 26. Error and Edge Cases

The app must handle:

### No Stops for Selected Day

Show:

- Empty-day explanation
- Option to select another day
- Option to move a skipped stop into the day

### Missing Coordinates

The location should remain available in the timeline but not be shown on the map.

A valid P0 import should normally reject missing required map references.

### Missing Images

Use a category-based fallback image or illustration.

### Persistence Failure

Show:

- Clear error
- Retry action
- Avoid falsely confirming completion

### All Stops Skipped

Show End-of-Day Summary with an explanation and rescheduling options.

### Duplicate Completion

Do not create multiple completion records for the same stop.

---

## 27. Analytics Events for Future Use

P0 does not require a remote analytics platform, but event names may be documented for future instrumentation.

Suggested events:

- `trip_started`
- `trip_resumed`
- `day_selected`
- `map_pin_opened`
- `destination_opened`
- `stop_completed`
- `stop_skipped`
- `stop_moved`
- `stop_restored`
- `route_highlight_opened`
- `traveler_tip_helpful`
- `day_completed`
- `trip_completed`
- `trip_shared`
- `destination_review_saved`
- `trip_review_saved`

No analytics SDK is required in P0.

---

## 28. P1 Evolution

In P1, Trip Execution Mode will evolve into an in-app Journey Mode.

P1 may add:

- Live location
- Turn-by-turn navigation
- Actual road route
- Offline map downloads
- Live ETA
- Route recalculation
- GPS-triggered audio tours
- Background navigation
- Arrival detection
- Stops shown along the active route

The P0 information architecture should remain recognizable when these capabilities are added.

---

## 29. P0 Acceptance Criteria

Trip Execution is complete when a user can:

- Start a trip.
- Resume a trip.
- View the current day.
- Switch between trip days.
- View all planned stops on a map.
- View every stop’s map reference.
- View route highlights.
- Understand the current stop.
- Understand what comes next.
- Complete a stop.
- Skip a stop.
- Move a stop to another day.
- Restore the original itinerary.
- View day progress.
- View trip progress.
- Complete a day.
- Complete a trip.
- Leave local destination and trip reviews.
- Resume progress after restarting the app.
- Use the core itinerary when internet is unavailable.

No live navigation or built-in AI is required.
