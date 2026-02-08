\# Phase 1.5 — Activity Log & Event Stream

Status: Next

Goal: Make Studio observable and debuggable

Depends on: Phase 1.4 merged

\---

\## Objective

Introduce a unified Activity Log showing real Gateway and Studio events.

This is the foundation for debugging, trust, and future automation.

\---

\## Scope (P0)

Events to surface:

\- Gateway connected / disconnected

\- Model switched

\- Usage updated

\- Cron ran / failed

\- Tool invoked

\- Errors

\---

\## Architecture

\- Subscribe to Gateway event stream (if available)

\- OR poll minimal status endpoints if streaming unavailable

\- Server normalizes events

\- UI renders chronological log

\---

\## UX Rules

\- Read-only

\- Timestamped

\- Filterable by type (future)

\- No sensitive payloads

\---

\## Deliverables

\- \`/api/events\` (or equivalent)

\- Activity Log UI panel

\- \`docs/ACTIVITY\_LOGS.md\`

\- PR: \`Phase 1.5: Activity logs + event stream\`

\---

\## Stop Condition

Open PR and STOP.

Do not begin Phase 1.6 until merged.