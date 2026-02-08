\# Phase 1.4 — Usage + Cost Parity (leverage OpenClaw v2026.2.6 + “Open Usage” pattern)

Repo: https://github.com/outsourc-e/openclaw-studio

Context:

We have a reference implementation (“Open Usage”) that already pulls provider usage correctly by reading the local auth profile/providers and using the newer OpenClaw v2026.2.6 usage capabilities. We want to leverage that approach instead of inventing new usage logic.

Goal:

Replace ALL demo usage/cost UI with real Gateway-backed data, including per-provider usage.

\---

\## P0 Scope (must ship in this PR)

\### 1) Investigate existing “Open Usage” behavior (reference pattern)

\- Identify how “Open Usage” determines configured providers:

\- which auth file it reads

\- what fields it extracts (provider IDs only)

\- Identify how it queries usage (RPC endpoints, payloads)

\- Identify how it maps usage → providers (join keys, canonical provider names)

Important:

\- You may clone the “Open Usage” repo locally ONLY as a reference.

\- Do NOT copy large chunks blindly; port the minimal logic needed.

\- Do NOT introduce new dependencies unless absolutely necessary.

\### 2) Add server API routes (Studio)

Create/modify server routes to expose usage + cost:

\- GET \`/api/usage\`

\- returns totals + per-provider usage (where possible)

\- uses OpenClaw v2026.2.6 usage endpoints (do not estimate)

\- filters/organizes results using configured providers from auth profile (provider IDs only)

\- GET \`/api/cost\`

\- returns spend totals (and timeseries if available)

\- uses Gateway/usage source of truth (do not estimate)

\### 3) Wire the UI widgets to real data (no demo fallback)

\- Usage Meter donut → \`/api/usage\`

\- Provider Usage panel → \`/api/usage\` grouped by provider

\- Cost tracker sparkline/totals → \`/api/cost\`

If any usage/cost endpoint isn’t supported by the current Gateway:

\- Show “Unavailable on this Gateway version”

\- Do NOT show demo numbers

\### 4) Security requirements (non-negotiable)

\- Never return secrets, tokens, api keys, refresh tokens

\- If reading auth profiles, server must extract ONLY provider IDs (names), nothing else

\- No logging of auth profile contents

\---

\## Constraints

\- No custom cost estimation logic

\- Minimal diff (don’t refactor unrelated UI)

\- Preserve architecture: UI → \`/api/\*\` → server/gateway.ts → Gateway RPC

\- No changes to licensing, CI, or repo visibility

\- Avoid scope creep (usage + cost only)

\---

\## Deliverables

1) PR titled: \`Phase 1.4: Wire usage + cost to Gateway (Open Usage pattern)\`

2) Docs: \`docs/USAGE\_AND\_COST.md\`

\- Which Gateway RPC(s) / endpoints were used

\- Payload shapes for \`/api/usage\` and \`/api/cost\`

\- Which auth profile file is read and what is extracted (provider IDs only)

\- How provider mapping works

3) Test plan in PR description:

\- \`curl\` commands for \`/api/usage\` and \`/api/cost\`

\- Manual UI checks

4) Build proof:

\- \`npm run build\` output

\---

\## Manual Test Plan (required)

\- Gateway running:

\- \`/api/usage\` returns totals + provider breakdown

\- UI shows real usage numbers (not demo)

\- Disconnect Gateway:

\- UI shows “Gateway disconnected” and/or “Unavailable…”

\- Verify no secrets:

\- \`curl /api/usage | grep -iE '(token|secret|password|apiKey|refresh)'\` returns nothing

\---