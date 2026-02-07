# Phase 0 — Stabilization & Truth

## Goal

Ensure the product never lies to the user.

## Deliverables

1. **Demo Mode banner** — Any widget/feature using demo data shows a visible "Demo" indicator
2. **Demo data labeling** — All hardcoded/mock data has explicit labels, never appears as real
3. **Secrets scan report** — Run `git log --all -p | grep -iE "sk-|ghp_|token.*=.*[a-f0-9]{32}"` on full history
4. **Gateway parity test script** — Script that tests every `/api/*` endpoint returns real data when Gateway is connected
5. **Error state audit** — Every feature has a clear error state (not just empty/blank)

## Exit Criteria

- [ ] No feature appears functional while using mock data without a visible demo indicator
- [ ] Secrets scan passes clean
- [ ] All API endpoints tested against live Gateway
- [ ] Error states exist for: no Gateway, no sessions, no skills, no files
