#!/usr/bin/env bash
#===============================================================================
# Script Name: key-vault-secret-rotation-audit.sh
# Description: Audit Key Vault secrets for expiration and rotation review indicators.
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
OUT="$REPORT_DIR/key-vault-secret-rotation-audit-$TIMESTAMP.csv"
WARN_DAYS="${WARN_DAYS:-30}"

echo "vault,secret,enabled,expires,status" > "$OUT"
az keyvault list -o json > "$REPORT_DIR/keyvaults-$TIMESTAMP.json"
jq -r '.[] | .name' "$REPORT_DIR/keyvaults-$TIMESTAMP.json" | while read -r vault; do
  log "INFO" "Checking Key Vault $vault"
  az keyvault secret list --vault-name "$vault" -o json > "$REPORT_DIR/secrets-${vault}-$TIMESTAMP.json" || continue
  jq -r --arg vault "$vault" '
    .[] | [
      $vault,
      (.name // "unknown"),
      (.attributes.enabled | tostring),
      (.attributes.expires // "none"),
      (if .attributes.expires == null then "missing_expiration" else "review" end)
    ] | @csv' "$REPORT_DIR/secrets-${vault}-$TIMESTAMP.json" >> "$OUT"
done
log "INFO" "Completed: $OUT"
