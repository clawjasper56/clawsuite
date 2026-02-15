# ClawSuite Deterministic Rollback Mechanism

**Version:** 1.0.0
**Status:** Active
**Author:** ClawSuite Operations

---

## Overview

ClawSuite provides **two complementary rollback mechanisms**:

1. **Deployment Rollback** (`deploy-with-rollback.sh`) - Backup-based rollback for failed deployments
2. **Git Rollback** (`rollback.sh`) - Commit-based rollback for code regressions

Both are **deterministic** - given the same inputs, they always produce the same result.

---

## Quick Reference

| Scenario | Command |
|----------|---------|
| Deploy with auto-rollback | `./scripts/ops/deploy-with-rollback.sh deploy --pre-build` |
| Rollback failed deployment | `./scripts/ops/deploy-with-rollback.sh rollback` |
| View deployment status | `./scripts/ops/deploy-with-rollback.sh status` |
| View transaction journal | `./scripts/ops/deploy-with-rollback.sh journal` |
| Verify state | `./scripts/ops/deploy-with-rollback.sh verify` |
| Rollback to git commit | `./scripts/ops/rollback.sh --to <commit>` |
| Rollback N commits | `./scripts/ops/rollback.sh --steps N` |

---

## Deployment Rollback

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT FLOW                               │
├─────────────────────────────────────────────────────────────────┤
│  1. Create backup (dist/, package.json, state files)             │
│  2. Run build (if --pre-build)                                  │
│  3. Stop existing server                                         │
│  4. Start new server                                             │
│  5. Health check verification                                    │
│     ├─ PASS → Record success in journal                          │
│     └─ FAIL → Automatic rollback to last backup                 │
└─────────────────────────────────────────────────────────────────┘
```

### Commands

#### Deploy with Automatic Rollback

```bash
# Deploy with pre-build and health verification
./scripts/ops/deploy-with-rollback.sh deploy --pre-build

# Deploy without health check (use with caution)
./scripts/ops/deploy-with-rollback.sh deploy --no-health-check

# Custom health check timeout
./scripts/ops/deploy-with-rollback.sh deploy --pre-build --timeout 60
```

#### Manual Rollback

```bash
# Rollback to last successful deployment
./scripts/ops/deploy-with-rollback.sh rollback

# Rollback to specific transaction
./scripts/ops/deploy-with-rollback.sh rollback --to tx-20260215-120000

# Force rollback (skip health check)
./scripts/ops/deploy-with-rollback.sh rollback --force
```

#### Status and Journal

```bash
# Current deployment status
./scripts/ops/deploy-with-rollback.sh status

# View last 10 transactions
./scripts/ops/deploy-with-rollback.sh journal

# View last 20 transactions
./scripts/ops/deploy-with-rollback.sh journal 20

# Verify current state
./scripts/ops/deploy-with-rollback.sh verify
```

### Transaction Journal

Every deployment and rollback is recorded in the transaction journal:

**Location:** `logs/deploy-journal/transactions.jsonl`

**Entry Format:**
```json
{
  "tx_id": "tx-20260215-120000-1234",
  "timestamp": "2026-02-15T12:00:00Z",
  "action": "deploy_complete",
  "status": "success",
  "details": {}
}
```

**Actions:**
| Action | Meaning |
|--------|---------|
| `deploy_start` | Deployment initiated |
| `backup_created` | Pre-deployment backup completed |
| `build_start/complete` | Build phase |
| `server_start` | Server start attempted |
| `health_check` | Health verification |
| `deploy_complete` | Deployment finished |
| `rollback` | Rollback executed |

### Backup Retention

- Backups stored in `backups/<tx_id>/`
- Last 5 backups retained automatically
- Older backups cleaned up after successful deployment

---

## Git Rollback

### How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    GIT ROLLBACK FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│  1. Resolve target commit                                        │
│  2. Check for uncommitted changes (block unless --force)         │
│  3. Stop existing server                                         │
│  4. Git checkout to target commit                                │
│  5. npm ci (reinstall dependencies)                              │
│  6. npm run build (for preview mode)                             │
│  7. Start server                                                 │
│  8. Health check verification                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Commands

#### Rollback to Specific Commit/Tag

```bash
# Rollback to specific commit
./scripts/ops/rollback.sh --to abc1234

# Rollback to tag
./scripts/ops/rollback.sh --to v1.2.3

