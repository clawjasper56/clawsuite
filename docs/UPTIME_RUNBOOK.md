# ClawSuite Uptime Runbook

Operational guide for monitoring and maintaining ClawSuite server availability using the watchdog system.

## Overview

The ClawSuite watchdog system provides:
- **Health monitoring** - Periodic checks on server availability
- **Automatic recovery** - Restart failed services automatically
- **State tracking** - Persistent state for debugging and alerting
- **Operational visibility** - Logs and status reporting

## Quick Reference

| Task | Command |
|------|---------|
| Check health (once) | `./scripts/ops/watchdog-health.sh` |
| Check health (JSON) | `./scripts/ops/watchdog-health.sh --json` |
| Restart server | `./scripts/ops/watchdog-restart.sh` |
| Start daemon | `./scripts/ops/watchdog-daemon.sh --daemonize` |
| Stop daemon | `./scripts/ops/watchdog-daemon.sh --stop` |
| Daemon status | `./scripts/ops/watchdog-daemon.sh --status` |
| Dry-run check | `./scripts/ops/watchdog-daemon.sh --dry-run` |

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

3. **Run initial health check**:
   ```bash
   ./scripts/ops/watchdog-health.sh
   ```

### Directory Structure

```
clawsuite/
├── scripts/ops/
│   ├── watchdog-health.sh    # Health check script
│   ├── watchdog-restart.sh   # Restart/recovery script
│   └── watchdog-daemon.sh    # Background daemon
├── logs/
│   ├── watchdog.state        # Current state (JSON)
│   ├── watchdog.log          # Daemon logs
│   └── watchdog.pid          # Daemon PID file
└── docs/
    └── UPTIME_RUNBOOK.md     # This file
```

## Usage

### Health Checks

#### Basic Health Check
```bash
./scripts/ops/watchdog-health.sh
```

**Expected output (healthy):**
```
=== ClawSuite Health Check ===
Timestamp: 2026-02-14T21:06:00Z
Target: localhost:3000
Port Status: listening
HTTP Status: healthy
PID: 12345
Result: HEALTHY
```

**Expected output (unhealthy):**
```
=== ClawSuite Health Check ===
Timestamp: 2026-02-14T21:06:00Z
Target: localhost:3000
Port Status: not_listening
HTTP Status: unhealthy
PID: N/A
Result: UNHEALTHY - Port 3000 is not listening
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
  "port": 3000,
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
DRY-RUN: Would start preview server on port 3000
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
  "port": 3000,
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

## State File

Location: `logs/watchdog.state`

```json
{
  "timestamp": "2026-02-14T21:06:00Z",
  "host": "localhost",
  "port": 3000,
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
   lsof -i :3000
   # or
   ss -tlnp | grep 3000
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
   curl -I http://localhost:3000/
   ```

2. **Check process**:
   ```bash
   ps aux | grep -E 'vite|node'
   ```

3. **Check firewall/network**:
   ```bash
   # Is the port bound to the right interface?
   ss -tlnp | grep 3000
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
| `Port 3000 is not listening` | Server not running | Run restart script |
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

*Last updated: 2026-02-14*
*Maintainer: ClawSuite Operations*
