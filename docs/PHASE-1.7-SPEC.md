\# Phase 1.7 — Provider Setup Wizard (Foundation)

Status: Design + Minimal UI

Goal: Prepare for easy provider onboarding

Depends on: Phase 1.6 merged

\---

\## Objective

Create the UX foundation for adding providers/models \*without editing config files\*.

This phase is NOT full implementation — it is structure + flow.

\---

\## Scope (P0)

\- “Add Provider” entry point in Studio

\- Wizard flow (UI only or partial):

1\. Choose provider

2\. Choose auth type (API key / OAuth)

3\. Explain where auth is stored

4\. Choose allowed models

\---

\## Constraints

\- No secrets stored in Studio

\- Wizard writes NOTHING yet unless explicitly safe

\- OAuth flows may open external browser

\- API keys must remain local

\---

\## Deliverables

\- UI shell + navigation

\- No-op or stub handlers

\- \`docs/PROVIDER\_WIZARD.md\`

\- PR: \`Phase 1.7: Provider setup wizard foundation\`

\---

\## Stop Condition

Open PR and STOP.

Do not begin Phase 2.0 until merged.