#!/usr/bin/env bash
# ClawSuite Unified Start Script
# Enforces single runtime owner, deterministic port, and clean-start flow
#
# Usage:
#   ./start.sh [OPTIONS]
#
# This is the SINGLE ENTRY POINT for starting ClawSuite.
# All other launch paths should use this script.
#
# Exit codes:
#   0 - Started successfully
#   1 - Failed to start
#   2 - Configuration error
#   3 - Lock contention (another instance starting)

set -euo pipefail

# ============================================================================
# CONFIGURATION - Central place for all defaults
# ============================================================================
DEFAULT_PORT=4173
DEFAULT_HOST="0.0.0.0"
DEFAULT_MODE="preview"
START_TIMEOUT=30
HEALTH_RETRIES=6
HEALTH_INTERVAL=5

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCK_DIR="${PROJECT_ROOT}/logs"
LOCK_FILE="${LOCK_DIR}/clawsuite.lock"
PID_FILE="${LOCK_DIR}/clawsuite.pid"
STATE_FILE="${LOCK_DIR}/watchdog.state"
LOG_FILE="${LOCK_DIR}/start.log"

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================
PORT="${CLAWSUITE_PORT:-${DEFAULT_PORT}}"
HOST="${CLAWSUITE_HOST:-${DEFAULT_HOST}}"
MODE="${DEFAULT_MODE}"
BUILD="true"
CLEAN="false"
FORCE="false"

usage() {
    cat <<EOF
ClawSuite Unified Start Script

This is the SINGLE ENTRY POINT for starting ClawSuite.
Enforces single runtime owner and deterministic startup.

Usage: $(basename "$0") [OPTIONS]

Options:
    -p, --port PORT     Server port (default: ${DEFAULT_PORT}, env: CLAWSUITE_PORT)
    -H, --host HOST     Bind host (default: ${DEFAULT_HOST}, env: CLAWSUITE_HOST)
    -m, --mode MODE     Server mode: 'dev' or 'preview' (default: ${DEFAULT_MODE})
    --no-build          Skip build step (for preview mode)
    --clean             Clean dist/ before building
    -f, --force         Kill existing process on port before starting
    -h, --help          Show this help message

Modes:
    dev      - Development server with hot reload (npm run dev)
    preview  - Production preview (npm run preview, requires build)

Environment Variables:
    CLAWSUITE_PORT      Override default port
    CLAWSUITE_HOST      Override default host

Exit Codes:
    0 - Started successfully
    1 - Failed to start
    2 - Configuration error
    3 - Lock contention (another instance is starting)

Examples:
    $(basename "$0")                     # Start preview on port 4173
    $(basename "$0") --clean --force     # Clean build, kill existing, start fresh
    $(basename "$0") --mode dev          # Start development server
    $(basename "$0") -p 3000             # Start on custom port
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -H|--host)
            HOST="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        --no-build)
            BUILD="false"
            shift
            ;;
        --clean)
            CLEAN="true"
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
            echo "ERROR: Unknown option: $1" >&2
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

# ============================================================================
# LOGGING UTILITIES
# ============================================================================
log() {
    local level="$1"
    local message="$2"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[${ts}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }

# ============================================================================
# LOCK MANAGEMENT - Single Runtime Owner Enforcement
# ============================================================================
acquire_lock() {
    mkdir -p "${LOCK_DIR}"
    
    # Check for existing lock from another start process
    if [[ -f "${LOCK_FILE}" ]]; then
        local lock_pid
        lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "")
        
        if [[ -n "${lock_pid}" ]] && kill -0 "${lock_pid}" 2>/dev/null; then
            error "Another start process is running (PID: ${lock_pid})"
            return 3
        fi
        
        # Stale lock file, remove it
        warn "Removing stale lock file"
        rm -f "${LOCK_FILE}"
    fi
    
    # Acquire lock
    echo $$ > "${LOCK_FILE}"
    trap 'release_lock' EXIT
    info "Lock acquired"
}

release_lock() {
    rm -f "${LOCK_FILE}"
}

# ============================================================================
# PROCESS MANAGEMENT
# ============================================================================
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

kill_process_gracefully() {
    local pid="$1"
    local attempts=0
    local max_attempts=10
    
    info "Stopping process ${pid}..."
    kill -TERM "${pid}" 2>/dev/null || true
    
    while [[ ${attempts} -lt ${max_attempts} ]]; do
        if ! kill -0 "${pid}" 2>/dev/null; then
            info "Process ${pid} stopped gracefully"
            return 0
        fi
        sleep 1
        ((attempts++))
    done
    
    # Force kill if still running
    if kill -0 "${pid}" 2>/dev/null; then
        warn "Force killing process ${pid}"
        kill -KILL "${pid}" 2>/dev/null || true
        sleep 1
    fi
    
    if kill -0 "${pid}" 2>/dev/null; then
        error "Failed to stop process ${pid}"
        return 1
    fi
    
    return 0
}

