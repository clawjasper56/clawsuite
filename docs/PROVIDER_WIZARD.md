# Provider Setup Wizard (Phase 1.7 Foundation)

## Overview
This phase adds a provider onboarding UX shell in Studio at `/settings/providers`.

Implemented in this phase:
- Providers list screen that reads provider/model availability from `/api/models`
- "Add Provider" wizard with a 4-step setup flow
- Static provider catalog for known providers and setup metadata
- Stub verification flow with no-op handler and completion messaging

Out of scope for this phase:
- Writing to `~/.openclaw/openclaw.json`
- Reading or validating actual secrets
- Real provider connection verification

## Safety Guarantees
The foundation implementation is intentionally non-destructive and local-only for secret management.

- Studio does not read API key values from the config file.
- Studio does not write to `~/.openclaw/openclaw.json`.
- The wizard never asks for keys in form inputs.
- All snippets use placeholders such as `"sk-your-key-here"`.
- UI messaging explicitly states keys remain local and are never sent to Studio.

## Key Files
- `src/routes/settings/providers.tsx`
- `src/routes/settings/index.tsx`
- `src/screens/settings/providers-screen.tsx`
- `src/screens/settings/components/provider-wizard.tsx`
- `src/lib/provider-catalog.ts`

## Extending With New Providers
To add another provider:
1. Add an entry to `PROVIDER_CATALOG` in `src/lib/provider-catalog.ts`.
2. Include `id`, `name`, `description`, supported `authTypes`, `docsUrl`, and a placeholder-only `configExample`.
3. Map an icon in `src/screens/settings/components/provider-icon.tsx`.
4. If auth behavior differs, extend `buildConfigExample` in `src/lib/provider-catalog.ts`.

## Future Phases (2+)
Potential follow-up implementation areas:
- Verify flow that calls a dedicated backend endpoint for provider health checks.
- Optional guided config writing with explicit user confirmation and rollback safety.
- Config schema validation with actionable error messaging.
- Post-setup refresh flow to re-fetch model/provider lists without restart.
- Per-provider diagnostics and troubleshooting steps.
