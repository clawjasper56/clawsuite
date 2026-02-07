# Phase 1 — Gateway Parity (P0 — Shipping Blocker)

## Goal

Match everything the Gateway Web UI can do. Studio must fully replace `http://127.0.0.1:18789/`.

## Deliverables

1. **Model switcher wired to Gateway RPC** — Selecting a model in the composer actually changes the agent's model via Gateway
2. **Model persists per session** — Model choice saved and restored when switching sessions
3. **Settings persist and apply** — Settings page reads from Gateway config and writes changes back
4. **Provider token auto-discovery** — Desktop app reads Gateway token from `~/.openclaw/openclaw.json` (no manual .env required)
5. **Execution context bar** — Shows current agent ID, active model, loaded skills count in chat header
6. **Chat streaming parity** — Verify streaming works identically to Gateway Web UI (thinking blocks, tool calls, markdown)
7. **Session management** — Create new session, switch sessions, view session history (all via Gateway RPC)

## Exit Criteria

- [ ] A user can install Studio, connect to Gateway, and never open the Gateway Web UI
- [ ] Model switching works end-to-end
- [ ] Settings changes persist across restarts
- [ ] Zero manual configuration required beyond having OpenClaw installed
