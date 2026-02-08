# Phase 3.3 — Empty & Error States Test Plan

## Prerequisites
- App running on localhost
- Gateway connected

## Test Cases

### T1: Activity Log - Empty State
1. Navigate to `/activity` with no events
2. **Expected:** EmptyState component showing:
   - Icon: Activity icon
   - Title: "No events recorded"
   - Description: "Activity will appear here as you use the app"

### T2: Activity Log - Disconnected State
1. Stop Gateway
2. Navigate to `/activity`
3. **Expected:** EmptyState showing:
   - Icon: WiFi disconnected icon
   - Title: "Stream disconnected"
   - Description: "Check your Gateway connection and refresh"

### T3: Search - Empty Results
1. Open search (Cmd+K)
2. Type gibberish that matches nothing (e.g., "xyzabc123")
3. **Expected:** EmptyState showing:
   - Icon: Search icon
   - Title: "No results found"
   - Description: "Try a different search term"

### T4: Skills - Loading Skeleton
1. Navigate to `/skills`
2. Observe brief loading state
3. **Expected:** Skeleton loaders appear for skill cards

### T5: Skills - Empty Filters
1. Navigate to `/skills`
2. Search for gibberish
3. **Expected:** Friendly empty state:
   - "No skills found"
   - "Try adjusting your filters or search term"

### T6: Sessions Sidebar Error (Regression)
1. Ensure existing error state still works
2. **Expected:** "Failed to load sessions" + error text + Retry button

### T7: File Explorer Empty (Regression)
1. Check file explorer empty state (from Phase 2.6)
2. **Expected:** Still shows "No workspace selected" state

## Visual Checks

- All empty states use consistent icon size (24px) and spacing
- Icons are in bordered circles with primary background
- Text is properly sized (title: sm font-medium, description: xs)
- Actions are centered and properly styled
