#!/usr/bin/env bash
#===============================================================================
# Script Name: log-analytics-linux-ingest.sh
# Description: Create a Linux health JSON payload and provide a safe Log Analytics ingestion pattern.
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


require_cmd jq
OUT_JSON="$REPORT_DIR/linux-health-payload-$TIMESTAMP.json"
OUT_NOTE="$REPORT_DIR/log-analytics-ingest-notes-$TIMESTAMP.txt"

jq -n \
  --arg hostname "$(hostname)" \
  --arg kernel "$(uname -r)" \
  --arg uptime "$(uptime -p 2>/dev/null || uptime)" \
  --arg timestamp "$(date -Iseconds)" \
  '{hostname:$hostname,kernel:$kernel,uptime:$uptime,generatedAt:$timestamp,source:"linux-bash-portfolio"}' > "$OUT_JSON"

cat > "$OUT_NOTE" <<'EOF'
Log Analytics ingestion note:
Use Azure Monitor Logs ingestion with a Data Collection Endpoint and Data Collection Rule in production.
This script creates a safe local JSON payload. Add your approved ingestion method after validating workspace, DCR, RBAC, and schema.
Do not hardcode shared keys or tokens in scripts.
EOF

log "INFO" "Payload created: $OUT_JSON"
log "INFO" "Notes created: $OUT_NOTE"
