#!/usr/bin/env bash
# ClawSuite deterministic rollback script
# Rolls back to an explicit git commit/tag, or deterministically to first-parent HEAD~N.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
STATE_FILE="${LOG_DIR}/rollback.state"

MODE="preview"
PORT="${CLAWSUITE_PORT:-4173}"
TARGET_REF=""
STEPS=1
DRY_RUN="false"
FORCE="false"

usage() {
  cat <<EOF
ClawSuite deterministic rollback

Usage: $(basename "$0") [OPTIONS]

Options:
  --to REF           Roll back to explicit commit/tag REF
  --steps N          Roll back to first-parent HEAD~N (default: 1)
  --mode MODE        Start mode after rollback: dev|preview (default: preview)
  --port PORT        Port to use for restart (default: 4173)
  --dry-run          Print deterministic plan only
  --force            Allow rollback with local uncommitted changes
  -h, --help         Show help

Exit codes:
  0 success
  1 failure
  2 invalid input
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --to)
      TARGET_REF="$2"; shift 2 ;;
    --steps)
      STEPS="$2"; shift 2 ;;
    --mode)
      MODE="$2"; shift 2 ;;
    --port)
      PORT="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN="true"; shift ;;
    --force)
      FORCE="true"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERROR: Unknown option $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [[ "${MODE}" != "dev" && "${MODE}" != "preview" ]]; then
  echo "ERROR: --mode must be dev or preview" >&2
  exit 2
fi

if ! [[ "${STEPS}" =~ ^[0-9]+$ ]] || [[ "${STEPS}" -lt 1 ]]; then
  echo "ERROR: --steps must be an integer >= 1" >&2
  exit 2
fi

cd "${PROJECT_ROOT}"
mkdir -p "${LOG_DIR}"

CURRENT_REF="$(git rev-parse HEAD)"
if [[ -n "${TARGET_REF}" ]]; then
  RESOLVED_TARGET="$(git rev-parse --verify "${TARGET_REF}^{commit}" 2>/dev/null || true)"
else
  RESOLVED_TARGET="$(git rev-parse --verify "HEAD~${STEPS}^{commit}" 2>/dev/null || true)"
fi

if [[ -z "${RESOLVED_TARGET}" ]]; then
  echo "ERROR: Unable to resolve rollback target" >&2
  exit 2
fi

if [[ "${CURRENT_REF}" == "${RESOLVED_TARGET}" ]]; then
  echo "INFO: Current ref already matches target (${CURRENT_REF})"
  exit 0
fi

DIRTY="false"
if ! git diff --quiet || ! git diff --cached --quiet; then
  DIRTY="true"
fi

if [[ "${DIRTY}" == "true" && "${FORCE}" != "true" ]]; then
  echo "ERROR: Working tree has uncommitted changes. Commit/stash or use --force." >&2
  exit 1
fi

PLAN="rollback ${CURRENT_REF} -> ${RESOLVED_TARGET}, mode=${MODE}, port=${PORT}"
echo "PLAN: ${PLAN}"

if [[ "${DRY_RUN}" == "true" ]]; then
  exit 0
fi

"${SCRIPT_DIR}/stop.sh" --port "${PORT}" --force || true

git checkout --force "${RESOLVED_TARGET}"

npm ci
if [[ "${MODE}" == "preview" ]]; then
  npm run build
fi

"${SCRIPT_DIR}/start.sh" --mode "${MODE}" --port "${PORT}" --force

if ! "${SCRIPT_DIR}/watchdog-health.sh" --host localhost --port "${PORT}" --json >/tmp/clawsuite-rollback-health.json; then
  cat > "${STATE_FILE}" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "failed",
  "from": "${CURRENT_REF}",
  "to": "${RESOLVED_TARGET}",
  "mode": "${MODE}",
  "port": ${PORT},
  "error": "Post-rollback health check failed"
}
EOF
  echo "ERROR: Rollback target failed health check" >&2
  exit 1
fi

cat > "${STATE_FILE}" <<EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "ok",
  "from": "${CURRENT_REF}",
  "to": "${RESOLVED_TARGET}",
  "mode": "${MODE}",
  "port": ${PORT},
  "health": $(cat /tmp/clawsuite-rollback-health.json)
}
EOF

echo "Rollback successful: ${CURRENT_REF} -> ${RESOLVED_TARGET}"
echo "State recorded at ${STATE_FILE}"
