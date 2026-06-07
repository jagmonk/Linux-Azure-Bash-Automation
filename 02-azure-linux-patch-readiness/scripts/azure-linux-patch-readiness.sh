#!/usr/bin/env bash
#===============================================================================
# Script Name: azure-linux-patch-readiness.sh
# Description: Collect patch readiness indicators from Azure Linux VMs with run-command.
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
OUT="$REPORT_DIR/azure-linux-patch-readiness-$TIMESTAMP.csv"
QUERY="[?storageProfile.osDisk.osType=='Linux'].[name,resourceGroup]"

echo "vm,resource_group,patch_check_file,status" > "$OUT"
az vm list --query "$QUERY" -o tsv | while read -r vm rg; do
  safe_vm="${vm//[^a-zA-Z0-9_.-]/_}"
  result="$REPORT_DIR/patch-${safe_vm}-$TIMESTAMP.json"
  log "INFO" "Checking patch readiness on $vm"
  if az vm run-command invoke --resource-group "$rg" --name "$vm" --command-id RunShellScript --scripts '
    echo PACKAGE_MANAGER=$(command -v apt >/dev/null && echo apt || command -v dnf >/dev/null && echo dnf || command -v yum >/dev/null && echo yum || echo unknown)
    echo KERNEL=$(uname -r)
    echo ROOT_DISK=$(df -P / | awk "NR==2 {print \$5}")
    test -f /var/run/reboot-required && echo REBOOT_REQUIRED=true || echo REBOOT_REQUIRED=false
    command -v apt >/dev/null && apt list --upgradable 2>/dev/null | wc -l || true
    command -v dnf >/dev/null && dnf check-update >/tmp/dnf-check.txt 2>&1; wc -l /tmp/dnf-check.txt || true
  ' -o json > "$result"; then
    echo "$vm,$rg,$result,ok" >> "$OUT"
  else
    echo "$vm,$rg,$result,failed" >> "$OUT"
  fi
done
log "INFO" "Completed: $OUT"
