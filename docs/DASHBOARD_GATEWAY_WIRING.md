# Dashboard Gateway Wiring Map

**Branch:** `phase-dashboard-gateway-wiring`  
**Created:** 2026-02-10  
**Scope:** Wire all dashboard widgets to real Gateway data. No new features.

---

## Gateway RPC Methods Used

| RPC Method | Route | Purpose |
|-----------|-------|---------|
| `connect` | Internal (handshake) | WebSocket auth |
| `sessions.list` | `GET /api/sessions` | List all sessions with metadata |
| `sessions.usage` | `GET /api/usage` | All-time token usage by provider |
| `usage.status` | `GET /api/usage` (secondary) | Provider quota windows + percent used |
| `usage.cost` | `GET /api/cost` | Billing period daily spend timeseries |
| `session.status` | `GET /api/session-status` | **Rich status**: default model, session details, agent info, context % |
| `models.list` | `GET /api/models` | Available models filtered by config |
| SSE via activity-stream | `GET /api/events` | Real-time gateway events |

---

## Widget Wiring Table

| Widget | Component | Current Source | Gateway Truth Source | Route | Field Mapping | Fallback State | Status |
|--------|-----------|---------------|---------------------|-------|---------------|----------------|--------|
| **Weather** | `weather-widget.tsx` | `wttr.in` external API | N/A (not gateway data) | N/A | N/A | "Weather unavailable" | ✅ Correct — external data |
| **Quick Actions** | `quick-actions-widget.tsx` | Static config | N/A (navigation only) | N/A | N/A | N/A | ✅ Correct |
| **Time & Date** | `time-date-widget.tsx` | `Date` + `Intl` | N/A (client-side) | N/A | N/A | N/A | ✅ Correct |
| **Usage Meter** | `usage-meter-widget.tsx` | `GET /api/usage` → `sessions.usage` + `usage.status` | ✅ Already wired | `GET /api/usage` | `usage.total.cost` → total cost, `usage.byProvider.*` → per-provider breakdown, `usage.total.percentUsed` → donut | "No usage data" / "Unavailable on this Gateway version" | ✅ Correct |
| **Tasks** | `tasks-widget.tsx` | localStorage + seed data | N/A (demo widget) | N/A | N/A | Demo badge shown | ✅ Correct |
| **Agent Status** | `agent-status-widget.tsx` | `GET /api/sessions` → `sessions.list` | ✅ Already wired | `GET /api/sessions` | `sessions[].model`, `sessions[].updatedAt`, `sessions[].totalTokens/contextTokens` → progress % | "No active agent sessions" | ✅ Correct |
| **Cost Tracker** | `cost-tracker-widget.tsx` | `GET /api/cost` → `usage.cost` | ✅ Already wired | `GET /api/cost` | `cost.total.amount` → period spend, `cost.timeseries[]` → sparkline + daily/weekly/monthly metrics | "No cost history" / "Unavailable" | ✅ Correct |
| **Recent Sessions** | `recent-sessions-widget.tsx` | Props from parent ← `GET /api/sessions` | ✅ Already wired | `GET /api/sessions` | `sessions[].friendlyId`, `.label/.title/.derivedTitle`, `.lastMessage`, `.updatedAt` | Fallback: 2 placeholder sessions | ✅ Correct |
| **System Status** | `system-status-widget.tsx` | Props from parent: gateway ping (real) + model (HARDCODED "sonnet") + uptime (HARDCODED 0) | **Needs wiring** → `GET /api/session-status` | `GET /api/session-status` | `payload.sessions.defaults.model` → current model, `payload.sessions.recent[0].age` → uptime proxy, `payload.sessions.count` → session count | "—" for missing fields | ❌ **P0 Fix needed** |
| **Notifications** | `notifications-widget.tsx` | `GET /api/sessions` → `sessions.list` | ✅ Already wired | `GET /api/sessions` | Derives lifecycle events from session timestamps | "No recent activity" | ✅ Correct |
| **Activity Log** | `activity-log-widget.tsx` | SSE `GET /api/events` → activity-stream | ✅ Already wired | `GET /api/events` | Real-time gateway events | "Gateway disconnected" + Retry | ✅ Correct (after previous fix) |

