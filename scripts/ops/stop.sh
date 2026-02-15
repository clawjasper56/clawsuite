#!/usr/bin/env bash
# ClawSuite Stop Script
# Safely stops running ClawSuite instances
#
# Usage:
#   ./stop.sh [OPTIONS]
#
# Exit codes:
#   0 - Stopped successfully (or was not running)
#   1 - Failed to stop

set -euo pipefail

# Configuration
DEFAULT_PORT=4173

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCK_DIR="${PROJECT_ROOT}/logs"
PID_FILE="${LOCK_DIR}/clawsuite.pid"
STATE_FILE="${LOCK_DIR}/watchdog.state"
WATCHDOG_PID="${LOCK_DIR}/watchdog.pid"

# Parse arguments
PORT="${CLAWSUITE_PORT:-${DEFAULT_PORT}}"
FORCE="false"

usage() {
    cat <<EOF
ClawSuite Stop Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -p, --port PORT     Port to check (default: ${DEFAULT_PORT}, env: CLAWSUITE_PORT)
    -f, --force         Force kill if graceful stop fails
    -h, --help          Show this help message

Exit Codes:
    0 - Stopped successfully or was not running
    1 - Failed to stop
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# Find process on port
find_process_on_port() {
    local port="$1"
    local pid=""
    
    if command -v lsof &>/dev/null; then
        pid=$(lsof -t -i ":${port}" -sTCP:LISTEN 2>/dev/null | head -1)
    elif command -v ss &>/dev/null; then
        local line
        line=$(ss -tlnp 2>/dev/null | grep ":${port} " | head -1)
        if [[ -n "${line}" ]]; then
            pid=$(echo "${line}" | grep -oP 'pid=\K[0-9]+' | head -1)
        fi
    fi
    
    echo "${pid:-}"
}

# Kill process
kill_process() {
    local pid="$1"
    local attempts=0
    local max_attempts=10
    
    echo "Stopping process ${pid}..."
    kill -TERM "${pid}" 2>/dev/null || true
    
    while [[ ${attempts} -lt ${max_attempts} ]]; do
        if ! kill -0 "${pid}" 2>/dev/null; then
            echo "Process ${pid} stopped gracefully"
            return 0
        fi
        sleep 1
        ((attempts++))
    done
    
    if [[ "${FORCE}" == "true" ]]; then
        echo "Force killing process ${pid}..."
        kill -KILL "${pid}" 2>/dev/null || true
        sleep 1
        
        if ! kill -0 "${pid}" 2>/dev/null; then
            echo "Process ${pid} force killed"
            return 0
        fi
    fi
    
    echo "ERROR: Failed to stop process ${pid}" >&2
    return 1
}

# Stop watchdog daemon if running
stop_watchdog() {
    if [[ -f "${WATCHDOG_PID}" ]]; then
        local wpid
        wpid=$(cat "${WATCHDOG_PID}" 2>/dev/null || echo "")
        
        if [[ -n "${wpid}" ]] && kill -0 "${wpid}" 2>/dev/null; then
            echo "Stopping watchdog daemon (PID: ${wpid})..."
            kill -TERM "${wpid}" 2>/dev/null || true
            sleep 1
        fi
        
        rm -f "${WATCHDOG_PID}"
    fi
}

# Main
echo "=== Stopping ClawSuite ==="

# Stop watchdog first
stop_watchdog

# Find and stop server
pid=$(find_process_on_port "${PORT}")

if [[ -z "${pid}" ]]; then
    echo "No process found on port ${PORT}"
else
    if ! kill_process "${pid}"; then
        exit 1
    fi
fi

# Clean up state files
rm -f "${PID_FILE}"
rm -f "${LOCK_DIR}/clawsuite.lock"

# Update state file to reflect stopped state
cat > "${STATE_FILE}" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "host": "localhost",
  "port": ${PORT},
  "port_status": "not_listening",
  "http_status": "unknown",
  "healthy": false,
  "pid": null,
  "mode": "stopped",
  "error": "Service stopped"
}
EOF

echo "ClawSuite stopped"
echo "State file updated"
