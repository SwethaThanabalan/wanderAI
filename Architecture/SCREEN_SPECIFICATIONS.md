# wanderAI Screen Specifications

**Version:** 0.1.0  
**Status:** Alpha — P0  
**Platform:** iOS 17+

---

## Purpose

This document defines the screen-level requirements for wanderAI P0.

Each screen specification includes:

- Purpose
- Entry points
- Content
- Primary actions
- Secondary actions
- States
- Error handling
- Accessibility
- Future considerations

The implementation must remain within the boundaries defined in `P0_SCOPE.md`.

---

# Global Screen Requirements

All screens should:

- Use native SwiftUI patterns.
- Support Dynamic Type.
- Support VoiceOver.
- Support light and dark mode where practical.
- Provide a minimum 44 × 44 point interactive target.
- Avoid communicating state through color alone.
- Keep primary actions clear and visually dominant.
- Preserve user progress when navigating backward.
- Work offline after a trip has been imported.
- Use reusable components rather than screen-specific duplicates.

---

# 1. Launch Screen

## Purpose

Provide a brief branded transition while the app initializes local data.

## Content

- wanderAI logo
- Brown toy poodle mascot
- Minimal background
- Optional short brand phrase

## Behavior

- Display only while initialization is required.
- Avoid artificial delays.
- Continue automatically to Home.

## Error State

If initialization fails:

- Continue to a recoverable app state where possible.
- Display a clear retry option.

## Accessibility

- Logo must have an accessibility label.
- Decorative mascot elements should be hidden from VoiceOver where appropriate.

---

# 2. Home Screen

## Purpose

Allow users to access, import, manage, and resume trips.

## Entry Points

- Application launch
- Return from Trip Overview
- Return from Trip Completion

## Layout

### Navigation Bar

- wanderAI title or logo
- Preferences action
- Import action

### Main Content

- In-progress trip section, when applicable
- Upcoming or unstarted trips
- Completed trips
- Floating or prominent import action when no trips exist

### Trip Card

Display:

- Cover image
- Trip name
- Primary destination
- Date range
- Number of days
- Progress state
- Current day where applicable
- `Start Trip`, `Resume Trip`, or `View Trip`

## Primary Actions

- Open trip
- Resume active trip
- Import JSON

## Secondary Actions

- Delete trip
- Restore sample trip
- Export preferences
- View completed trip

## Empty State

Display:

- Mascot illustration
- Explanation that no trips are loaded
- `Load Sample Trip`
- `Import Trip JSON`

Suggested copy:

> Your next adventure starts here.

## Loading State

Use skeleton cards or a subtle progress indicator.

## Error State

Show:

- Short explanation
- Retry action
- Sample trip fallback where available

## Accessibility

Trip cards should expose a concise combined VoiceOver description.

Example:

> Olympic National Park Adventure, five days, not started.

---

# 3. Import Trip Screen or Sheet

## Purpose

Help users import a valid trip JSON file.

## Entry Points

- Home navigation bar
- Home empty state
- Trip-management menu

## Content

- Explanation of supported file type
- Import button
- Schema version information
- Optional link to JSON requirements
- Recent import result where relevant

## Primary Action

- Choose JSON File

## Import Success State

Display:

- Trip name
- Number of days
- Number of stops
- Confirmation message
- `Open Trip`

## Import Error State

Display:

- Human-readable issue summary
- Affected field where available
- Supported schema version
- `Choose Another File`

## Accessibility

Error summaries must be announced automatically by VoiceOver.

---

# 4. Trip Overview Screen

## Purpose

Help the user understand the complete trip before entering execution mode.

## Entry Points

- Home trip card
- Import success
- Trip completion history

## Layout

### Hero Section

Display:

- Cover image
- Trip name
- Destination
- Date range
- Number of days
- Travel group suitability

### Summary Section

Display:

- Trip description
- Top highlights
- Planned distance, when supplied
- Estimated total experience time
- Trip rating, when available

### Interactive Map

Display:

