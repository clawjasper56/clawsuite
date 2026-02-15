#!/usr/bin/env bash
# ClawSuite Health Endpoint Server
# Exposes machine-readable JSON health contract via HTTP
#
# Usage:
#   ./health-endpoint.sh [--port HEALTH_PORT] [--target-port APP_PORT] [--daemonize]
#
# This creates a lightweight HTTP server that exposes:
#   GET /health          - Full health status (JSON)
#   GET /health/ready    - Readiness probe (200/503)
#   GET /health/live     - Liveness probe (200/503)
#   GET /health/version  - Version info (JSON)
#
# Exit codes:
#   0 - Started successfully
#   1 - Failed to start
#   2 - Configuration error

set -euo pipefail

# Configuration
DEFAULT_HEALTH_PORT=4180
DEFAULT_TARGET_PORT=4173
DEFAULT_HOST="localhost"
VERSION="1.0.0"
CONTRACT_VERSION="2026-02-15"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STATE_DIR="${PROJECT_ROOT}/logs"
PID_FILE="${STATE_DIR}/health-endpoint.pid"
LOG_FILE="${STATE_DIR}/health-endpoint.log"

# Parse arguments
HEALTH_PORT="${CLAWSUITE_HEALTH_PORT:-${DEFAULT_HEALTH_PORT}}"
TARGET_PORT="${CLAWSUITE_PORT:-${DEFAULT_TARGET_PORT}}"
TARGET_HOST="${CLAWSUITE_HOST:-${DEFAULT_HOST}}"
DAEMONIZE="false"

usage() {
    cat <<EOF
ClawSuite Health Endpoint Server

Exposes a machine-readable JSON health contract via HTTP.

Usage: $(basename "$0") [OPTIONS]

Options:
    -p, --port PORT       Health endpoint port (default: ${DEFAULT_HEALTH_PORT})
    -t, --target PORT     Target app port to monitor (default: ${DEFAULT_TARGET_PORT})
    -H, --host HOST       Target host (default: ${DEFAULT_HOST})
    -d, --daemonize       Run in background
    -s, --stop            Stop running health endpoint
    -h, --help            Show this help message

Endpoints:
    GET /health           Full health status (JSON)
    GET /health/ready     Readiness probe (200=ready, 503=not ready)
    GET /health/live      Liveness probe (200=alive, 503=dead)
    GET /health/version   Version and contract info (JSON)

Environment Variables:
    CLAWSUITE_HEALTH_PORT   Health endpoint port
    CLAWSUITE_PORT          Target app port
    CLAWSUITE_HOST          Target host

Exit Codes:
    0 - Success
    1 - Failed to start/stop
    2 - Configuration error

Examples:
    $(basename "$0")                    # Start health endpoint on port 4180
    $(basename "$0") --daemonize        # Run in background
    $(basename "$0") --stop             # Stop running health endpoint
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            HEALTH_PORT="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_PORT="$2"
            shift 2
            ;;
        -H|--host)
            TARGET_HOST="$2"
            shift 2
            ;;
        -d|--daemonize)
            DAEMONIZE="true"
            shift
            ;;
        -s|--stop)
            stop_health_endpoint
            exit $?
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

# Ensure state directory exists
mkdir -p "${STATE_DIR}"

# ============================================================================
# HEALTH CHECK FUNCTIONS
# ============================================================================

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

check_port_listening() {
    local port="$1"
    local host="${2:-localhost}"
    
    if command -v nc &>/dev/null; then
        nc -z -w 2 "${host}" "${port}" 2>/dev/null && return 0
    elif command -v timeout &>/dev/null; then
        timeout 2 bash -c "echo >/dev/tcp/${host}/${port}" 2>/dev/null && return 0
    fi
    return 1
}

check_http_health() {
    local port="$1"
    local host="${2:-localhost}"
    
    if command -v curl &>/dev/null; then
        local code
        code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://${host}:${port}/" 2>/dev/null) || return 1
        [[ "${code}" =~ ^(2[0-9][0-9]|3[0-9][0-9])$ ]] && return 0
    elif command -v wget &>/dev/null; then
        wget -q --spider --timeout=3 "http://${host}:${port}/" 2>/dev/null && return 0
    fi
    return 1
}

find_process() {
    local port="$1"
    local pid=""
    
    if command -v lsof &>/dev/null; then
        pid=$(lsof -t -i ":${port}" -sTCP:LISTEN 2>/dev/null | head -1)
    elif command -v ss &>/dev/null; then
        local line
        line=$(ss -tlnp 2>/dev/null | grep ":${port} " | head -1)
        [[ -n "${line}" ]] && pid=$(echo "${line}" | grep -oP 'pid=\K[0-9]+' | head -1)
    fi
    
    echo "${pid:-null}"
}

