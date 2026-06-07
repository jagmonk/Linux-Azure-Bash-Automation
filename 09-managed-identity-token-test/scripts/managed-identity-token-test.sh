#!/usr/bin/env bash
#===============================================================================
# Script Name: managed-identity-token-test.sh
# Description: Validate Managed Identity token retrieval from Azure Linux VM using IMDS endpoint.
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


require_cmd curl
require_cmd jq
RESOURCE="${1:-https://management.azure.com/}"
OUT="$REPORT_DIR/managed-identity-token-test-$TIMESTAMP.json"

log "INFO" "Requesting managed identity token metadata from IMDS"
http_code=$(curl -sS -o "$OUT" -w "%{http_code}" \
  -H "Metadata: true" \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=${RESOURCE}") || true

if [[ "$http_code" == "200" ]]; then
  jq '{token_type, expires_on, resource}' "$OUT" > "$REPORT_DIR/managed-identity-token-summary-$TIMESTAMP.json"
  log "INFO" "Managed Identity token request succeeded. Token redacted in summary."
else
  log "WARN" "Managed Identity token request failed with HTTP $http_code. This is expected outside an Azure VM with managed identity."
fi
