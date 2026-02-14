#!/usr/bin/env bash
# ClawSuite Watchdog Wrapper for Cron
# This script wraps watchdog-health.sh for the cron job interface
# Outputs: "ALERT: <message>" on issues, "NO_ALERT" when healthy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${CLAWSUITE_PORT:-4173}"
HOST="${CLAWSUITE_HOST:-localhost}"

# Run health check
if ! HEALTH_OUTPUT=$("$SCRIPT_DIR/watchdog-health.sh" --port "$PORT" --host "$HOST" 2>&1); then
    echo "ALERT: ClawSuite health check failed on ${HOST}:${PORT} - $HEALTH_OUTPUT"
    exit 0
fi

# Parse result - check if healthy
if echo "$HEALTH_OUTPUT" | grep -qi "result: healthy\|\"healthy\":true"; then
    echo "NO_ALERT"
else
    echo "ALERT: ClawSuite health check returned unexpected status on ${HOST}:${PORT}"
fi