# Get package version if available
get_app_version() {
    local pkg_file="${PROJECT_ROOT}/package.json"
    if [[ -f "${pkg_file}" ]]; then
        grep -oP '"version"\s*:\s*"\K[^"]+' "${pkg_file}" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Build full health response
build_health_json() {
    local ts
    ts=$(timestamp)
    
    local port_status="not_listening"
    local http_status="unhealthy"
    local healthy="false"
    local pid="null"
    local error="null"
    local app_version
    app_version=$(get_app_version)
    
    # Check port
    if check_port_listening "${TARGET_PORT}" "${TARGET_HOST}"; then
        port_status="listening"
        pid=$(find_process "${TARGET_PORT}")
    else
        error="\"Port ${TARGET_PORT} is not listening\""
    fi
    
    # Check HTTP
    if [[ "${port_status}" == "listening" ]]; then
        if check_http_health "${TARGET_PORT}" "${TARGET_HOST}"; then
            http_status="healthy"
            healthy="true"
        else
            error="\"HTTP check failed on port ${TARGET_PORT}\""
        fi
    fi
    
    cat <<EOF
{
  "contract_version": "${CONTRACT_VERSION}",
  "timestamp": "${ts}",
  "service": {
    "name": "clawsuite",
    "version": "${app_version}",
    "mode": "preview"
  },
  "status": {
    "healthy": ${healthy},
    "port_status": "${port_status}",
    "http_status": "${http_status}",
    "pid": ${pid}
  },
  "checks": {
    "port": {
      "status": "${port_status}",
      "target": "${TARGET_HOST}:${TARGET_PORT}"
    },
    "http": {
      "status": "${http_status}",
      "target": "http://${TARGET_HOST}:${TARGET_PORT}/"
    }
  },
  "error": ${error}
}
EOF
}

# Build version response
build_version_json() {
    local app_version
    app_version=$(get_app_version)
    
    cat <<EOF
{
  "contract_version": "${CONTRACT_VERSION}",
  "endpoint_version": "${VERSION}",
  "service": {
    "name": "clawsuite",
    "version": "${app_version}"
  }
}
EOF
}

# ============================================================================
# HTTP SERVER (using bash + nc)
# ============================================================================

stop_health_endpoint() {
    if [[ -f "${PID_FILE}" ]]; then
        local pid
        pid=$(cat "${PID_FILE}")
        if kill -0 "${pid}" 2>/dev/null; then
            kill "${pid}" 2>/dev/null
            rm -f "${PID_FILE}"
            echo "Health endpoint stopped (PID: ${pid})"
            return 0
        else
            rm -f "${PID_FILE}"
            echo "Health endpoint was not running (stale PID file removed)"
            return 0
        fi
    else
        echo "Health endpoint is not running"
        return 0
    fi
}

handle_request() {
    local request="$1"
    local path
    path=$(echo "$request" | head -1 | awk '{print $2}')
    
    local status="200"
    local body=""
    local content_type="application/json"
    
    case "${path}" in
        /health|/health/)
            body=$(build_health_json)
            ;;
        /health/ready)
            local health_json
            health_json=$(build_health_json)
            if echo "${health_json}" | grep -q '"healthy": true'; then
                status="200"
                body='{"ready":true}'
            else
                status="503"
                body='{"ready":false}'
            fi
            ;;
        /health/live)
            # Liveness is always true if this endpoint is responding
            body='{"alive":true}'
            ;;
        /health/version)
            body=$(build_version_json)
            ;;
        *)
            status="404"
            body='{"error":"not_found"}'
            ;;
    esac
    
    local length=${#body}
    
    echo -e "HTTP/1.1 ${status} OK\r"
    echo -e "Content-Type: ${content_type}\r"
    echo -e "Content-Length: ${length}\r"
    echo -e "Connection: close\r"
    echo -e "\r"
    echo -n "${body}"
}

run_server() {
    echo "Starting health endpoint on port ${HEALTH_PORT}..."
    echo "Monitoring: ${TARGET_HOST}:${TARGET_PORT}"
    echo "Endpoints: /health, /health/ready, /health/live, /health/version"
    echo "PID: $$"
    
    # Write PID file
    echo $$ > "${PID_FILE}"
    
    # Cleanup on exit
    trap 'rm -f "${PID_FILE}"; exit 0' INT TERM EXIT
    
    # Use while loop with nc for each connection
    while true; do
        if command -v nc &>/dev/null; then
            # GNU netcat or OpenBSD netcat
            request=$(nc -l -p "${HEALTH_PORT}" -q 1 2>/dev/null || nc -l "${HEALTH_PORT}" 2>/dev/null) || true
            if [[ -n "${request}" ]]; then
                response=$(handle_request "${request}")
                echo "${response}" | nc -q 0 "${TARGET_HOST}" "${HEALTH_PORT}" 2>/dev/null || true
            fi
        else
            echo "ERROR: nc (netcat) is required for health endpoint" >&2
            exit 1
        fi
    done
}

