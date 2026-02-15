# ClawSuite Uptime Runbook

Operational guide for monitoring and maintaining ClawSuite server availability using the watchdog system.

## Overview

The ClawSuite watchdog system provides:
- **Single entry point** - Unified `start.sh` for all server starts
- **Single runtime owner** - Lock file prevents concurrent starts
- **Deterministic port** - Default port 4173 (configurable via `CLAWSUITE_PORT`)
- **Health monitoring** - Periodic checks on server availability
- **Automatic recovery** - Restart failed services automatically
- **State tracking** - Persistent state for debugging and alerting

## Quick Reference

| Task | Command |
|------|---------|
| Start preview | `npm run start` or `./scripts/ops/start.sh` |
| Start dev | `npm run start:dev` |
| Stop server | `npm run stop` |
| Clean start | `npm run clean-start` |
| Check health | `npm run status` |
| Restart (clean) | `npm run restart` |
| Deploy (with rollback) | `npm run deploy` |
| Deploy status | `npm run deploy:status` |
| Rollback (git-based) | `npm run rollback -- --steps 1` |
| Rollback (transaction) | `npm run rollback:tx` |
| Start daemon | `./scripts/ops/watchdog-daemon.sh --daemonize` |
| Stop daemon | `./scripts/ops/watchdog-daemon.sh --stop` |
| Daemon status | `./scripts/ops/watchdog-daemon.sh --status` |
| Health endpoint | `npm run health:endpoint` |

## Default Ports

| Mode | Port | Environment Variable |
|------|------|---------------------|
| preview | 4173 | `CLAWSUITE_PORT` |
| dev | 3000 | `CLAWSUITE_PORT` |

## Setup

### Prerequisites

- Node.js 18+ and npm
- One of: `curl`, `wget`, `nc`, or bash with `/dev/tcp` support
- One of: `ss`, `netstat`, or `lsof` for port detection

### Initial Configuration

1. **Build the project first** (for preview mode):
   ```bash
   npm run build
   ```

2. **Verify scripts are executable**:
   ```bash
   chmod +x scripts/ops/*.sh
   ```

3. **Start the server**:
   ```bash
   npm run start
   # or
   ./scripts/ops/start.sh
   ```

4. **Verify health**:
   ```bash
   npm run status
   ```

### Single Entry Point

**IMPORTANT**: Always use `./scripts/ops/start.sh` (or `npm run start`) to start ClawSuite.

Do NOT use `npm run preview` or `npm run dev` directly - these bypass the lock mechanism and can cause:
- Multiple processes on the same port
- Stale PID files
- Inconsistent state tracking

## Usage

### Starting the Server

```bash
# Start preview (default, port 4173)
npm run start

# Start dev server (port 3000)
npm run start:dev

# Start with custom port
CLAWSUITE_PORT=8080 npm run start

# Force restart (kill existing process)
./scripts/ops/start.sh --force

# Clean build and start
npm run clean-start
```

### Stopping the Server

```bash
npm run stop
# or
./scripts/ops/stop.sh

# Force kill if graceful stop fails
./scripts/ops/stop.sh --force
```

### Health Checks

The canonical machine-readable health contract is `GET /api/healthz` (see `docs/HEALTH_ENDPOINT_CONTRACT.md`).

#### Basic Health Check
```bash
./scripts/ops/watchdog-health.sh
```

**Expected output (healthy):**
```
=== ClawSuite Health Check ===
Timestamp: 2026-02-14T21:06:00Z
Target: localhost:4173
Port Status: listening
HTTP Status: healthy
PID: 12345
Result: HEALTHY
```

**Expected output (unhealthy):**
```
=== ClawSuite Health Check ===
Timestamp: 2026-02-14T21:06:00Z
Target: localhost:4173
Port Status: not_listening
HTTP Status: unhealthy
PID: N/A
Result: UNHEALTHY - Port 4173 is not listening
```

#### JSON Output (for monitoring systems)
```bash
./scripts/ops/watchdog-health.sh --json
```

