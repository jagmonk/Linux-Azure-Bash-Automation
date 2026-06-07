#!/usr/bin/env bash
#===============================================================================
# Script Name: network-watcher-linux-path-check.sh
# Description: Combine Linux network diagnostics with Azure Network Watcher next-hop checks.
# Author: Jesse Monk
# Portfolio: Advanced Linux and Azure Bash Automation Portfolio
# Audience: Senior Systems Administrator, Hybrid Cloud Administrator, Linux Admin
# Safety: Report-first by default. Destructive actions require explicit flags.
# Requirements: Bash 4+, Azure CLI, jq, core GNU/Linux utilities
# Notes:
#   - Use a lab subscription first.
#   - Do not commit tenant IDs, subscription IDs, secrets, keys, or client data.
#   - Prefer managed identity, workload identity, or certificate auth where possible.
#===============================================================================

set -Eeuo pipefail
IFS=$'
	'

SCRIPT_NAME="$(basename "$0")"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${REPORT_DIR:-$BASE_DIR/reports}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REPORT_DIR"

log() {
  local level="$1"; shift
  printf '[%s] [%s] [%s] %s
' "$(date '+%Y-%m-%d %H:%M:%S')" "$SCRIPT_NAME" "$level" "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { log "ERROR" "Required command not found: $1"; exit 1; }
}

require_azure() {
  require_cmd az
  require_cmd jq
  if ! az account show >/dev/null 2>&1; then
    log "ERROR" "Azure CLI is not logged in. Run az login, use managed identity, or configure service principal auth."
    exit 1
  fi
}

csv_escape() {
  local value="${1:-}"
  value="${value//"/""}"
  printf '"%s"' "$value"
}


require_azure
TARGET="${1:-microsoft.com}"
PORT="${2:-443}"
VM_NAME="${AZURE_VM_NAME:-}"
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-}"
OUT="$REPORT_DIR/network-watcher-linux-path-check-$TIMESTAMP.txt"

{
  echo "Target: $TARGET"
  echo "Port: $PORT"
  echo "Timestamp: $(date)"
  echo
  echo "== Local DNS =="
  getent hosts "$TARGET" || true
  echo
  echo "== Local route =="
  ip route get "$TARGET" 2>/dev/null || true
  echo
  echo "== Local TCP =="
  timeout 5 bash -c "</dev/tcp/$TARGET/$PORT" >/dev/null 2>&1 && echo "reachable" || echo "not reachable"
  echo
  echo "== Azure Network Watcher note =="
  if [[ -n "$VM_NAME" && -n "$RESOURCE_GROUP" ]]; then
    echo "VM_NAME and RESOURCE_GROUP provided. Collecting VM NIC details."
    az vm show -g "$RESOURCE_GROUP" -n "$VM_NAME" -d -o json
  else
    echo "Set AZURE_VM_NAME and AZURE_RESOURCE_GROUP to collect Azure VM network context."
  fi
} > "$OUT"
log "INFO" "Completed: $OUT"
