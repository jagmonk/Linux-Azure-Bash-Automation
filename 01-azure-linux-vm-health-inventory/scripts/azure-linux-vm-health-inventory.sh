#!/usr/bin/env bash
#===============================================================================
# Script Name: azure-linux-vm-health-inventory.sh
# Description: Inventory Azure Linux VMs and optionally collect health signals with VM run-command.
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
OUT="$REPORT_DIR/azure-linux-vm-health-inventory-$TIMESTAMP.csv"
RUN_COMMAND="${RUN_COMMAND:-false}"

log "INFO" "Exporting Linux VM inventory"
az vm list -d --query "[?storageProfile.osDisk.osType=='Linux']" -o json > "$REPORT_DIR/linux-vms-$TIMESTAMP.json"

{
  echo "name,resource_group,location,power_state,private_ips,public_ips,size,health_source"
  jq -r '.[] | [.name,.resourceGroup,.location,.powerState,(.privateIps // ""),(.publicIps // ""),(.hardwareProfile.vmSize // ""),"az_vm_list"] | @csv' "$REPORT_DIR/linux-vms-$TIMESTAMP.json"
} > "$OUT"

if [[ "$RUN_COMMAND" == "true" ]]; then
  log "INFO" "RUN_COMMAND=true. Collecting uname, uptime, disk, and memory from each VM"
  jq -r '.[] | [.name,.resourceGroup] | @tsv' "$REPORT_DIR/linux-vms-$TIMESTAMP.json" | while IFS=$'\t' read -r vm rg; do
    safe_vm="${vm//[^a-zA-Z0-9_.-]/_}"
    az vm run-command invoke \
      --resource-group "$rg" \
      --name "$vm" \
      --command-id RunShellScript \
      --scripts 'hostname; uname -r; uptime; df -hP /; free -m' \
      -o json > "$REPORT_DIR/run-command-${safe_vm}-$TIMESTAMP.json" || log "WARN" "Run-command failed for $vm"
  done
else
  log "INFO" "Set RUN_COMMAND=true to collect guest health signals"
fi
log "INFO" "Completed: $OUT"
