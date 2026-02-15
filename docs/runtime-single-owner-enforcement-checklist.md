# ClawSuite Runtime Single-Owner Enforcement Checklist (One Page)

**Purpose:** Prevent runtime flapping, port drift, and split ownership.

**Rule:** ClawSuite runtime must have **one owner, one port, one PID source of truth**.

---

## 1) Ownership (Must Pass)

- [ ] A single runtime owner is explicitly designated (name + command).
- [ ] All starts/stops/restarts go through that owner only.
- [ ] Direct `npm run preview` / `nohup` launches are prohibited in normal ops.

**Owner of record:** ____________________

---

## 2) Competing Starters Disabled (Must Pass)

- [ ] Duplicate system services are disabled.
- [ ] Watchdog is in monitor-only mode or disabled for recovery windows.
- [ ] Cron jobs that can start/restart ClawSuite runtime are disabled unless explicitly approved.
- [ ] Manual background launch scripts are removed or blocked.

---

## 3) Port Discipline (Must Pass)

- [ ] Expected runtime port is fixed (e.g., `4173`).
- [ ] Auto-increment port fallback is disabled (no silent move to `4174+`).
- [ ] If expected port is occupied, startup fails fast with an explicit error.

**Expected port:** __________

---

## 4) Pre-Start Guard (Must Pass)

Before start, run guard checks:

- [ ] No existing unmanaged ClawSuite PID is running.
- [ ] Expected port is free OR owned by the designated owner.
- [ ] Build artifacts are in a clean state (no stale partial output).

**Guard command used:** ____________________

---

## 5) Canonical State Files (Must Pass)

- [ ] Only the designated owner writes PID/state files.
- [ ] Health/restart scripts read from the same canonical PID/state file.
- [ ] PID file contains PID only (no mixed log output).

**PID file path:** ____________________
**State file path:** ____________________

---

## 6) Health Contract (Must Pass)

- [ ] Machine-readable JSON health endpoint exists and is documented.
- [ ] Health endpoint returns deterministic fields (at minimum):
  - [ ] `status`
  - [ ] `service`
  - [ ] `port`
  - [ ] `pid`
  - [ ] `timestamp`
- [ ] Content-Type is JSON (`application/json`).
- [ ] Health endpoint is validated with explicit command output before go-live.

**Health endpoint:** ____________________
**Validation command:** ____________________

---

## 7) Rollback Readiness (Must Pass)

- [ ] Deterministic rollback script exists and is executable.
- [ ] Supports rollback by tag/ref and by step count.
- [ ] Has dry-run mode.
- [ ] Performs post-rollback health verification.
- [ ] Writes rollback state/log for audit.

**Rollback command:** ____________________
**Last dry-run timestamp:** ____________________

---

## 8) Post-Start Verification Gate (Must Pass)

After each start/restart/deploy:

- [ ] Exactly one ClawSuite runtime PID is active.
- [ ] Exactly one expected runtime port is listening.
- [ ] JSON health endpoint passes.
- [ ] UI/API smoke check passes.

If any fail: **No-Go** and invoke rollback.

---

## 9) Operational Guardrail (Must Pass)

- [ ] No deployment is marked complete without QA PASS on:
  - [ ] JSON health contract
  - [ ] Single-owner runtime
  - [ ] Rollback drill
- [ ] Any manual override is logged with owner + timestamp + reason.

---

## 10) Sign-Off

**Coder:** ____________________ Date: __________

**QA:** ____________________ Date: __________

**Main/Release Authority:** ____________________ Date: __________

**Final Status:** ☐ GO-LIVE  ☐ NO-GO
