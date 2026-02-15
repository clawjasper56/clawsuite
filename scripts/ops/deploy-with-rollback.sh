#!/usr/bin/env bash
# ClawSuite Deterministic Rollback Mechanism
# Provides atomic deployments with automatic rollback on failure
#
# Usage:
#   ./deploy-with-rollback.sh [COMMAND] [OPTIONS]
#
# Commands:
#   deploy     - Execute deployment with rollback on failure
#   rollback   - Rollback to last known-good state
#   status     - Show current deployment status
#   journal    - View transaction journal
#   verify     - Verify current state matches journal
#
# Exit codes:
#   0 - Success
#   1 - Failure (deployment or rollback failed)
#   2 - Configuration error

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
JOURNAL_DIR="${PROJECT_ROOT}/logs/deploy-journal"
STATE_DIR="${PROJECT_ROOT}/logs"
BACKUP_DIR="${PROJECT_ROOT}/backups"

# Journal files
JOURNAL_FILE="${JOURNAL_DIR}/transactions.jsonl"
CURRENT_STATE="${JOURNAL_DIR}/current-state.json"
LOCK_FILE="${JOURNAL_DIR}/deploy.lock"

# Health check settings
HEALTH_PORT="${CLAWSUITE_HEALTH_PORT:-4180}"
HEALTH_RETRIES=6
HEALTH_INTERVAL=5
HEALTH_TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITIES
# ============================================================================

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log() {
    local level="$1"
    local message="$2"
    local ts
    ts=$(timestamp)
    echo -e "[${ts}] [${level}] ${message}"
}

info() { log "INFO" "${BLUE}${1}${NC}"; }
success() { log "SUCCESS" "${GREEN}${1}${NC}"; }
warn() { log "WARN" "${YELLOW}${1}${NC}"; }
error() { log "ERROR" "${RED}${1}${NC}"; }

usage() {
    cat <<EOF
ClawSuite Deterministic Rollback Mechanism v${VERSION}

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  deploy [OPTIONS]     Execute deployment with automatic rollback
    --pre-build        Run npm build before deployment
    --no-health-check  Skip post-deployment health verification
    --timeout SEC      Health check timeout (default: ${HEALTH_TIMEOUT})
    
  rollback [OPTIONS]   Rollback to previous state
    --to TX_ID         Rollback to specific transaction ID
    --force            Force rollback even if verification fails
    
  status               Show current deployment status
  journal [N]          Show last N transactions (default: 10)
  verify               Verify current state matches journal
  init                 Initialize journal (first-time setup)

Options:
  -h, --help           Show this help message
  -v, --verbose        Enable verbose output

Exit Codes:
  0 - Success
  1 - Failure
  2 - Configuration error

Examples:
  $(basename "$0") deploy --pre-build
  $(basename "$0") rollback
  $(basename "$0") rollback --to tx-20260215-120000
  $(basename "$0") status
  $(basename "$0") journal 20
EOF
}

# ============================================================================
# JOURNAL MANAGEMENT
# ============================================================================

init_journal() {
    mkdir -p "${JOURNAL_DIR}" "${BACKUP_DIR}"
    
    if [[ ! -f "${JOURNAL_FILE}" ]]; then
        touch "${JOURNAL_FILE}"
        info "Journal initialized at ${JOURNAL_FILE}"
    fi
    
    if [[ ! -f "${CURRENT_STATE}" ]]; then
        echo '{"status": "initialized", "timestamp": "'$(timestamp)'", "transaction_id": null}' > "${CURRENT_STATE}"
    fi
}

# Generate unique transaction ID
generate_tx_id() {
    echo "tx-$(date +%Y%m%d-%H%M%S)-$${RANDOM:-$((RANDOM % 10000))}"
}

# Append transaction to journal
journal_append() {
    local tx_id="$1"
    local action="$2"
    local status="$3"
    local details="$4"
    
    init_journal
    
    local entry
    entry=$(cat <<EOF
{"tx_id":"${tx_id}","timestamp":"$(timestamp)","action":"${action}","status":"${status}","details":${details}}
EOF
)
    echo "${entry}" >> "${JOURNAL_FILE}"
}