# Preview only (dry run)
./scripts/ops/rollback.sh --to v1.2.3 --dry-run
```

#### Rollback N Commits

```bash
# Rollback 1 commit (default)
./scripts/ops/rollback.sh --steps 1

# Rollback 3 commits
./scripts/ops/rollback.sh --steps 3

# Rollback with dev mode
./scripts/ops/rollback.sh --steps 1 --mode dev
```

### Rollback State File

**Location:** `logs/rollback.state`

```json
{
  "timestamp": "2026-02-15T12:00:00Z",
  "status": "ok",
  "from": "abc1234...",
  "to": "def5678...",
  "mode": "preview",
  "port": 4173,
  "health": { ... }
}
```

---

## Decision Matrix

| Situation | Use This |
|-----------|----------|
| Deployment failed during build | `deploy-with-rollback.sh rollback` (automatic) |
| Deployment failed health check | `deploy-with-rollback.sh rollback` (automatic) |
| Need to undo last deployment | `deploy-with-rollback.sh rollback` |
| Code regression in latest commit | `rollback.sh --steps 1` |
| Revert to known-good release | `rollback.sh --to v1.2.3` |
| Debug failed deployment | `deploy-with-rollback.sh journal` |
| Verify system state | `deploy-with-rollback.sh verify` |

---

## Determinism Guarantees

### Deployment Rollback Determinism

Given the same:
- Transaction ID
- Backup files

The rollback will always:
1. Stop the server
2. Restore files from backup
3. Restart server
4. Verify health

### Git Rollback Determinism

Given the same:
- Git commit reference
- Clean working tree (or --force)

The rollback will always:
1. Stop server
2. Checkout to commit
3. Reinstall dependencies
4. Rebuild
5. Start server
6. Verify health

---

## Verification Commands

### Verify Deployment State

```bash
# Check current deployment status
./scripts/ops/deploy-with-rollback.sh status

# Verify system health
./scripts/ops/deploy-with-rollback.sh verify

# Check health endpoint
curl -s http://localhost:4180/health | jq '.status.healthy'
```

### Verify Git State

```bash
# Current commit
git rev-parse HEAD

# Compare with rollback state
cat logs/rollback.state | jq '.to'

# Check for uncommitted changes
git status --porcelain
```

### Full Verification

```bash
# Run all checks
./scripts/ops/deploy-with-rollback.sh verify && \
curl -sf http://localhost:4180/health/ready && \
echo "ALL CHECKS PASSED"
```

---

## Troubleshooting

### Rollback Failed

1. **Check logs:**
   ```bash
   cat logs/deploy-journal/transactions.jsonl | tail -5 | jq .
   cat logs/deploy.log
   ```

2. **Manual recovery:**
   ```bash
   ./scripts/ops/stop.sh --force
   ls backups/  # Find last good backup
   cp -r backups/tx-XXX/dist ./dist
   ./scripts/ops/start.sh --force
   ```

### No Backups Available

If no backups exist:
```bash
# Fresh build and deploy
./scripts/ops/clean-start.sh
```

### Health Check Always Failing

1. Check health endpoint:
   ```bash
   curl -v http://localhost:4180/health
   ```

2. Check app server:
   ```bash
   curl -v http://localhost:4173/
   ```

3. Force rollback without health check:
   ```bash
   ./scripts/ops/deploy-with-rollback.sh rollback --force
   ```

---

## Integration with CI/CD

### GitHub Actions Example

```yaml
deploy:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: Deploy with Rollback
      run: |
        ./scripts/ops/deploy-with-rollback.sh deploy --pre-build --timeout 60
        
    - name: Verify Deployment
      run: |
        ./scripts/ops/deploy-with-rollback.sh verify
```

### GitLab CI Example

```yaml
deploy:
  script:
    - ./scripts/ops/deploy-with-rollback.sh deploy --pre-build
    - ./scripts/ops/deploy-with-rollback.sh verify
  after_script:
    - ./scripts/ops/deploy-with-rollback.sh status
```

---

## Exit Codes Reference

### deploy-with-rollback.sh

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Failure (deployment or rollback failed) |
| 2 | Configuration error |

### rollback.sh

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Failure |
| 2 | Invalid input |

---

**Last Updated:** 2026-02-15
**Maintainer:** ClawSuite Operations