- Planned stops
- Numbered pins
- Start and end pins
- Route highlights
- Simple connecting line
- Day filtering

### Daily Itinerary

Display a section for each day containing:

- Day title
- Route summary
- Number of destinations
- Estimated time
- Destination previews

### Sticky Primary Action

Use:

- `Start Trip`
- `Resume Trip`
- `View Completed Trip`

## Primary Actions

- Start or resume trip
- Select day
- Open destination

## Secondary Actions

- Open map pin preview
- View route highlight
- Delete trip
- Restore original itinerary
- Review completed trip

## Map Behavior

- Fit the selected route within the viewport.
- Selecting a day filters the visible pins.
- Selecting `All Days` shows the full trip.
- Tapping a pin opens a preview sheet.
- P0 map does not show current GPS position.
- P0 map does not offer turn-by-turn navigation.

## Empty or Incomplete Data

When optional content is unavailable:

- Hide empty sections.
- Do not show placeholder values such as `N/A`.
- Preserve the core itinerary view.

## Accessibility

Provide a non-map itinerary alternative containing the same destinations and order.

---

# 5. Map Location Preview Sheet

## Purpose

Provide fast information without removing the user from the route context.

## Entry Point

- Tap a destination or route-highlight pin

## Presentation

- Medium-height bottom sheet
- Expandable where appropriate
- Map remains visible behind it

## Content

Display:

- Image or category icon
- Name
- Pin type
- Rating
- Planned time
- Estimated duration
- One-line description
- Must-do summary
- Suitability badges
- Detour estimate for route highlights

## Primary Action

- Open Details

## Contextual Actions

Depending on location type:

- Mark Complete
- Skip
- Restore Stop
- Add to Day, for optional highlights in future
- Dismiss

P0 should not display a functional `Navigate` button.

---

# 6. Trip Execution Screen

## Purpose

Serve as the primary companion interface while users follow an itinerary.

## Entry Points

- `Start Trip`
- `Resume Trip`
- Continue from end-of-day summary

## Layout

### Header

Display:

- Trip name
- Day number and title
- Trip-level progress
- Day selector or day-switch action

### Map Overview

Display:

- Current day's planned stops
- Numbered destination pins
- Route highlights
- Simple route line
- Completed, current, upcoming, skipped, and moved states

### Progress Section

Display:

- Day progress
- Trip progress
- Stops completed
- Stops remaining

### Current Stop Card

Display:

- Destination name
- Image
- Planned time
- Estimated duration
- Must-do activity
- Suitability badges
- Completion state

### Upcoming Stops

Display stops in current order with:

- Sequence
- Time
- Duration
- Status
- User-modified indicator where relevant

### Along the Route

Display selected route highlights such as:

- Scenic viewpoints
- Photo spots
- Cafés
- Dog-friendly stops
- Restrooms
- Gas

### Persistent Action Area

For current stop:

- `View Destination`
- `Complete Stop`
- `Skip`

## Primary Actions

- Complete current stop
- Open current destination
- Skip or reschedule a stop

## Secondary Actions

- Tap map pin
- Open route highlight
- Switch day
- Pause trip
- View trip overview

## Status Definitions

### Planned

Not yet reached in the itinerary.

### Current

The next active stop.

### Completed

Finished by the user.

### Skipped

Intentionally not completed.

### Moved

Rescheduled to another day.

## Map Visual Hierarchy

- Current stop: strongest emphasis
- Planned destinations: numbered primary pins
- Completed stops: completed indicator
- Skipped stops: visually distinct with text or icon
- Route highlights: smaller secondary pins

## P0 Limitations

The screen must not imply that:

- The map reflects live location.
- The route follows actual roads.
- ETA values are live.
- Traffic is considered.
- Highlight proximity is calculated in real time.

## Accessibility

The complete stop sequence must be available as an accessible list.

Map annotations must have meaningful labels.

---

# 7. Day Selector

## Purpose

Allow users to move between days in a multi-day trip.

## Presentation

