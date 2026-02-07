# Security Non-Negotiables

These rules MUST be enforced in all phases.

## Secrets

- No API keys in git (present or historical)
- Secrets must live in `.env` (gitignored)
- Secrets scan must be run on full history before any public release
- Gateway token auto-discovered from `~/.openclaw/openclaw.json` at runtime

## Skills

- New skills disabled by default
- Skill permissions visible (FS / Network / Browser)
- Explicit execution warnings before running untrusted skills

## Transparency

- Demo data must be labeled (visible "Demo" badge)
- Demo mode must be visible to the user
- No silent fallbacks — if data is fake, say so
- Error states must be clear, not hidden behind mock data

## Architecture

- Browser UI MUST NOT talk directly to the Gateway WebSocket
- All Gateway access goes through the server-side singleton client
- No auth tokens in client-side JavaScript bundles
