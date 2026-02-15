# ClawSuite Recovery Report — 2026-02-15

## Executive Summary
ClawSuite was failing in multiple layers:
1. **Runtime instability** (duplicate preview owners / port drift risk)
2. **False-positive health checks** (green while gateway was actually failing)
3. **Gateway auth incompatibility** after OpenClaw auth changes (device identity + challenge/nonce)
4. **Dashboard data path blocked** (`missing scope: operator.read` / pairing-required / origin-policy errors)
5. **Realtime stream path disconnecting** (chat-events stream using older connect path)
6. **Appearance persistence regressions** (theme/accent written to wrong stores)

Recovery is now complete and validated via live endpoint checks.

---

## What Failed (Root Causes)

### 1) Health endpoint was lying (false green)
`/api/gateway/status` previously returned `connected: true` in catch/failure paths.

**Impact:** Operational checks showed healthy while data APIs were failing.

### 2) Gateway auth protocol drift
OpenClaw gateway now expects device identity + challenge/nonce signed handshake.
Older/simple token connect behavior became insufficient in some paths.

**Impact:** Errors observed across attempts:
- `missing scope: operator.read`
- `gateway token mismatch`
- `origin not allowed`
- `pairing required`

### 3) Stream path not upgraded with main gateway path
Main RPC client had newer connect handling; `gateway-stream.ts` did not.

**Impact:** Gateway Debug Console could connect then quickly show stream disconnects.

### 4) Appearance settings source-of-truth split
Theme controls in some UI surfaces wrote to `chat-settings` or raw `localStorage.theme`, while the dashboard appearance system depends on `openclaw-settings`.

**Impact:** Theme/accent appeared to apply, then reset on refresh/navigation.

### 5) Runtime ownership drift risk
Potential for both managed service + manual preview process to contend.

**Impact:** Historical flapping between 4173/4174 and unstable restart behavior.

---

## Recovery Actions Performed

## A) Runtime and health contract stabilization
- Enforced single-owner runtime behavior for preview port.
- Added canonical machine health endpoint:
  - `src/routes/api/healthz.ts`
- Updated watchdog checks to use `/api/healthz`.
- Kept `/health` and `/api/health` out of automation due HTML responses in this setup.

## B) Gateway protocol/auth repair
- Applied upstream commits bringing gateway auth compatibility in line:
  - `701905c` — Ed25519 device identity + challenge/nonce handshake
  - `522ee0b` — checkpoint fixes including related gateway/session UX stability
- Aligned requested scopes to include read/admin/approvals/pairing.
- Corrected gateway URL/token runtime config handling and reconnect behavior.
- Approved pending paired device when gateway required pairing.

## C) Realtime stream repair
- Updated `src/server/gateway-stream.ts` to support challenge/nonce connect path before sending `connect`.
- Stream now remains connected under normal operation.

## D) Appearance persistence repair
- Fixed preload precedence in `src/routes/__root.tsx`:
  - `openclaw-settings` is authoritative for app appearance.
  - `chat-settings` only legacy fallback.
- Removed hydration behavior that could race defaults over persisted settings in `src/hooks/use-settings.ts`.
- Unified theme toggles to write through `useSettings` (`openclaw-settings`) instead of chat/localStorage side channels:
  - `src/components/theme-toggle.tsx`
  - `src/screens/chat/components/chat-sidebar.tsx` (ThemeToggleMini)

---

## Verification Evidence (Post-Fix)

### Runtime/ports
- Single listener on `:4173`
- No listener on `:4174`
- `clawsuite-preview.service` disabled/failed (not contending)

### Health and gateway
- `GET /api/healthz` → `status: ok`
- `GET /api/ping` → `ok: true`
- `GET /api/gateway/status` → `connected: true, ok: true`
- `GET /api/gateway/agents` → `ok: true`
- `GET /api/gateway/sessions` → `ok: true`

### UX confirmation
- Gateway Debug Console stream/connect issues resolved
- Appearance settings persistence confirmed working by user

---

## Lessons Learned / Preventive Controls

1. **Health checks must be truthy, not optimistic**
   - Never set `connected: true` in error fallback paths.
2. **Protocol updates must be mirrored across all gateway clients**
   - Main RPC and stream clients must share auth/connect logic.
3. **One store per concern**
   - App appearance must write to a single authoritative persisted store.
4. **Single runtime owner policy**
   - Keep service/manual ownership strict to avoid port drift.
5. **Pairing/auth errors should be surfaced explicitly in UI**
   - `pairing required`, origin policy, scope issues should guide operator action.

---

## Files Touched During Final Recovery
- `src/server/gateway.ts`
- `src/server/gateway-stream.ts`
- `src/routes/api/gateway/status.ts`
- `src/routes/api/healthz.ts`
- `src/routes/__root.tsx`
- `src/hooks/use-settings.ts`
- `src/components/theme-toggle.tsx`
- `src/screens/chat/components/chat-sidebar.tsx`
- `scripts/ops/watchdog-health.sh`
- `docs/runtime-single-owner-enforcement-checklist.md`

---

## Current Status
**Recovered / stable.**
ClawSuite gateway, stream, runtime ownership, and appearance persistence are functioning as expected.