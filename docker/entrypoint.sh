#!/bin/bash
set -euo pipefail

readonly DATA_DIR="/data"
readonly CLIENT_CONFIG="${DATA_DIR}/client-config.json"
readonly TON_CONFIG="${DATA_DIR}/ton-config.json"
readonly TON_CONFIG_URL="https://cocoon.org/resources/mainnet.cocoon.global.config.json"

readonly ROOT_CONTRACT_ADDRESS="EQCns7bYSp0igFvS1wpb5wsZjCKCV19MD5AVzI4EyxsnU73k"
readonly ROUTER_PORT=8116
readonly HTTP_PORT=10000

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
die() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

read_secret() {
    local var="$1"
    local file="/run/secrets/${var,,}"
    [[ -f "$file" ]] && { cat "$file"; return; }
    local file_var="${var}_FILE"
    [[ -n "${!file_var:-}" ]] && [[ -f "${!file_var}" ]] && { cat "${!file_var}"; return; }
    echo "${!var:-}"
}

download_ton_config() {
    log "Downloading TON config..."
    local retries=3
    for ((i=1; i<=retries; i++)); do
        if curl -sf --connect-timeout 10 -o "${TON_CONFIG}" "${TON_CONFIG_URL}"; then
            log "TON config downloaded"
            return 0
        fi
        log "Retry ${i}/${retries}..."
        sleep 2
    done
    die "Failed to download TON config from ${TON_CONFIG_URL}"
}

generate_config() {
    local wallet_key
    wallet_key=$(read_secret "COCOON_NODE_WALLET_KEY")
    local access_hash="${COCOON_HTTP_ACCESS_HASH:-}"

    [[ -z "${COCOON_OWNER_ADDRESS:-}" ]] && die "COCOON_OWNER_ADDRESS is required"
    [[ -z "$wallet_key" ]] && die "COCOON_NODE_WALLET_KEY is required"

    cat > "${CLIENT_CONFIG}" <<EOF
{
  "is_test": 0,
  "is_testnet": false,
  "http_port": ${HTTP_PORT},
  "proxy_connections": ${COCOON_PROXY_CONNECTIONS:-1},
  "ton_config_filename": "${TON_CONFIG}",
  "owner_address": "${COCOON_OWNER_ADDRESS}",
  "root_contract_address": "${ROOT_CONTRACT_ADDRESS}",
  "node_wallet_key": "${wallet_key}",
  "connect_to_proxy_via": "127.0.0.1:${ROUTER_PORT}",
  "check_proxy_hashes": 0,
  "max_coefficient": 0,
  "max_tokens": 0,
  "http_access_hash": "${access_hash}"
}
EOF
    log "Client config generated"
}

ROUTER_PID=""
CLIENT_PID=""

cleanup() {
    trap - SIGTERM SIGINT  # Disable trap to prevent re-entry
    log "Shutting down..."
    [[ -n "$CLIENT_PID" ]] && kill "$CLIENT_PID" 2>/dev/null
    [[ -n "$ROUTER_PID" ]] && kill "$ROUTER_PID" 2>/dev/null
    wait
    exit 0
}

trap cleanup SIGTERM SIGINT

main() {
    log "COCOON starting..."
    log "  Owner: ${COCOON_OWNER_ADDRESS:-<not set>}"
    log "  Verbosity: ${COCOON_VERBOSITY:-3}"
    log "  Proxy connections: ${COCOON_PROXY_CONNECTIONS:-1}"
    log "  Access hash: ${COCOON_HTTP_ACCESS_HASH:+<configured>}${COCOON_HTTP_ACCESS_HASH:-<not set>}"

    download_ton_config
    generate_config

    log "Starting router on port ${ROUTER_PORT}..."
    router -S "${ROUTER_PORT}@any" --serialize-info -v "${COCOON_VERBOSITY:-3}" &
    ROUTER_PID=$!
    sleep 1
    log "Router started (PID: $ROUTER_PID)"

    log "Starting client..."
    client-runner -c "${CLIENT_CONFIG}" -v "${COCOON_VERBOSITY:-3}" &
    CLIENT_PID=$!
    log "Client started (PID: $CLIENT_PID)"

    wait "$CLIENT_PID"
}

main