### Header Buttons

| Element | Current | Desired | Status |
|---------|---------|---------|--------|
| Reset Layout | Disabled + tooltip | Same (no layout state yet) | ✅ Done (previous PR) |
| Add Widget | Disabled + tooltip | Same (no widget picker yet) | ✅ Done (previous PR) |

---

## P0 Wiring Fixes Required

### Fix 1: System Status — Wire to `/api/session-status`

**Problem:** `currentModel` hardcoded to `"sonnet"`, `uptimeSeconds` hardcoded to `0`.

**Solution:** The `GET /api/session-status` endpoint already exists and returns rich data:
```json
{
  "payload": {
    "sessions": {
      "defaults": { "model": "claude-sonnet-4-5", "contextTokens": 500000 },
      "count": 7,
      "recent": [{ "model": "claude-opus-4-6", "age": 85129, "percentUsed": 20 }]
    }
  }
}
```

**Field mapping:**
- `currentModel` ← `payload.sessions.defaults.model` (friendly-formatted)
- `uptimeSeconds` ← derive from main session's `age` field (ms → seconds), or hide if unavailable
- `sessionCount` ← `payload.sessions.count`
- Gateway connected ← existing `/api/ping` check (keep as-is)

**Implementation:**
1. In `dashboard-screen.tsx`: add `useQuery` for `/api/session-status`
2. Map fields into `SystemStatus` type
3. Pass to `SystemStatusWidget`
4. Widget already handles display — just needs real data

### Fix 2: System Status Widget — Model Name Formatting

**Problem:** Raw model ID like `claude-sonnet-4-5` is not user-friendly.

**Solution:** Format to short name: `claude-sonnet-4-5` → `Sonnet 4.5`, `claude-opus-4-6` → `Opus 4.6`, etc.

---

## Already Correctly Wired (No Changes Needed)

| Widget | Gateway RPC | Evidence |
|--------|------------|---------|
| Usage Meter | `sessions.usage` + `usage.status` | Server route calls `gatewayRpc('sessions.usage', ...)` and `gatewayRpc('usage.status', {})` |
| Cost Tracker | `usage.cost` | Server route calls `gatewayRpc('usage.cost', { days: 30 })` |
| Agent Status | `sessions.list` | Server route calls `gatewayRpc('sessions.list', { limit: 50, ... })` |
| Recent Sessions | `sessions.list` (same) | Reuses sessions query from parent |
| Notifications | `sessions.list` (same) | Own fetch to `/api/sessions` |
| Activity Log | SSE via activity-stream | `activity-stream.ts` manages gateway event forwarding |

---

## Risks + Fallback Behavior

| Scenario | Affected Widgets | Fallback |
|----------|-----------------|----------|
| Gateway offline | All API-powered widgets | Usage/Cost: "Unavailable" cards. Agents/Sessions: empty states. System Status: "Disconnected". Activity Log: "Gateway disconnected" + Retry. |
| `session.status` RPC unavailable (older gateway) | System Status | Model shows "—", uptime shows "—", session count from sessions.list instead |
| `usage.cost` unavailable | Cost Tracker | "Unavailable on this Gateway version" (501 handling exists) |
| `usage.status` unavailable | Usage Meter (percent ring) | Percent ring hidden, totals still shown (existing graceful degradation) |
| SSE disconnects mid-stream | Activity Log | Badge switches to "Disconnected", events buffer preserved, Retry button shown |

---

## Missing Gateway RPCs (None)

All required RPCs already exist. No new server routes needed.
The only change is wiring `GET /api/session-status` data into the dashboard's System Status widget.
