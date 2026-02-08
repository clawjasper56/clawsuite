\# Phase 1.6 — Gateway Debug Console

Status: Planned

Goal: Help users recover when Gateway breaks

Depends on: Phase 1.5 merged

\---

\## Objective

Add a Debug Console inside Studio that activates when:

\- Gateway is down

\- Errors occur

\- User manually opens it

This is a \*support killer\* feature.

\---

\## Scope (P0)

1\. Debug panel UI:

\- Shows connection state

\- Shows recent errors/events

2\. Docs integration:

\- Link to relevant OpenClaw docs

\- Contextual help per error

3\. LLM assistant (safe mode):

\- Reads logs + errors

\- Suggests fixes

\- Suggests terminal commands (copy-only)

\---

\## Safety Rules

\- LLM cannot execute commands

\- Commands are copy/paste only

\- No secrets or tokens in prompts

\- Clear disclaimer: “Suggestions only”

\---

\## Deliverables

\- Debug Console UI

\- LLM prompt + guardrails

\- \`docs/DEBUG\_CONSOLE.md\`

\- PR: \`Phase 1.6: Gateway debug console\`

\---

\## Stop Condition

Open PR and STOP.

Do not begin Phase 1.7 until merged.