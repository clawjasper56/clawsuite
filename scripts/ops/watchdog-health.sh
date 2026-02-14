#!/usr/bin/env bash
# ClawSuite Watchdog Health Check
# Checks the health of preview/dev server process
#
# Usage:
#   ./watchdog-health.sh [--port PORT] [--json] [--help]
#
# Exit codes:
#   0 - Healthy
#   1 - Unhealthy (process not running or not responding)
#   2 - Error during check

set -euo pipefail

# Configuration
DEFAULT_PORT=3000
DEFAULT_HOST="localhost"
TIMEOUT_SECONDS=5
STATE_DIR="${STATE_DIR:-$(dirname "$0")/../../logs}"
STATE_FILE="${STATE_DIR}/watchdog.state"

# Output format
OUTPUT_FORMAT="text"

# Parse arguments
PORT="${DEFAULT_PORT}"
HOST="${DEFAULT_HOST}"

usage() {
    cat <<EOF
ClawSuite Watchdog Health Check

Usage: $(basename "$0") [OPTIONS]

Options:
    -p, --port PORT     Port to check (default: ${DEFAULT_PORT})
    -H, --host HOST     Host to check (default: ${DEFAULT_HOST})
    -j, --json          Output in JSON format
    -s, --state         Update state file after check
    -h, --help          Show this help message

Exit Codes:
    0 - Service is healthy
    1 - Service is unhealthy
    2 - Error during health check

Examples:
    $(basename "$0")                    # Check localhost:3000
    $(basename "$0") --port 4173        # Check preview server
    $(basename "$0") --json --state     # JSON output, update state file
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
        -j|--json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        -s|--state)
            UPDATE_STATE="true"
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

# Ensure state directory exists
mkdir -p "${STATE_DIR}"

# Timestamp for logging
timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Check if process is listening on port
check_port_listening() {
    local host="$1"
    local port="$2"
    
    # Try ss first (more modern), fall back to netstat
    if command -v ss &>/dev/null; then
        ss -tln 2>/dev/null | grep -q ":${port} " || return 1
    elif command -v netstat &>/dev/null; then
        netstat -tln 2>/dev/null | grep -q ":${port} " || return 1
    elif command -v lsof &>/dev/null; then
        lsof -i ":${port}" -sTCP:LISTEN 2>/dev/null | grep -q LISTEN || return 1
    else
        # Fallback: try to connect
        if command -v nc &>/dev/null; then
            nc -z -w "${TIMEOUT_SECONDS}" "${host}" "${port}" 2>/dev/null || return 1
        elif command -v timeout &>/dev/null; then
            timeout "${TIMEOUT_SECONDS}" bash -c "echo >/dev/tcp/${host}/${port}" 2>/dev/null || return 1
        else
            echo "ERROR: No tool available to check port" >&2
            return 2
        fi
    fi
    return 0
}

# HTTP health check
check_http_health() {
    local host="$1"
    local port="$2"
    local url="http://${host}:${port}/"
    
    # Try curl first, then wget
    if command -v curl &>/dev/null; then
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "${TIMEOUT_SECONDS}" "${url}" 2>/dev/null) || return 1
        [[ "${response_code}" =~ ^(2[0-9][0-9]|3[0-9][0-9])$ ]] && return 0
        return 1
    elif command -v wget &>/dev/null; then
        wget -q --spider --timeout="${TIMEOUT_SECONDS}" "${url}" 2>/dev/null && return 0
        return 1
    else
        echo "ERROR: Neither curl nor wget available for HTTP check" >&2
        return 2
    fi
}

# Find running Node/Vite process
find_server_process() {
    local port="$1"
    local pid=""
    
    # Find process listening on port
    if command -v lsof &>/dev/null; then
        pid=$(lsof -t -i ":${port}" -sTCP:LISTEN 2>/dev/null | head -1)
    elif command -v ss &>/dev/null; then
        local line
        line=$(ss -tlnp 2>/dev/null | grep ":${port} " | head -1)
        if [[ -n "${line}" ]]; then
            pid=$(echo "${line}" | grep -oP 'pid=\K[0-9]+' | head -1)
        fi
    fi
    
    echo "${pid}"
}

# Main health check logic
perform_health_check() {
    local ts
    ts=$(timestamp)
    
    local port_status="unknown"
    local http_status="unknown"
    local pid=""
    local healthy="false"
    local error_msg=""
    
    # Check port listening
    if check_port_listening "${HOST}" "${PORT}"; then
        port_status="listening"
        pid=$(find_server_process "${PORT}")
    else
        port_status="not_listening"
        error_msg="Port ${PORT} is not listening"
    fi
    
    # Check HTTP health if port is listening
    if [[ "${port_status}" == "listening" ]]; then
        if check_http_health "${HOST}" "${PORT}"; then
            http_status="healthy"
            healthy="true"
        else
            http_status="unhealthy"
            error_msg="HTTP check failed on port ${PORT}"
        fi
    fi
    
    # Build JSON error field
    local error_json="null"
    if [[ -n "${error_msg}" ]]; then
        error_json="\"${error_msg}\""
    fi
    
    # Output results
    case "${OUTPUT_FORMAT}" in
        json)
            cat <<EOF
{
  "timestamp": "${ts}",
  "host": "${HOST}",
  "port": ${PORT},
  "port_status": "${port_status}",
  "http_status": "${http_status}",
  "healthy": ${healthy},
  "pid": ${pid:-null},
  "error": ${error_json}
}
EOF
            ;;
        text)
            echo "=== ClawSuite Health Check ==="
            echo "Timestamp: ${ts}"
            echo "Target: ${HOST}:${PORT}"
            echo "Port Status: ${port_status}"
            echo "HTTP Status: ${http_status}"
            echo "PID: ${pid:-N/A}"
            if [[ "${healthy}" == "true" ]]; then
                echo "Result: HEALTHY"
            else
                echo "Result: UNHEALTHY - ${error_msg}"
            fi
            ;;
    esac
    
    # Update state file if requested
    if [[ "${UPDATE_STATE:-}" == "true" ]]; then
        cat > "${STATE_FILE}" <<EOF
{
  "timestamp": "${ts}",
  "host": "${HOST}",
  "port": ${PORT},
  "port_status": "${port_status}",
  "http_status": "${http_status}",
  "healthy": ${healthy},
  "pid": ${pid:-null},
  "error": ${error_json}
}
EOF
    fi
    
    # Return appropriate exit code
    if [[ "${healthy}" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Run health check
perform_health_check
