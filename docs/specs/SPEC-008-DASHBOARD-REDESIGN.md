# SPEC-008: Dashboard Redesign — Command Center Layout

## Reference
Screenshot from Eric (2026-02-06) showing the target dashboard layout.

## Current State
- Basic dashboard with glass cards, simple widgets
- Weather, Quick Actions, Tasks (list), Cost Tracker (basic), Agent Status, Notifications, System Status, Recent Sessions

## Target Layout (from screenshot)

### Header
- "Studio Overview" badge (top-left)
- "OpenClaw Dashboard" title + subtitle "Design, orchestrate, and monitor AI agent systems from a single command center."
- "Reset Layout" button (resets to default grid)
- "+ Add Widget" button (opens widget picker)

### Widget Grid (3-column responsive)

#### Row 1 (3 widgets, size SM)
1. **Weather** — Location, temp °F, condition + humidity, 3-day forecast with emoji + highs
2. **Quick Actions** — 2x3 grid: New Chat, Spawn Agent, Open Terminal, Browse Skills, Search, Settings
3. **Time & Date** — Timezone label, large live clock (HH:MM:SS), full date

#### Row 2 (2 widgets, size MD)
4. **Usage Meter** — Donut chart (% used), per-model token bars (color-coded), daily cost total
5. **Tasks** — 4-column kanban: Backlog, In Progress, Review, Done. Cards with title, assignee avatar, priority badge

#### Row 3 (2 widgets, size MD)
6. **Active Agents** — List of running agents: name/task, model badge, status bar (progress), elapsed time
7. **Cost Tracker** — Daily/Weekly/Monthly columns with dollar amounts, % change badges (green/red), sparkline chart

### Widget Chrome (every widget)
- Header: icon + title + "Drag" handle + settings gear + close X
- Footer: "Widget N • size SM/MD/LG" label
- Draggable (react-grid-layout or similar)
- Configurable (gear opens settings)
- Dismissible (X removes from grid)

### Design System
- Light background (#fafaf9 or similar warm white)
- Rounded cards with subtle border (#e5e5e5)
- Orange accent color for progress bars, active states
- Clean sans-serif typography
- Consistent spacing and padding

## Implementation Plan

### Phase A: Widget Components (parallel Codex agents)
1. **Time & Date widget** — New component with live clock
2. **Usage Meter widget upgrade** — Donut chart + per-model bars + cost
3. **Tasks widget → Kanban** — 4-column layout with cards
4. **Active Agents widget upgrade** — Agent list with progress bars + timers
5. **Cost Tracker widget upgrade** — Daily/Weekly/Monthly + sparkline

### Phase B: Dashboard Shell
6. **Widget chrome wrapper** — Drag handle, gear, close X, footer label
7. **Header bar** — Reset Layout + Add Widget buttons
8. **Grid layout** — react-grid-layout for drag-and-drop repositioning
9. **Widget picker modal** — Add Widget opens modal with available widgets
10. **Layout persistence** — Save grid layout to localStorage

## Data Sources
- Weather: wttr.in API (existing)
- Usage: /api/provider-usage + /api/session-status
- Tasks: localStorage + optional Gateway integration
- Agents: /api/sessions (filter active)
- Cost: /api/provider-usage (aggregate by day/week/month)
- Time: browser Date API