**Expected output:**
```json
{
  "timestamp": "2026-02-14T21:06:00Z",
  "host": "localhost",
  "port": 4173,
  "port_status": "listening",
  "http_status": "healthy",
  "healthy": true,
  "pid": 12345,
  "error": null
}
```

#### Update State File
```bash
./scripts/ops/watchdog-health.sh --state
```
Writes current state to `logs/watchdog.state`.

### Restart/Recovery

#### Restart Preview Server
```bash
./scripts/ops/watchdog-restart.sh
```

#### Restart Dev Server
```bash
./scripts/ops/watchdog-restart.sh --mode dev
```

#### Dry-Run (show what would happen)
```bash
./scripts/ops/watchdog-restart.sh --dry-run
```

**Expected dry-run output:**
```
DRY-RUN: Would stop process 12345
DRY-RUN: Would start preview server on port 4173
```

### Watchdog Daemon

#### Start Background Daemon
```bash
./scripts/ops/watchdog-daemon.sh --daemonize
```

Options:
- `--interval 120` - Check every 2 minutes (default: 60s)
- `--mode dev` - Monitor dev server instead of preview
- `--port 4173` - Monitor different port

#### Check Daemon Status
```bash
./scripts/ops/watchdog-daemon.sh --status
```

**Expected output:**
```
=== ClawSuite Watchdog Status ===
Daemon Status: RUNNING (PID: 54321)

Last Health Check:
{
  "timestamp": "2026-02-14T21:05:00Z",
  "host": "localhost",
  "port": 4173,
  "port_status": "listening",
  "http_status": "healthy",
  "healthy": true,
  "pid": 12345,
  "error": null
}

Log File: /path/to/logs/watchdog.log
Recent log entries:
  [2026-02-14T21:05:00Z] [INFO] Health check passed
```

#### Stop Daemon
```bash
./scripts/ops/watchdog-daemon.sh --stop
```

#### Single Check with Auto-Restart
```bash
./scripts/ops/watchdog-daemon.sh
```
Runs once: checks health and restarts if needed.

#### Test Mode (No Restart)
```bash
./scripts/ops/watchdog-daemon.sh --dry-run
```

### Deployment with Rollback

#### Deploy with Automatic Rollback
```bash
npm run deploy
# or
./scripts/ops/deploy-with-rollback.sh deploy --pre-build
```

The deploy command:
1. Creates a backup of current state
2. Runs build (if `--pre-build`)
3. Stops existing server
4. Starts new server
5. Verifies health
6. Automatically rolls back if any step fails

#### Check Deployment Status
```bash
npm run deploy:status
# or
./scripts/ops/deploy-with-rollback.sh status
```

#### Manual Rollback (Transaction-based)
```bash
# Rollback to last successful transaction
npm run rollback:tx

# Rollback to specific transaction
./scripts/ops/deploy-with-rollback.sh rollback --to tx-20260215-120000
```

#### Git-based Rollback
```bash
# Roll back 1 commit
npm run rollback -- --steps 1

# Roll back to specific commit/tag
npm run rollback -- --to v2.0.0
./scripts/ops/rollback.sh --to HEAD~3 --mode preview --port 4173
```

**Rollback options:**
- `--to REF` - Roll back to explicit commit/tag
- `--steps N` - Roll back N commits (default: 1)
- `--mode MODE` - Start mode after rollback (dev|preview)
- `--dry-run` - Show plan without executing
- `--force` - Allow rollback with uncommitted changes

## State File

Location: `logs/watchdog.state`

```json
{
  "timestamp": "2026-02-14T21:06:00Z",
  "host": "localhost",
  "port": 4173,
  "port_status": "listening",
  "http_status": "healthy",
  "healthy": true,
  "pid": 12345,
  "mode": "preview",
  "error": null
}
```

