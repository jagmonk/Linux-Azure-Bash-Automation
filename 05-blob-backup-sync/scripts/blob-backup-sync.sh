#!/usr/bin/env bash
#===============================================================================
# Script Name: blob-backup-sync.sh
# Description: Sync local Linux backup folder to Azure Blob Storage with dry-run default and explicit APPLY=true mode.
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
SOURCE_DIR="${1:-/backup}"
STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT:-}"
CONTAINER="${AZURE_STORAGE_CONTAINER:-linux-backups}"
APPLY="${APPLY:-false}"
OUT="$REPORT_DIR/blob-backup-sync-$TIMESTAMP.txt"

if [[ -z "$STORAGE_ACCOUNT" ]]; then
  log "ERROR" "Set AZURE_STORAGE_ACCOUNT before running"
  exit 1
fi
if [[ ! -d "$SOURCE_DIR" ]]; then
  log "ERROR" "Source directory not found: $SOURCE_DIR"
  exit 1
fi

{
  echo "Source: $SOURCE_DIR"
  echo "Storage account: $STORAGE_ACCOUNT"
  echo "Container: $CONTAINER"
  echo "Apply: $APPLY"
  echo
  find "$SOURCE_DIR" -type f | head -100
} > "$OUT"

if [[ "$APPLY" == "true" ]]; then
  log "WARN" "APPLY=true. Uploading files to Blob container"
  az storage blob upload-batch \
    --account-name "$STORAGE_ACCOUNT" \
    --destination "$CONTAINER" \
    --source "$SOURCE_DIR" \
    --auth-mode login \
    --overwrite false | tee -a "$OUT"
else
  log "INFO" "Dry run only. Set APPLY=true to upload."
fi
log "INFO" "Completed: $OUT"
