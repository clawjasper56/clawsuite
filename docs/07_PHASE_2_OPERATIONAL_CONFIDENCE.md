# Phase 2 — Operational Confidence

## Goal

Make agent behavior observable and trustworthy. Users should understand what agents are doing, what they cost, and be able to intervene.

## Deliverables

1. **Real usage + cost telemetry** — Wire Usage Meter to actual token counts from Gateway/providers
2. **Gateway event stream logs** — Subscribe to Gateway events for real-time activity feed
3. **Real agent sidebar** — Replace demo swarm with actual running agents/sessions
4. **Session replay** — Ability to review past session transcripts in full
5. **Cost tracking** — When Gateway exposes cost data, wire the dashboard sparkline
6. **Notification system** — Real alerts for: session start/end, errors, cron completions, usage thresholds

## Exit Criteria

- [ ] No demo data in Agent View or Activity Logs when Gateway is connected
- [ ] Users can see real token usage and estimated costs
- [ ] All running agents visible with status, model, and elapsed time
- [ ] Event stream provides real-time activity without polling
