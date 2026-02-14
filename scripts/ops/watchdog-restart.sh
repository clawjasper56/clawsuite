#!/usr/bin/env bash
# ClawSuite Watchdog Restart/Recovery
# Restarts the preview/dev server process with recovery logic
#
# Usage:
#   ./watchdog-restart.sh [--port PORT] [--mode MODE] [--dry-run] [--help]
#
# Exit codes:
#   0 - Restart successful
#   1 - Restart failed
#   2 - Configuration error

set -euo pipefail

# Configuration
DEFAULT_PORT=3000
DEFAULT_MODE="preview"
TIMEOUT_SECONDS=30
WAIT_AFTER_START=10
MAX_RESTART_ATTEMPTS=3
STATE_DIR="${STATE_DIR:-$(dirname "$0")/../../logs}"
STATE_FILE="${STATE_DIR}/watchdog.state"
LOG_FILE="${STATE_DIR}/watchdog.log"

# Parse arguments
PORT="${DEFAULT_PORT}"
MODE="${DEFAULT_MODE}"
DRY_RUN="false"
FORCE="false"

usage() {
    cat <<EOF
ClawSuite Watchdog Restart/Recovery

Usage: $(basename "$0") [OPTIONS]

Options:
    -p, --port PORT     Port for the server (default: ${DEFAULT_PORT})
    -m, --mode MODE     Server mode: 'dev' or 'preview' (default: ${DEFAULT_MODE})
    -n, --dry-run       Show what would be done without executing
    -f, --force         Force restart even if currently healthy
    -h, --help          Show this help message

Modes:
    dev      - Run 'npm run dev' (development server on port 3000)
    preview  - Run 'npm run preview' (preview built app, requires build first)

Exit Codes:
    0 - Restart successful (or dry-run completed)
    1 - Restart failed
    2 - Configuration error

Examples:
    $(basename "$0")                    # Restart preview server
    $(basename "$0") --mode dev         # Restart dev server
    $(basename "$0") --dry-run          # Show what would happen
    $(basename "$0") --force            # Force restart regardless of health
EOF
}

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
        -n|--dry-run)
            DRY_RUN="true"
            shift
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

# Ensure state directory exists
mkdir -p "${STATE_DIR}"

# Get script directory for relative paths
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

# Kill process gracefully, then forcefully if needed
kill_process() {
    local pid="$1"
    local attempts=0
    local max_attempts=10
    
    log "INFO" "Stopping process ${pid}"
    
    # Try graceful termination first
    kill -TERM "${pid}" 2>/dev/null || true
    
    while [[ ${attempts} -lt ${max_attempts} ]]; do
        if ! kill -0 "${pid}" 2>/dev/null; then
            log "INFO" "Process ${pid} stopped gracefully"
            return 0
        fi
        sleep 1
        ((attempts++))
    done
    
    # Force kill if still running
    if kill -0 "${pid}" 2>/dev/null; then
        log "WARN" "Force killing process ${pid}"
        kill -KILL "${pid}" 2>/dev/null || true
        sleep 1
    fi
    
    if kill -0 "${pid}" 2>/dev/null; then
        log "ERROR" "Failed to stop process ${pid}"
        return 1
    fi
    
    return 0
}

# Start server in background
start_server() {
    local mode="$1"
    local port="$2"
    
    log "INFO" "Starting ${mode} server on port ${port}"
    
    # Build first if preview mode
    if [[ "${mode}" == "preview" ]]; then
        log "INFO" "Ensuring build exists..."
        if [[ "${DRY_RUN}" == "true" ]]; then
            echo "DRY-RUN: Would run: npm run build"
        else
            npm run build --prefix "${PROJECT_ROOT}" >> "${LOG_FILE}" 2>&1 || {
                log "ERROR" "Build failed, cannot start preview server"
                return 1
            }
        fi
    fi
    
    # Start server
    local cmd
    case "${mode}" in
        dev)
            cmd="npm run dev"
            ;;
        preview)
            cmd="npm run preview -- --port ${port}"
            ;;
    esac
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "DRY-RUN: Would run: ${cmd}"
        return 0
    fi
    
    cd "${PROJECT_ROOT}"
    nohup ${cmd} >> "${LOG_FILE}" 2>&1 &
    local start_pid=$!
    
    log "INFO" "Server started with PID ${start_pid}"
    
    # Wait for server to be ready
    log "INFO" "Waiting up to ${WAIT_AFTER_START}s for server to be ready..."
    local waited=0
    while [[ ${waited} -lt ${WAIT_AFTER_START} ]]; do
        sleep 1
        ((waited++))
        
        # Check if process is still running
        if ! kill -0 ${start_pid} 2>/dev/null; then
            log "ERROR" "Server process ${start_pid} exited unexpectedly"
            return 1
        fi
        
        # Check if port is listening
        local listening_pid
        listening_pid=$(find_process_on_port "${port}")
        if [[ -n "${listening_pid}" ]]; then
            log "INFO" "Server is listening on port ${port} (PID: ${listening_pid})"
            
            # Update state file
            cat > "${STATE_FILE}" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "host": "localhost",
  "port": ${port},
  "port_status": "listening",
  "http_status": "healthy",
  "healthy": true,
  "pid": ${listening_pid},
  "mode": "${mode}",
  "error": null
}
EOF
            return 0
        fi
    done
    
    log "ERROR" "Server did not start listening within ${WAIT_AFTER_START}s"
    return 1
}

# Main restart logic
main() {
    log "INFO" "=== ClawSuite Restart/Recovery ==="
    log "INFO" "Mode: ${MODE}, Port: ${PORT}, Dry-run: ${DRY_RUN}, Force: ${FORCE}"
    
    # Check current state
    local current_pid
    current_pid=$(find_process_on_port "${PORT}")
    
    if [[ -n "${current_pid}" ]]; then
        log "INFO" "Found existing process ${current_pid} on port ${PORT}"
        
        if [[ "${DRY_RUN}" == "true" ]]; then
            echo "DRY-RUN: Would stop process ${current_pid}"
            echo "DRY-RUN: Would start ${MODE} server on port ${PORT}"
            exit 0
        fi
        
        # Stop existing process
        if ! kill_process "${current_pid}"; then
            log "ERROR" "Failed to stop existing process"
            exit 1
        fi
        
        # Brief pause to ensure port is released
        sleep 2
    else
        log "INFO" "No process found on port ${PORT}"
        
        if [[ "${DRY_RUN}" == "true" ]]; then
            echo "DRY-RUN: Would start ${MODE} server on port ${PORT}"
            exit 0
        fi
    fi
    
    # Start new server
    if ! start_server "${MODE}" "${PORT}"; then
        log "ERROR" "Failed to start ${MODE} server"
        
        # Update state file to reflect failure
        cat > "${STATE_FILE}" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "host": "localhost",
  "port": ${PORT},
  "port_status": "not_listening",
  "http_status": "unhealthy",
  "healthy": false,
  "pid": null,
  "mode": "${MODE}",
  "error": "Failed to start server"
}
EOF
        exit 1
    fi
    
    log "INFO" "Restart completed successfully"
    exit 0
}

main
