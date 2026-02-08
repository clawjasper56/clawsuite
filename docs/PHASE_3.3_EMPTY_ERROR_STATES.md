# Phase 3.3 — Empty & Error State Polish

**Priority:** P0 UX  
**Branch:** phase3.3-empty-error-states  
**Base:** v2.0.4

## Goal

Polish all empty and error states with consistent, helpful UX:
- Plain language explanations
- Single clear action
- Friendly icons
- Reuse existing components

## Constraints

- UX-only changes (no new backend, no new API routes)
- Reuse existing glass card patterns
- No new dependencies

## Areas to Polish

### 1. Activity Log (Currently: "No activity events yet.")

**Empty State:**
```
Icon: 📋 Activity
Title: "No events recorded"
Description: "Activity will appear here as you use the app"
```

**Disconnected State:**
```
Icon: 🔴 Disconnected
Title: "Stream disconnected"
Description: "Check your Gateway connection"
Action: "Reconnect" button
```

### 2. Search Modal Empty Results

**Currently:** Shows nothing when no results  
**Improved:**
```
Icon: 🔍 Search
Title: "No results found"
Description: "Try a different search term"
```

### 3. Skills Screen Loading

**Currently:** Minimal loading state  
**Improved:** Add skeleton loaders for skill cards

### 4. Terminal Empty State

Check if terminal has an empty state when no sessions exist.

### 5. Sessions List Error (sidebar-sessions.tsx)

**Current:** "Failed to load sessions." + error text + Retry  
**Already good** — keep as-is

### 6. File Explorer

**Already improved in Phase 2.6** — keep as-is

## Files to Change

- `src/screens/activity/activity-screen.tsx` — Add empty + disconnected states
- `src/components/search/search-modal.tsx` — Add empty results state
- `src/screens/skills/skills-screen.tsx` — Add skeleton loaders
- `src/components/empty-state.tsx` — NEW: Reusable empty state component
- `docs/QA/phase3.3-empty-error-states_TESTPLAN.md` — Test steps
- `docs/QA/phase3.3-empty-error-states_RESULTS.md` — Test results

## Reusable Empty State Component

Create a flexible component:

```tsx
<EmptyState
  icon={ActivityIcon}
  title="No events recorded"
  description="Activity will appear here as you use the app"
  action={
    <Button onClick={handleRetry}>Retry</Button>
  }
/>
```

## Manual Test Plan

### T1: Activity Log Empty
1. Clear activity events (or use fresh session)
2. Navigate to /activity
3. **Expected:** Friendly empty state with icon + description

### T2: Activity Log Disconnected
1. Disconnect Gateway
2. Navigate to /activity
3. **Expected:** Disconnected state with reconnect action

### T3: Search No Results
1. Open search (Cmd+K)
2. Type gibberish
3. **Expected:** "No results found" message

### T4: Skills Loading
1. Refresh skills page
2. **Expected:** Skeleton loaders appear briefly

## Security

No security concerns — UX-only changes, no data handling.

## Risks

- **None:** Pure UI changes
- **Regression:** Ensure existing states still work (loading, error)
