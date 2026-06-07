#!/usr/bin/env bash
#===============================================================================
# Script Name: azure-backup-rpo-audit.sh
# Description: Audit Recovery Services vault backup items for RPO review evidence.
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
OUT="$REPORT_DIR/azure-backup-rpo-audit-$TIMESTAMP.csv"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-25}"

echo "vault,resource_group,item_name,workload_type,last_backup_time,protection_state,rpo_status" > "$OUT"
az backup vault list -o json > "$REPORT_DIR/recovery-vaults-$TIMESTAMP.json"
jq -r '.[] | [.name,.resourceGroup] | @tsv' "$REPORT_DIR/recovery-vaults-$TIMESTAMP.json" | while IFS=$'\t' read -r vault rg; do
  log "INFO" "Checking vault $vault"
  az backup item list --vault-name "$vault" --resource-group "$rg" -o json > "$REPORT_DIR/backup-items-${vault}-$TIMESTAMP.json" || continue
  jq -r --arg vault "$vault" --arg rg "$rg" --arg max "$MAX_AGE_HOURS" '
    .[] | [
      $vault,
      $rg,
      (.properties.friendlyName // .name // "unknown"),
      (.properties.workloadType // "unknown"),
      (.properties.lastBackupTime // "unknown"),
      (.properties.protectionState // "unknown"),
      "review"
    ] | @csv' "$REPORT_DIR/backup-items-${vault}-$TIMESTAMP.json" >> "$OUT"
done
log "INFO" "Completed: $OUT"