stop_existing() {
    local existing_pid
    existing_pid=$(find_process_on_port "${PORT}")
    
    if [[ -n "${existing_pid}" ]]; then
        if [[ "${FORCE}" == "true" ]]; then
            warn "Found existing process ${existing_pid} on port ${PORT}, stopping..."
            if ! kill_process_gracefully "${existing_pid}"; then
                error "Failed to stop existing process"
                return 1
            fi
            # Wait for port to be released
            sleep 2
        else
            error "Port ${PORT} is in use by process ${existing_pid}"
            error "Use --force to kill existing process or choose a different port"
            return 1
        fi
    fi
    
    # Also check for stale PID file
    if [[ -f "${PID_FILE}" ]]; then
        local file_pid
        file_pid=$(cat "${PID_FILE}" 2>/dev/null || echo "")
        
        if [[ -n "${file_pid}" ]] && ! kill -0 "${file_pid}" 2>/dev/null; then
            warn "Removing stale PID file"
            rm -f "${PID_FILE}"
        fi
    fi
    
    return 0
}

# ============================================================================
# BUILD MANAGEMENT
# ============================================================================
clean_build() {
    info "Cleaning build artifacts..."
    cd "${PROJECT_ROOT}"
    
    rm -rf dist .vite .tanstack 2>/dev/null || true
    info "Clean complete"
}

run_build() {
    if [[ "${MODE}" != "preview" ]] || [[ "${BUILD}" != "true" ]]; then
        return 0
    fi
    
    info "Building project..."
    cd "${PROJECT_ROOT}"
    
    if ! npm run build >> "${LOG_FILE}" 2>&1; then
        error "Build failed - check ${LOG_FILE} for details"
        return 1
    fi
    
    info "Build complete"
    return 0
}

# ============================================================================
# SERVER START
# ============================================================================
wait_for_healthy() {
    local port="$1"
    local retries="${HEALTH_RETRIES}"
    local interval="${HEALTH_INTERVAL}"
    
    # Use file descriptor 2 (stderr) for logging to avoid polluting stdout
    log_info() {
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [INFO] $1" >> "${LOG_FILE}"
    }
    
    log_info "Waiting for server to be healthy (max $((retries * interval))s)..."
    
    while [[ ${retries} -gt 0 ]]; do
        sleep "${interval}"
        
        # Check if port is listening
        local pid
        pid=$(find_process_on_port "${port}")
        
        if [[ -n "${pid}" ]]; then
            # Try HTTP health check
            if command -v curl &>/dev/null; then
                local response
                response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://127.0.0.1:${port}/" 2>/dev/null) || true
                if [[ "${response}" =~ ^(2[0-9][0-9]|3[0-9][0-9])$ ]]; then
                    log_info "Server is healthy (HTTP ${response})"
                    echo "${pid}"
                    return 0
                fi
            else
                # No curl, just verify port is listening
                log_info "Server is listening (PID: ${pid})"
                echo "${pid}"
                return 0
            fi
        fi
        
        ((retries--))
        log_info "Waiting... (${retries} retries left)"
    done
    
    error "Server did not become healthy within timeout"
    return 1
}

start_server() {
    local mode="$1"
    local port="$2"
    local host="$3"
    
    cd "${PROJECT_ROOT}"
    
    local cmd
    case "${mode}" in
        dev)
            cmd="npm run dev -- --port ${port}"
            ;;
        preview)
            cmd="npm run preview -- --host ${host} --port ${port}"
            ;;
    esac
    
    info "Starting ${mode} server on ${host}:${port}"
    info "Command: ${cmd}"
    
    # Start server in background
    nohup ${cmd} >> "${LOG_FILE}" 2>&1 &
    local start_pid=$!
    
    # Wait for server to be healthy
    local healthy_pid
    if ! healthy_pid=$(wait_for_healthy "${port}"); then
        # Check if the process is still running
        if kill -0 ${start_pid} 2>/dev/null; then
            warn "Process ${start_pid} is running but not healthy, stopping..."
            kill -TERM ${start_pid} 2>/dev/null || true
        fi
        return 1
    fi
    
    # Write PID file
    echo "${healthy_pid}" > "${PID_FILE}"
    info "PID file written: ${PID_FILE} -> ${healthy_pid}"
    
    # Update state file
    cat > "${STATE_FILE}" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "host": "${host}",
  "port": ${port},
  "port_status": "listening",
  "http_status": "healthy",
  "healthy": true,
  "pid": ${healthy_pid},
  "mode": "${mode}",
  "error": null
}
EOF
    
    info "State file updated: ${STATE_FILE}"
    
    return 0
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    info "=== ClawSuite Start ==="
    info "Mode: ${MODE}, Port: ${PORT}, Host: ${HOST}"
    info "Build: ${BUILD}, Clean: ${CLEAN}, Force: ${FORCE}"
    
    # Acquire lock to prevent concurrent starts
    if ! acquire_lock; then
        exit 3
    fi
    
    # Stop existing process if needed
    if ! stop_existing; then
        exit 1
    fi
    
    # Clean if requested
    if [[ "${CLEAN}" == "true" ]]; then
        if ! clean_build; then
            exit 1
        fi
    fi
    
    # Build if needed
    if ! run_build; then
        exit 1
    fi
    
    # Start server
    if ! start_server "${MODE}" "${PORT}" "${HOST}"; then
        exit 1
    fi
    
    info "=== ClawSuite Started Successfully ==="
    echo ""
    echo "ClawSuite is running at: http://${HOST}:${PORT}"
    echo "PID: $(cat "${PID_FILE}")"
    echo "Logs: ${LOG_FILE}"
    echo ""
    echo "To stop: pkill -f 'vite.*${PORT}'"
    
    return 0
}

main