### State Fields

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 UTC timestamp of last check |
| `host` | Target hostname |
| `port` | Target port number |
| `port_status` | `listening` or `not_listening` |
| `http_status` | `healthy`, `unhealthy`, or `unknown` |
| `healthy` | Overall health boolean |
| `pid` | Process ID if running, null otherwise |
| `mode` | Server mode: `dev` or `preview` |
| `error` | Error message if unhealthy, null otherwise |

## Troubleshooting

### Server Won't Start

1. **Check build exists** (preview mode):
   ```bash
   ls -la dist/
   ```

2. **Check for port conflicts**:
   ```bash
   lsof -i :4173
   # or
   ss -tlnp | grep 4173
   ```

3. **Check logs**:
   ```bash
   tail -50 logs/watchdog.log
   ```

4. **Manual start to see errors**:
   ```bash
   npm run preview
   # or
   npm run dev
   ```

### Health Check Fails

1. **Verify server is running**:
   ```bash
   curl -I http://localhost:4173/
   ```

2. **Check process**:
   ```bash
   ps aux | grep -E 'vite|node'
   ```

3. **Check firewall/network**:
   ```bash
   # Is the port bound to the right interface?
   ss -tlnp | grep 4173
   ```

### Daemon Issues

1. **Daemon won't start**:
   - Check if already running: `./scripts/ops/watchdog-daemon.sh --status`
   - Check for stale PID file: `rm -f logs/watchdog.pid`

2. **Daemon crashes repeatedly**:
   - Check logs: `tail -100 logs/watchdog.log`
   - Try running without daemonize: `./scripts/ops/watchdog-daemon.sh`

3. **Daemon not restarting failed server**:
   - Check `MAX_FAILURES` threshold (default: 3)
   - Server may be restarting but failing immediately

### Common Error Messages

| Error | Cause | Resolution |
|-------|-------|------------|
| `Port 4173 is not listening` | Server not running | Run restart script |
| `HTTP check failed` | Server crashed or unhealthy | Check logs, restart |
| `Build failed, cannot start preview` | Missing build output | Run `npm run build` |
| `Failed to stop process` | Zombie process | Kill manually: `kill -9 <pid>` |
| `Neither curl nor wget available` | Missing HTTP tools | Install curl or wget |

## Cron Integration

For systems without daemon support, use cron:

```cron
# Check every 5 minutes
*/5 * * * * /path/to/scripts/ops/watchdog-daemon.sh >> /path/to/logs/cron.log 2>&1
```

## Monitoring Integration

### Prometheus/Node Exporter

Use the textfile collector with JSON state:

```bash
# Example: create textfile from state
cat logs/watchdog.state | jq -r '
  "clawsuite_watchdog_healthy \(.healthy | if . then 1 else 0 end)",
  "clawsuite_watchdog_port_status \(.port_status == \"listening\" | if . then 1 else 0 end)"
' > /var/lib/node_exporter/textfile_collector/clawsuite.prom
```

### Webhook Notifications

Add to `watchdog-daemon.sh` after restart attempts:

```bash
curl -X POST "${WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"ClawSuite watchdog triggered restart at $(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}"
```

## Best Practices

1. **Run daemon in preview mode** for production-like monitoring
2. **Check logs weekly** for recurring issues
3. **Set up external monitoring** (Uptime Kuma, Pingdom) as backup
4. **Keep builds updated** - stale builds can cause preview failures
5. **Don't commit state files** - they're in .gitignore for a reason

## Exit Codes Reference

### watchdog-health.sh
| Code | Meaning |
|------|---------|
| 0 | Healthy |
| 1 | Unhealthy |
| 2 | Error during check |

### watchdog-restart.sh
| Code | Meaning |
|------|---------|
| 0 | Restart successful |
| 1 | Restart failed |
| 2 | Configuration error |

### watchdog-daemon.sh
| Code | Meaning |
|------|---------|
| 0 | Normal exit |
| 1 | Fatal error |
| 2 | Configuration error |

---

*Last updated: 2026-02-15*
*Maintainer: ClawSuite Operations*
