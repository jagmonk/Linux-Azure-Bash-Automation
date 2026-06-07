#!/usr/bin/env bash
#===============================================================================
# Script Name: azure-linux-cost-tag-audit.sh
# Description: Audit Azure Linux VM tags for ownership and cost governance using Azure Resource Graph.
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
OUT="$REPORT_DIR/azure-linux-cost-tag-audit-$TIMESTAMP.csv"
QUERY='Resources
| where type =~ "microsoft.compute/virtualmachines"
| extend osType = tostring(properties.storageProfile.osDisk.osType)
| where osType =~ "Linux"
| project name, resourceGroup, location, subscriptionId, owner=tostring(tags.Owner), costCenter=tostring(tags.CostCenter), environment=tostring(tags.Environment), app=tostring(tags.Application)'

az graph query -q "$QUERY" -o json > "$REPORT_DIR/linux-vm-tags-$TIMESTAMP.json"

echo "name,resource_group,location,subscription_id,owner,cost_center,environment,application,tag_status" > "$OUT"
jq -r '.data[] | .tag_status = (if ((.owner // "") == "" or (.costCenter // "") == "") then "missing_required_tags" else "ok" end) | [.name,.resourceGroup,.location,.subscriptionId,(.owner // ""),(.costCenter // ""),(.environment // ""),(.app // ""),.tag_status] | @csv' "$REPORT_DIR/linux-vm-tags-$TIMESTAMP.json" >> "$OUT"
log "INFO" "Completed: $OUT"
