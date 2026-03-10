#!/bin/bash
set -euo pipefail

readonly ROUTER_PORT="${COCOON_ROUTER_PORT:-8116}"
readonly ROUTER_POLICY="${COCOON_ROUTER_POLICY:-any}"
readonly VERBOSITY="${COCOON_VERBOSITY:-3}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Router starting on port ${ROUTER_PORT} (policy: ${ROUTER_POLICY})"

exec router -S "${ROUTER_PORT}@${ROUTER_POLICY}" --listen 0.0.0.0 --serialize-info -v "${VERBOSITY}"