Use one of:

- Horizontal day tabs
- Compact day carousel
- Bottom sheet selector

## Content

Each day should display:

- Day number
- Short title
- Completion status
- Number of unfinished stops

## Behavior

Selecting another day updates:

- Map
- Timeline
- Progress
- Current stop context

The app must distinguish the actively selected day from the actual current execution day.

---

# 8. Destination Details Screen

## Purpose

Give the traveler everything needed to understand and experience a destination.

## Entry Points

- Trip Overview
- Trip Execution
- Map location preview
- Review history

## Layout

### Hero

Display:

- Hero image
- Destination name
- Location
- Rating
- Category

### Quick Facts

Display:

- Planned visit time
- Estimated duration
- Parking
- Restrooms
- Cost or fee
- Hours
- Seasonality

### Suitability

Display:

- Dog friendly
- Kid friendly
- Older-adult friendly
- Wheelchair accessibility
- Stroller suitability
- Difficulty

### Description

A concise explanation of the destination.

### History

Historical or cultural context.

### Must Do

A prioritized activity list.

### Highlights

Specific viewpoints, activities, trails, food, or experiences.

### Map Reference

Display a contextual map with a pin.

P0 must not present turn-by-turn navigation.

### Reviews

Display:

- User's review
- Imported or sample reviews where provided
- Overall rating
- Category ratings

## Primary Actions

Depending on context:

- Complete Stop
- Write Review
- Edit Review

## Secondary Actions

- Skip Stop
- Move to Another Day
- Return to Map

## Missing Information

Hide optional sections when no content exists.

Do not fabricate information.

## Accessibility

Images need useful alternative descriptions where they communicate content.

Long content should remain readable at large Dynamic Type sizes.

---

# 9. Route Highlight Details Screen or Sheet

## Purpose

Explain why an optional location along the route may be worth seeing.

## Content

Display:

- Name
- Image or category icon
- Category
- Short description
- Coordinates
- Estimated detour
- Popularity indicator
- Suitability
- Practical information

## Popularity Presentation

Popular highlights may use:

- A small thumbnail
- `Popular Stop` label
- Higher visual emphasis

Popularity must not be inferred or fabricated if it is absent from the imported data.

## Primary Action

- Return to Route

Future releases may add:

- Add to Itinerary
- Navigate
- Save
- Community Reviews

---

# 10. Skip and Reschedule Sheet

## Purpose

Help users adapt an itinerary without losing track of a stop.

## Entry Points

- Current Stop card
- Upcoming stop menu
- Destination Details

## Content

Prompt:

> What would you like to do with this stop?

Options:

- Move to Another Day
- Keep as Skipped
- Remove From Active Plan
- Cancel

## Move-to-Day State

Display:

- Available days
- Day titles
- Number of planned stops
- Proposed placement

## Confirmation

Summarize the change before applying it.

Example:

> Marymere Falls will be moved to the end of Day 2.

## Undo

After a change, provide a temporary undo action.

---

# 11. End-of-Day Summary Screen

## Purpose

Close the day, review progress, and prepare for the next day.

## Entry Point

- Completion of final active stop
- Manual `End Day` action

## Content

Display:

- Day title
- Stops completed
- Stops skipped
- Stops moved
- Planned distance
- Estimated activity time
- Favorite stop prompt
- Sticker or lightweight celebration where earned

## Primary Action

- Continue to Next Day

## Secondary Actions

- Review missed stops
- Move skipped stops
- Review a destination
- Return to Trip Overview

## Accessibility

Celebration animation should respect Reduce Motion.

---

# 12. Trip Completion Summary Screen

## Purpose

Celebrate the full journey and help the user reflect on the experience.

## Content

Display:

- Completed trip name
- Days completed
- Destinations completed
- Destinations skipped
- Planned distance
- Reviews submitted
- Favorite destination
- Earned sticker
- Short travel summary

## Primary Action

- Review Trip

## Secondary Actions

- View Completed Route
- Return Home
- Edit Favorite Destination

