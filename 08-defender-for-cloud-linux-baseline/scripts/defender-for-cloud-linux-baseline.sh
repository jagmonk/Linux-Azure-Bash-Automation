#!/usr/bin/env bash
#===============================================================================
# Script Name: defender-for-cloud-linux-baseline.sh
# Description: Export Defender for Cloud security assessments for review and Linux baseline evidence.
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
OUT_JSON="$REPORT_DIR/defender-assessments-$TIMESTAMP.json"
OUT_CSV="$REPORT_DIR/defender-linux-baseline-$TIMESTAMP.csv"

log "INFO" "Exporting security assessments"
az security assessment list -o json > "$OUT_JSON"

echo "display_name,status,severity,resource_id" > "$OUT_CSV"
jq -r '
  .[] | [
    (.displayName // .name // "unknown"),
    (.status.code // "unknown"),
    (.metadata.severity // "unknown"),
    (.resourceDetails.Id // .resourceDetails.id // "unknown")
  ] | @csv' "$OUT_JSON" >> "$OUT_CSV"
log "INFO" "Completed: $OUT_CSV"