# Update current state
update_current_state() {
    local status="$1"
    local tx_id="$2"
    local version="$3"
    
    cat > "${CURRENT_STATE}" <<EOF
{
  "status": "${status}",
  "timestamp": "$(timestamp)",
  "transaction_id": "${tx_id}",
  "version": "${version}"
}
EOF
}

# Get last successful transaction
get_last_successful_tx() {
    if [[ ! -f "${JOURNAL_FILE}" ]]; then
        echo ""
        return
    fi
    
    tac "${JOURNAL_FILE}" | grep -m1 '"status":"success"' | jq -r '.tx_id' 2>/dev/null || echo ""
}

# Get transaction by ID
get_tx_by_id() {
    local tx_id="$1"
    grep "\"tx_id\":\"${tx_id}\"" "${JOURNAL_FILE}" 2>/dev/null | tail -1 || echo ""
}

# ============================================================================
# BACKUP/RESTORE
# ============================================================================

create_backup() {
    local tx_id="$1"
    local backup_path="${BACKUP_DIR}/${tx_id}"
    
    mkdir -p "${backup_path}"
    
    # Backup dist folder
    if [[ -d "${PROJECT_ROOT}/dist" ]]; then
        cp -r "${PROJECT_ROOT}/dist" "${backup_path}/dist"
        info "Backed up dist/ to ${backup_path}/dist"
    fi
    
    # Backup package.json and lock file
    cp "${PROJECT_ROOT}/package.json" "${backup_path}/" 2>/dev/null || true
    cp "${PROJECT_ROOT}/package-lock.json" "${backup_path}/" 2>/dev/null || true
    
    # Backup state files
    cp "${STATE_DIR}"/*.pid "${backup_path}/" 2>/dev/null || true
    cp "${STATE_DIR}"/*.state "${backup_path}/" 2>/dev/null || true
    
    # Record backup metadata
    cat > "${backup_path}/metadata.json" <<EOF
{
  "tx_id": "${tx_id}",
  "timestamp": "$(timestamp)",
  "backup_path": "${backup_path}"
}
EOF
    
    echo "${backup_path}"
}

restore_backup() {
    local tx_id="$1"
    local backup_path="${BACKUP_DIR}/${tx_id}"
    
    if [[ ! -d "${backup_path}" ]]; then
        error "Backup not found: ${backup_path}"
        return 1
    fi
    
    info "Restoring from backup: ${backup_path}"
    
    # Restore dist folder
    if [[ -d "${backup_path}/dist" ]]; then
        rm -rf "${PROJECT_ROOT}/dist"
        cp -r "${backup_path}/dist" "${PROJECT_ROOT}/dist"
        success "Restored dist/"
    fi
    
    # Restore package files
    cp "${backup_path}/package.json" "${PROJECT_ROOT}/" 2>/dev/null || true
    cp "${backup_path}/package-lock.json" "${PROJECT_ROOT}/" 2>/dev/null || true
    
    # Restore state files
    cp "${backup_path}"/*.pid "${STATE_DIR}/" 2>/dev/null || true
    cp "${backup_path}"/*.state "${STATE_DIR}/" 2>/dev/null || true
    
    success "Restore completed"
    return 0
}

# ============================================================================
# HEALTH CHECK
# ============================================================================

check_health() {
    local retries="${HEALTH_RETRIES}"
    local interval="${HEALTH_INTERVAL}"
    
    info "Checking health (retries: ${retries}, interval: ${interval}s)..."
    
    # First check if health endpoint is running
    if ! curl -sf "http://localhost:${HEALTH_PORT}/health/live" >/dev/null 2>&1; then
        info "Starting health endpoint..."
        "${SCRIPT_DIR}/health-endpoint.sh" --daemonize 2>/dev/null || true
        sleep 2
    fi
    
    for ((i=1; i<=retries; i++)); do
        if curl -sf "http://localhost:${HEALTH_PORT}/health/ready" >/dev/null 2>&1; then
            success "Health check passed (attempt ${i}/${retries})"
            return 0
        fi
        
        if [[ ${i} -lt ${retries} ]]; then
            info "Health check failed (attempt ${i}/${retries}), retrying in ${interval}s..."
            sleep "${interval}"
        fi
    done
    
    error "Health check failed after ${retries} attempts"
    return 1
}

# ============================================================================
# DEPLOY COMMAND
# ============================================================================

cmd_deploy() {
    local pre_build="false"
    local health_check="true"
    local timeout="${HEALTH_TIMEOUT}"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pre-build)
                pre_build="true"
                shift
                ;;
            --no-health-check)
                health_check="false"
                shift
                ;;
            --timeout)
                timeout="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    local tx_id
    tx_id=$(generate_tx_id)
    
    info "=========================================="
    info "Starting deployment: ${tx_id}"
    info "=========================================="
    
    # Acquire lock
    if [[ -f "${LOCK_FILE}" ]]; then
        local lock_pid
        lock_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "")
        if [[ -n "${lock_pid}" ]] && kill -0 "${lock_pid}" 2>/dev/null; then
            error "Another deployment is in progress (PID: ${lock_pid})"
            return 1
        fi
        rm -f "${LOCK_FILE}"
    fi
    echo $$ > "${LOCK_FILE}"
    trap 'rm -f "${LOCK_FILE}"' EXIT
    
    init_journal
    journal_append "${tx_id}" "deploy_start" "started" '{"pre_build":'"${pre_build}"',"health_check":'"${health_check}"'}'
    update_current_state "deploying" "${tx_id}" "unknown"
    
    # Create backup before deployment
    local backup_path
    backup_path=$(create_backup "${tx_id}")
    info "Backup created at: ${backup_path}"
    journal_append "${tx_id}" "backup_created" "success" "{\"backup_path\":\"${backup_path}\"}"
    
    # Pre-build if requested
    if [[ "${pre_build}" == "true" ]]; then
        info "Running build..."
        journal_append "${tx_id}" "build_start" "started" '{}'
        
        if npm run build >> "${STATE_DIR}/deploy.log" 2>&1; then
            success "Build completed"
            journal_append "${tx_id}" "build_complete" "success" '{}'
        else
            error "Build failed"
            journal_append "${tx_id}" "build_complete" "failed" '{"error":"Build failed"}'
            
            # Automatic rollback
            warn "Initiating automatic rollback..."
            cmd_rollback_internal "${tx_id}" "build_failed"
            return 1
        fi
    fi
    
    # Stop existing server
    info "Stopping existing server..."
    if [[ -f "${SCRIPT_DIR}/stop.sh" ]]; then
        "${SCRIPT_DIR}/stop.sh" >> "${STATE_DIR}/deploy.log" 2>&1 || true
    fi
    
    # Start new server
    info "Starting server..."
    journal_append "${tx_id}" "server_start" "started" '{}'
    
    if "${SCRIPT_DIR}/start.sh" --force >> "${STATE_DIR}/deploy.log" 2>&1; then
        success "Server started"
        journal_append "${tx_id}" "server_start" "success" '{}'
    else
        error "Server start failed"
        journal_append "${tx_id}" "server_start" "failed" '{"error":"Server start failed"}'
        
        # Automatic rollback
        warn "Initiating automatic rollback..."
        cmd_rollback_internal "${tx_id}" "server_start_failed"
        return 1
    fi
    
    # Health check
    if [[ "${health_check}" == "true" ]]; then
        if ! check_health; then
            error "Post-deployment health check failed"
            journal_append "${tx_id}" "health_check" "failed" '{}'
            
            # Automatic rollback
            warn "Initiating automatic rollback..."
            cmd_rollback_internal "${tx_id}" "health_check_failed"
            return 1
        fi
        journal_append "${tx_id}" "health_check" "success" '{}'
    fi
    
    # Deployment successful
    success "=========================================="
    success "Deployment successful: ${tx_id}"
    success "=========================================="
    
    journal_append "${tx_id}" "deploy_complete" "success" '{}'
    update_current_state "deployed" "${tx_id}" "$(get_app_version)"
    
    # Clean up old backups (keep last 5)
    ls -t "${BACKUP_DIR}" 2>/dev/null | tail -n +6 | while read old; do
        rm -rf "${BACKUP_DIR}/${old}"
        info "Cleaned up old backup: ${old}"
    done
    
    return 0
}

# ============================================================================
# ROLLBACK COMMAND
# ============================================================================

cmd_rollback_internal() {
    local current_tx="$1"
    local reason="$2"
    
    warn "Rollback triggered: ${reason}"
    
    # Find last successful transaction
    local last_good
    last_good=$(get_last_successful_tx)
    
    if [[ -z "${last_good}" ]]; then
        error "No successful transaction found to rollback to"
        journal_append "${current_tx}" "rollback" "failed" '{"reason":"no_rollback_target"}'
        return 1
    fi
    
    info "Rolling back to: ${last_good}"
    
    # Stop current server
    if [[ -f "${SCRIPT_DIR}/stop.sh" ]]; then
        "${SCRIPT_DIR}/stop.sh" >> "${STATE_DIR}/deploy.log" 2>&1 || true
    fi
    
    # Restore backup
    if restore_backup "${last_good}"; then
        # Restart server
        if "${SCRIPT_DIR}/start.sh" --force >> "${STATE_DIR}/deploy.log" 2>&1; then
            success "Rollback completed successfully"
            journal_append "${current_tx}" "rollback" "success" "{\"rolled_back_to\":\"${last_good}\",\"reason\":\"${reason}\"}"
            update_current_state "rolled_back" "${last_good}" "$(get_app_version)"
            return 0
        else
            error "Failed to restart server after rollback"
            journal_append "${current_tx}" "rollback" "failed" '{"reason":"server_restart_failed"}'
            return 1
        fi
    else
        error "Failed to restore backup"
        journal_append "${current_tx}" "rollback" "failed" '{"reason":"restore_failed"}'
        return 1
    fi
}

cmd_rollback() {
    local target_tx=""
    local force="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --to)
                target_tx="$2"
                shift 2
                ;;
            --force)
                force="true"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    local tx_id
    tx_id=$(generate_tx_id)
    
    info "=========================================="
    info "Starting rollback: ${tx_id}"
    info "=========================================="
    
    init_journal
    journal_append "${tx_id}" "manual_rollback" "started" "{\"target\":\"${target_tx:-last_success}\"}"
    
    # Find target transaction
    local rollback_to="${target_tx}"
    if [[ -z "${rollback_to}" ]]; then
        rollback_to=$(get_last_successful_tx)
        if [[ -z "${rollback_to}" ]]; then
            error "No successful transaction found to rollback to"
            journal_append "${tx_id}" "manual_rollback" "failed" '{"reason":"no_rollback_target"}'
            return 1
        fi
    fi
    
    info "Rolling back to: ${rollback_to}"
    
    # Verify backup exists
    if [[ ! -d "${BACKUP_DIR}/${rollback_to}" ]]; then
        error "Backup not found: ${BACKUP_DIR}/${rollback_to}"
        journal_append "${tx_id}" "manual_rollback" "failed" '{"reason":"backup_not_found"}'
        return 1
    fi
    
    # Stop current server
    info "Stopping current server..."
    if [[ -f "${SCRIPT_DIR}/stop.sh" ]]; then
        "${SCRIPT_DIR}/stop.sh" >> "${STATE_DIR}/deploy.log" 2>&1 || true
    fi
    
    # Restore backup
    if restore_backup "${rollback_to}"; then
        # Restart server
        info "Restarting server..."
        if "${SCRIPT_DIR}/start.sh" --force >> "${STATE_DIR}/deploy.log" 2>&1; then
            # Verify health unless forced
            if [[ "${force}" != "true" ]]; then
                if ! check_health; then
                    error "Health check failed after rollback"
                    journal_append "${tx_id}" "manual_rollback" "failed" '{"reason":"health_check_failed"}'
                    return 1
                fi
            fi
            
            success "=========================================="
            success "Rollback successful: ${rollback_to}"
            success "=========================================="
            
            journal_append "${tx_id}" "manual_rollback" "success" "{\"rolled_back_to\":\"${rollback_to}\"}"
            update_current_state "rolled_back" "${rollback_to}" "$(get_app_version)"
            return 0
        else
            error "Failed to restart server after rollback"
            journal_append "${tx_id}" "manual_rollback" "failed" '{"reason":"server_restart_failed"}'
            return 1
        fi
    else
        error "Failed to restore backup"
        journal_append "${tx_id}" "manual_rollback" "failed" '{"reason":"restore_failed"}'
        return 1
    fi
}

# ============================================================================
# STATUS COMMAND
# ============================================================================

cmd_status() {
    init_journal
    
    echo "=== ClawSuite Deployment Status ==="
    echo ""
    
    if [[ -f "${CURRENT_STATE}" ]]; then
        echo "Current State:"
        jq '.' "${CURRENT_STATE}" 2>/dev/null || cat "${CURRENT_STATE}"
    else
        echo "No deployment state found"
    fi
    
    echo ""
    echo "Last 5 Transactions:"
    
    if [[ -f "${JOURNAL_FILE}" ]] && [[ -s "${JOURNAL_FILE}" ]]; then
        tail -5 "${JOURNAL_FILE}" | while read -r line; do
            echo "${line}" | jq -c '{tx_id, timestamp, action, status}' 2>/dev/null || echo "${line}"
        done
    else
        echo "(no transactions recorded)"
    fi
    
    echo ""
    echo "Available Backups:"
    ls -lt "${BACKUP_DIR}" 2>/dev/null | head -6 || echo "(no backups)"
}

# ============================================================================
# JOURNAL COMMAND
# ============================================================================

cmd_journal() {
    local count="${1:-10}"
    
    init_journal
    
    echo "=== ClawSuite Transaction Journal (last ${count}) ==="
    echo ""
    
    if [[ -f "${JOURNAL_FILE}" ]] && [[ -s "${JOURNAL_FILE}" ]]; then
        tail -"${count}" "${JOURNAL_FILE}" | while read -r line; do
            echo "${line}" | jq '.' 2>/dev/null || echo "${line}"
            echo "---"
        done
    else
        echo "(journal is empty)"
    fi
}

# ============================================================================
# VERIFY COMMAND
# ============================================================================

cmd_verify() {
    init_journal
    
    echo "=== ClawSuite State Verification ==="
    echo ""
    
    local issues=0
    
    # Check current state file
    if [[ ! -f "${CURRENT_STATE}" ]]; then
        warn "Missing current state file"
        ((issues++))
    fi
    
    # Check journal file
    if [[ ! -f "${JOURNAL_FILE}" ]]; then
        warn "Missing journal file"
        ((issues++))
    fi
    
    # Check dist folder
    if [[ ! -d "${PROJECT_ROOT}/dist" ]]; then
        warn "Missing dist/ folder"
        ((issues++))
    fi
    
    # Check health endpoint
    if curl -sf "http://localhost:${HEALTH_PORT}/health/live" >/dev/null 2>&1; then
        success "Health endpoint is responding"
    else
        warn "Health endpoint not responding"
        ((issues++))
    fi
    
    # Check server process
    if curl -sf "http://localhost:${HEALTH_PORT}/health/ready" >/dev/null 2>&1; then
        success "Server is healthy"
    else
        warn "Server is not healthy"
        ((issues++))
    fi
    
    echo ""
    if [[ ${issues} -eq 0 ]]; then
        success "Verification passed - all checks OK"
        return 0
    else
        error "Verification failed - ${issues} issue(s) found"
        return 1
    fi
}

# ============================================================================
# INIT COMMAND
# ============================================================================

cmd_init() {
    init_journal
    success "Journal initialized at ${JOURNAL_DIR}"
}

# ============================================================================
# GET APP VERSION
# ============================================================================

get_app_version() {
    local pkg="${PROJECT_ROOT}/package.json"
    if [[ -f "${pkg}" ]]; then
        grep -oP '"version"\s*:\s*"\K[^"]+' "${pkg}" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

COMMAND="$1"
shift

case "${COMMAND}" in
    deploy)
        cmd_deploy "$@"
        ;;
    rollback)
        cmd_rollback "$@"
        ;;
    status)
        cmd_status
        ;;
    journal)
        cmd_journal "$@"
        ;;
    verify)
        cmd_verify
        ;;
    init)
        cmd_init
        ;;
    -h|--help)
        usage
        ;;
    *)
        error "Unknown command: ${COMMAND}"
        usage
        exit 2
        ;;
esac
