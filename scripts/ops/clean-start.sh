#!/usr/bin/env bash
# ClawSuite Clean Start
# Complete reset and fresh start for ClawSuite
#
# This script performs a complete reset:
# 1. Stops any running instances
# 2. Cleans all build artifacts
# 3. Rebuilds from scratch
# 4. Starts the server
#
# Usage: ./clean-start.sh [--mode dev|preview]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"

MODE="${1:-preview}"

echo "=== ClawSuite Clean Start ==="
echo "Mode: ${MODE}"
echo ""

# Step 1: Stop any running instances
echo "Step 1: Stopping any running instances..."
"${SCRIPT_DIR}/stop.sh" || true

# Step 2: Clean build artifacts
echo ""
echo "Step 2: Cleaning build artifacts..."
cd "${PROJECT_ROOT}"
rm -rf dist .vite .tanstack 2>/dev/null || true
rm -f "${LOG_DIR}/clawsuite.lock" "${LOG_DIR}/clawsuite.pid" 2>/dev/null || true
echo "Clean complete"

# Step 3: Rebuild
echo ""
echo "Step 3: Rebuilding..."
npm run build

# Step 4: Start
echo ""
echo "Step 4: Starting server..."
"${SCRIPT_DIR}/start.sh" --mode "${MODE}" --force

echo ""
echo "=== Clean Start Complete ==="
