#!/bin/bash
set -euo pipefail

readonly DATA_DIR="/data"
readonly CLIENT_CONFIG="${DATA_DIR}/client-config.json"
readonly TON_CONFIG="${DATA_DIR}/ton-config.json"
readonly TON_CONFIG_URL="${COCOON_TON_CONFIG_URL:-https://cocoon.org/resources/mainnet.cocoon.global.config.json}"

readonly ROOT_CONTRACT_ADDRESS="${COCOON_ROOT_CONTRACT_ADDRESS:-EQCns7bYSp0igFvS1wpb5wsZjCKCV19MD5AVzI4EyxsnU73k}"
readonly ROUTER_HOST="${COCOON_ROUTER_HOST:-10.100.0.10}"
readonly ROUTER_PORT="${COCOON_ROUTER_PORT:-8116}"
readonly HTTP_PORT="${COCOON_HTTP_PORT:-10000}"
readonly VERBOSITY="${COCOON_VERBOSITY:-3}"
readonly PROXY_CONNECTIONS="${COCOON_PROXY_CONNECTIONS:-1}"
readonly CHECK_PROXY_HASHES="${COCOON_CHECK_PROXY_HASHES:-0}"
readonly ACCESS_HASH="${COCOON_HTTP_ACCESS_HASH:-}"
readonly IS_TESTNET="${COCOON_IS_TESTNET:-false}"
readonly MAX_COEFFICIENT="${COCOON_MAX_COEFFICIENT:-0}"
readonly MAX_TOKENS="${COCOON_MAX_TOKENS:-0}"
readonly SECRET_STRING="${COCOON_SECRET_STRING:-}"

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
    log "Downloading TON config from ${TON_CONFIG_URL}..."
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

    [[ -z "${COCOON_OWNER_ADDRESS:-}" ]] && die "COCOON_OWNER_ADDRESS is required"
    [[ -z "$wallet_key" ]] && die "COCOON_NODE_WALLET_KEY is required"

    cat > "${CLIENT_CONFIG}" <<EOF
{
  "is_test": 0,
  "is_testnet": ${IS_TESTNET},
  "http_port": ${HTTP_PORT},
  "proxy_connections": ${PROXY_CONNECTIONS},
  "ton_config_filename": "${TON_CONFIG}",
  "owner_address": "${COCOON_OWNER_ADDRESS}",
  "root_contract_address": "${ROOT_CONTRACT_ADDRESS}",
  "node_wallet_key": "${wallet_key}",
  "connect_to_proxy_via": "${ROUTER_HOST}:${ROUTER_PORT}",
  "check_proxy_hashes": ${CHECK_PROXY_HASHES},
  "max_coefficient": ${MAX_COEFFICIENT},
  "max_tokens": ${MAX_TOKENS},
  "secret_string": "${SECRET_STRING}",
  "http_access_hash": "${ACCESS_HASH}"
}
EOF
    log "Client config generated (router: ${ROUTER_HOST}:${ROUTER_PORT})"
}

main() {
    log "COCOON Client starting..."
    log "  Owner: ${COCOON_OWNER_ADDRESS:-<not set>}"
    log "  Router: ${ROUTER_HOST}:${ROUTER_PORT}"
    log "  Verbosity: ${VERBOSITY}"
    log "  Proxy connections: ${PROXY_CONNECTIONS}"
    log "  Testnet: ${IS_TESTNET}"

    download_ton_config
    generate_config

    log "Starting client..."
    exec client-runner -c "${CLIENT_CONFIG}" -v "${VERBOSITY}"
}

main
