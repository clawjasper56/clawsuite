# Instructions for AI Agents

## Rules

1. **Declare phase** — State which phase (0-4) your work belongs to
2. **List files before editing** — Show which files you'll modify before making changes
3. **Respect architecture** — All Gateway access through `src/server/gateway.ts`, never direct from UI
4. **Respect security rules** — Read `04_SECURITY_NON_NEGOTIABLES.md` before any work
5. **Do not introduce unlabeled demo data** — If you add mock/demo data, it MUST have a visible "Demo" indicator
6. **Do not clone Codex behavior blindly** — Map concepts to OpenClaw primitives (see `02_CODEX_USABILITY_REFERENCE.md`)
7. **Run `npm run build` after every change** — No broken builds
8. **Use existing patterns** — Check existing widgets/components before creating new ones

## Goal

Functional parity → reliability → trust → polish

## Priority Order

Phase 0 (truth) → Phase 1 (parity) → Phase 2 (confidence) → Phase 3 (polish) → Phase 4 (differentiation)

## Key Files

- `src/server/gateway.ts` — Singleton Gateway WebSocket client (DO NOT create additional WS connections)
- `src/routes/api/*.ts` — API endpoints that proxy Gateway RPC
- `src/screens/dashboard/` — Dashboard widgets
- `src/screens/chat/` — Chat interface
- `docs/04_SECURITY_NON_NEGOTIABLES.md` — Security rules (READ FIRST)
