#!/usr/bin/env bash
# ClawSuite Watchdog Daemon
# Periodically checks server health and automatically restarts if unhealthy
#
# Usage:
#   ./watchdog-daemon.sh [OPTIONS]
#
# Exit codes:
#   0 - Normal exit (received signal)
#   1 - Fatal error
#   2 - Configuration error

set -euo pipefail

# Configuration
DEFAULT_PORT=3000
DEFAULT_MODE="preview"
DEFAULT_INTERVAL=60
MAX_FAILURES=3
FAILURE_RESET_AFTER=300
STATE_DIR="${STATE_DIR:-$(dirname "$0")/../../logs}"
STATE_FILE="${STATE_DIR}/watchdog.state"
LOG_FILE="${STATE_DIR}/watchdog.log"
PID_FILE="${STATE_DIR}/watchdog.pid"

# Parse arguments
PORT="${DEFAULT_PORT}"
MODE="${DEFAULT_MODE}"
INTERVAL="${DEFAULT_INTERVAL}"
DAEMONIZE="false"
DRY_RUN="false"

usage() {
    cat <<EOF
ClawSuite Watchdog Daemon

Periodically monitors the server and restarts it if unhealthy.

Usage: $(basename "$0") [OPTIONS]

Options:
    -p, --port PORT     Server port (default: ${DEFAULT_PORT})
    -m, --mode MODE     Server mode: 'dev' or 'preview' (default: ${DEFAULT_MODE})
    -i, --interval SEC  Check interval in seconds (default: ${DEFAULT_INTERVAL})
    -d, --daemonize     Run in background as daemon
    -s, --stop          Stop running daemon
    -t, --status        Show daemon status
    -n, --dry-run       Single check without restart (test mode)
    -h, --help          Show this help message

Modes:
    dev      - Monitor 'npm run dev' server
    preview  - Monitor 'npm run preview' server

Exit Codes:
    0 - Normal exit
    1 - Fatal error
    2 - Configuration error

Examples:
    $(basename "$0")                    # Run once, check and restart if needed
    $(basename "$0") --daemonize        # Run as background daemon
    $(basename "$0") --status           # Check daemon status
    $(basename "$0") --stop             # Stop running daemon
    $(basename "$0") --dry-run          # Health check only, no restart
EOF
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Logging function
log() {
    local level="$1"
    local message="$2"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${ts}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

# Check if daemon is running
is_daemon_running() {
    if [[ -f "${PID_FILE}" ]]; then
        local pid
        pid=$(cat "${PID_FILE}" 2>/dev/null)
        if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Show daemon status
show_status() {
    echo "=== ClawSuite Watchdog Status ==="
    
    if is_daemon_running; then
        local pid
        pid=$(cat "${PID_FILE}")
        echo "Daemon Status: RUNNING (PID: ${pid})"
    else
        echo "Daemon Status: NOT RUNNING"
    fi
    
    echo ""
    echo "Last Health Check:"
    if [[ -f "${STATE_FILE}" ]]; then
        cat "${STATE_FILE}" 2>/dev/null || echo "  (unable to read state)"
    else
        echo "  (no state file found)"
    fi
    
    echo ""
    echo "Log File: ${LOG_FILE}"
    if [[ -f "${LOG_FILE}" ]]; then
        echo "Recent log entries:"
        tail -5 "${LOG_FILE}" 2>/dev/null | sed 's/^/  /'
    fi
}

# Stop daemon
stop_daemon() {
    if ! is_daemon_running; then
        echo "Watchdog daemon is not running"
        return 0
    fi
    
    local pid
    pid=$(cat "${PID_FILE}")
    echo "Stopping watchdog daemon (PID: ${pid})..."
    
    kill -TERM "${pid}" 2>/dev/null || true
    
    local waited=0
    while [[ ${waited} -lt 10 ]]; do
        if ! kill -0 "${pid}" 2>/dev/null; then
            rm -f "${PID_FILE}"
            echo "Daemon stopped"
            return 0
        fi
        sleep 1
        ((waited++))
    done
    
    # Force kill if needed
    if kill -0 "${pid}" 2>/dev/null; then
        echo "Force stopping daemon..."
        kill -KILL "${pid}" 2>/dev/null || true
        rm -f "${PID_FILE}"
    fi
    
    echo "Daemon stopped"
    return 0
}

# Health check using watchdog-health.sh
run_health_check() {
    "${SCRIPT_DIR}/watchdog-health.sh" --port "${PORT}" --state
    return $?
}

# Restart using watchdog-restart.sh
run_restart() {
    log "WARN" "Server unhealthy, initiating restart..."
    "${SCRIPT_DIR}/watchdog-restart.sh" --port "${PORT}" --mode "${MODE}"
    return $?
}

# Single check cycle (for dry-run or non-daemon mode)
single_check() {
    log "INFO" "Running single health check (dry-run: ${DRY_RUN})"
    
    if run_health_check; then
        log "INFO" "Health check passed - server is healthy"
        return 0
    else
        if [[ "${DRY_RUN}" == "true" ]]; then
            log "WARN" "Health check failed - would restart in non-dry mode"
            return 1
        else
            log "WARN" "Health check failed - attempting restart"
            if run_restart; then
                log "INFO" "Restart successful"
                return 0
            else
                log "ERROR" "Restart failed"
                return 1
            fi
        fi
    fi
}

# Daemon loop
daemon_loop() {
    log "INFO" "=== Watchdog Daemon Started ==="
    log "INFO" "Port: ${PORT}, Mode: ${MODE}, Interval: ${INTERVAL}s"
    
    # Write PID file
    echo $$ > "${PID_FILE}"
    
    # Track consecutive failures
    local consecutive_failures=0
    local last_failure_time=0
    
    # Cleanup on exit
    trap 'log "INFO" "Received shutdown signal"; rm -f "${PID_FILE}"; exit 0' TERM INT
    
    while true; do
        if run_health_check; then
            # Reset failure counter on success
            if [[ ${consecutive_failures} -gt 0 ]]; then
                log "INFO" "Health recovered after ${consecutive_failures} failure(s)"
            fi
            consecutive_failures=0
        else
            local now
            now=$(date +%s)
            
            # Reset failures if enough time has passed
            if [[ $((now - last_failure_time)) -gt ${FAILURE_RESET_AFTER} ]]; then
                consecutive_failures=0
            fi
            
            ((consecutive_failures++))
            last_failure_time=${now}
            
            log "WARN" "Health check failed (${consecutive_failures}/${MAX_FAILURES} consecutive)"
            
            if [[ ${consecutive_failures} -ge ${MAX_FAILURES} ]]; then
                log "ERROR" "Max failures reached, attempting restart..."
                
                if run_restart; then
                    log "INFO" "Restart successful, resetting failure counter"
                    consecutive_failures=0
                else
                    log "ERROR" "Restart failed, will retry next cycle"
                fi
            fi
        fi
        
        sleep "${INTERVAL}"
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -d|--daemonize)
            DAEMONIZE="true"
            shift
            ;;
        -s|--stop)
            stop_daemon
            exit $?
            ;;
        -t|--status)
            show_status
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# Validate mode
if [[ "${MODE}" != "dev" && "${MODE}" != "preview" ]]; then
    echo "ERROR: Invalid mode '${MODE}'. Must be 'dev' or 'preview'." >&2
    exit 2
fi

# Validate interval
if ! [[ "${INTERVAL}" =~ ^[0-9]+$ ]] || [[ "${INTERVAL}" -lt 10 ]]; then
    echo "ERROR: Interval must be a number >= 10 seconds." >&2
    exit 2
fi

# Ensure state directory exists
mkdir -p "${STATE_DIR}"

# Main entry point
if [[ "${DAEMONIZE}" == "true" ]]; then
    if is_daemon_running; then
        echo "Watchdog daemon is already running"
        echo "Use '$(basename "$0") --status' to check status"
        echo "Use '$(basename "$0") --stop' to stop before starting new instance"
        exit 1
    fi
    
    echo "Starting watchdog daemon..."
    daemon_loop &
    disown
    sleep 1
    
    if is_daemon_running; then
        echo "Daemon started (PID: $(cat "${PID_FILE}"))"
    else
        echo "Failed to start daemon - check logs at ${LOG_FILE}"
        exit 1
    fi
else
    # Single check mode
    single_check
    exit $?
fi