# Alternative: Python one-liner server (more reliable)
run_python_server() {
    local port="${HEALTH_PORT}"
    
    cat > "${STATE_DIR}/health_server.py" <<'PYTHON_EOF'
#!/usr/bin/env python3
import http.server
import json
import socketserver
import subprocess
import os

PORT = int(os.environ.get('HEALTH_PORT', 4180))
TARGET_PORT = int(os.environ.get('TARGET_PORT', 4173))
TARGET_HOST = os.environ.get('TARGET_HOST', 'localhost')
PROJECT_ROOT = os.environ.get('PROJECT_ROOT', '.')

def get_health():
    import socket
    import urllib.request
    
    ts = __import__('datetime').datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    
    port_status = "not_listening"
    http_status = "unhealthy"
    healthy = False
    error = None
    
    # Check port
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)
    result = sock.connect_ex((TARGET_HOST, TARGET_PORT))
    sock.close()
    
    if result == 0:
        port_status = "listening"
        try:
            req = urllib.request.Request(f'http://{TARGET_HOST}:{TARGET_PORT}/', method='GET')
            urllib.request.urlopen(req, timeout=3)
            http_status = "healthy"
            healthy = True
        except Exception as e:
            error = f"HTTP check failed: {str(e)}"
    else:
        error = f"Port {TARGET_PORT} is not listening"
    
    # Get app version
    try:
        with open(os.path.join(PROJECT_ROOT, 'package.json')) as f:
            pkg = json.load(f)
            app_version = pkg.get('version', 'unknown')
    except:
        app_version = 'unknown'
    
    return {
        "contract_version": "2026-02-15",
        "timestamp": ts,
        "service": {"name": "clawsuite", "version": app_version, "mode": "preview"},
        "status": {"healthy": healthy, "port_status": port_status, "http_status": http_status},
        "checks": {
            "port": {"status": port_status, "target": f"{TARGET_HOST}:{TARGET_PORT}"},
            "http": {"status": http_status, "target": f"http://{TARGET_HOST}:{TARGET_PORT}/"}
        },
        "error": error
    }

class HealthHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress logging
    
    def send_json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(body))
        self.end_headers()
        self.wfile.write(body)
    
    def do_GET(self):
        if self.path in ('/health', '/health/'):
            self.send_json(get_health())
        elif self.path == '/health/ready':
            h = get_health()
            self.send_json({"ready": h["status"]["healthy"]}, 200 if h["status"]["healthy"] else 503)
        elif self.path == '/health/live':
            self.send_json({"alive": True})
        elif self.path == '/health/version':
            self.send_json({"contract_version": "2026-02-15", "endpoint_version": "1.0.0"})
        else:
            self.send_json({"error": "not_found"}, 404)

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), HealthHandler) as httpd:
        print(f"Health endpoint running on port {PORT}")
        httpd.serve_forever()
PYTHON_EOF

    export HEALTH_PORT TARGET_PORT TARGET_HOST PROJECT_ROOT
    python3 "${STATE_DIR}/health_server.py"
}

# ============================================================================
# MAIN
# ============================================================================

# Prefer Python server if available (more reliable HTTP)
if command -v python3 &>/dev/null; then
    if [[ "${DAEMONIZE}" == "true" ]]; then
        export HEALTH_PORT TARGET_PORT TARGET_HOST PROJECT_ROOT
        nohup python3 "${STATE_DIR}/health_server.py" >> "${LOG_FILE}" 2>&1 &
        echo $! > "${PID_FILE}"
        echo "Health endpoint started in background (PID: $(cat ${PID_FILE}))"
        echo "URL: http://localhost:${HEALTH_PORT}/health"
    else
        run_python_server
    fi
else
    if [[ "${DAEMONIZE}" == "true" ]]; then
        nohup "$0" --port "${HEALTH_PORT}" --target "${TARGET_PORT}" >> "${LOG_FILE}" 2>&1 &
        echo $! > "${PID_FILE}"
        echo "Health endpoint started in background (PID: $(cat ${PID_FILE}))"
    else
        run_server
    fi
fi