## Community Comparison

Do not show real relative ranking in P0 unless real data exists.

A future placeholder may be labeled:

> Community comparisons are coming in a future release.

---

# 13. Destination Review Screen

## Purpose

Capture structured and written feedback about a destination.

## Fields

- Overall rating
- Review text
- Dog friendliness
- Kid friendliness
- Older-adult suitability
- Accessibility
- Crowd level
- Visit date

## Primary Action

- Save Review

## Secondary Action

- Cancel

## Validation

- Overall rating may be required.
- Written text may be optional.
- The app should warn before discarding unsaved changes.

## Edit State

Existing reviews should be editable and deletable.

---

# 14. Trip Review Screen

## Purpose

Capture feedback about the complete itinerary and experience.

## Fields

- Overall rating
- Itinerary quality
- Trip pace
- Route quality
- Travel-group suitability
- Favorite destination
- Written summary

## Primary Action

- Save Trip Review

## Secondary Action

- Cancel

---

# 15. Preferences Screen

## Purpose

Capture the preferences that will be exported for use with an external LLM during P0.

## Sections

### Traveler Composition

- Solo
- Couple
- Family
- Friends
- Older adults
- Children
- Pets

### Interests

- National parks
- Scenic drives
- Hiking
- Photography
- History
- Food
- Local culture
- Wildlife
- Beaches
- Cities

### Travel Pace

- Relaxed
- Balanced
- Active

### Mobility and Accessibility

- Minimal walking
- Avoid stairs
- Wheelchair access
- Frequent seating
- Frequent restroom stops

### Pet Requirements

- Traveling with dog
- Dog-friendly lodging
- Dog-friendly trails
- Dog parks
- Leash restrictions

### Food Preferences

- Dietary restrictions
- Cuisine preferences
- Avoided foods
- Preferred dining style

### Driving Preferences

- Maximum daily driving time
- Scenic route preference
- Avoid tolls
- Avoid ferries
- Comfort with mountain roads

### Accommodation

- Hotel
- Rental
- Camping
- Cabin
- Flexible

## Primary Action

- Save Preferences

## Secondary Action

- Export JSON

## Empty State

Provide sensible defaults without assuming personal needs.

---

# 16. Preference Export Preview

## Purpose

Allow users to inspect the structured preference data before sharing it.

## Content

Display:

- Human-readable summary
- JSON file name
- Schema version
- Privacy note

## Primary Action

- Export JSON

## Secondary Actions

- Edit Preferences
- Cancel

## Export Method

Use the native iOS share sheet.

---

# 17. Delete Confirmation Dialog

## Purpose

Prevent accidental trip deletion.

## Content

Display:

- Trip name
- Explanation that local progress and reviews may be removed
- Clear destructive action

## Actions

- Delete Trip
- Cancel

---

# 18. Error State Components

Create reusable error components for:

- Trip loading failure
- JSON import failure
- Unsupported version
- Missing resource
- Local persistence failure
- Preference export failure

Each error should include:

- Clear title
- Brief explanation
- Recovery action
- Technical details only when useful for development

---

# 19. Reusable P0 Components

The P0 interface should establish reusable versions of:

- Trip Card
- Destination Card
- Current Stop Card
- Upcoming Stop Row
- Route Highlight Card
- Suitability Badge
- Progress Indicator
- Map Pin
- Location Preview Sheet
- Empty State
- Error State
- Rating Control
- Primary Button
- Secondary Button
- Sticker Card

These are reusable UI components, not a full formal design system.

---

# 20. Future Screen Extensions

The following screens are future-only and must not be implemented in P0:

## P1

- Live Navigation
- Offline Map Download
- Audio Tour Player
- Arrival Screen
- Route Recalculation
- Navigation Settings

## P2

- AI Planning Chat
- Generated Trip Review
- Recommendation Comparison
- Dynamic Itinerary Adjustment

## P3

- Community Feed
- Traveler Profile
- Shared Trip
- Messaging
- Social Rankings
