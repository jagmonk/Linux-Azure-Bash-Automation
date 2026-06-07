# Jesse Monk Advanced Linux and Azure Bash Automation Portfolio

This GitHub-ready repo extends the Linux Bash Systems Administration portfolio into advanced Azure-integrated automation. It is designed around a senior Systems Administrator profile with hybrid infrastructure, Microsoft 365, Entra ID, Azure, Intune, Windows Server, Active Directory, Linux administration, networking, backup/DR, monitoring, SOP documentation, legal IT support, and data center operations experience.

The scripts show how a Linux-focused administrator can operate in a modern hybrid cloud environment using Bash, Azure CLI, JSON parsing, CSV reporting, operational logging, and safe-by-default automation.

## Project list

| Folder | Project | Azure integration | Business value |
|---|---|---|---|
| `01-azure-linux-vm-health-inventory` | Azure Linux VM Health Inventory | Azure Compute, VM run-command | Linux fleet visibility |
| `02-azure-linux-patch-readiness` | Azure Linux Patch Readiness | Azure VM inventory, run-command | Safer patch planning |
| `03-azure-backup-rpo-audit` | Azure Backup RPO Audit | Recovery Services vaults | Backup and DR confidence |
| `04-log-analytics-linux-ingest` | Linux Report Upload to Log Analytics | Azure Monitor Logs API pattern | Centralized operational reporting |
| `05-blob-backup-sync` | Linux Backup Sync to Azure Blob | Azure Storage | Offsite backup copy workflow |
| `06-key-vault-secret-rotation-audit` | Key Vault Secret Rotation Audit | Azure Key Vault | Secret hygiene and risk reduction |
| `07-network-watcher-linux-path-check` | Azure Network Path Check | Network Watcher, Linux diagnostics | Hybrid network troubleshooting |
| `08-defender-for-cloud-linux-baseline` | Defender for Cloud Linux Baseline | Azure Security assessment export | Security posture evidence |
| `09-managed-identity-token-test` | Managed Identity Token Test | IMDS, Azure Resource Manager | Cloud-native Linux automation auth |
| `10-azure-linux-cost-tag-audit` | Azure Linux Cost and Tag Audit | Azure Resource Graph | Cost governance and ownership |

## Portfolio design principles

- Report-first by default
- No destructive actions unless explicitly enabled
- Clear script headers and operational docs
- CSV, JSON, and text output for ticketing or audit records
- Practical scripts that align with real Systems Administrator responsibilities
- Safe GitHub publishing guidance

## Requirements

- Bash 4 or newer
- Azure CLI
- jq
- curl
- coreutils
- An Azure subscription or lab tenant
- Least-privilege RBAC permissions for the resources being queried

## Recommended test approach

1. Use a lab subscription or personal Azure sandbox.
2. Run each script in report-only mode first.
3. Review generated files under each project's `reports/` folder.
4. Replace placeholders in `.env.example` with your own local environment variables.
5. Do not commit secrets, tenant IDs, subscription IDs, internal hostnames, or client data.

## Resume-ready summary

Built an advanced Linux and Azure Bash automation portfolio covering Azure Linux VM inventory, patch readiness, backup RPO auditing, Log Analytics ingestion patterns, Blob backup sync, Key Vault secret hygiene, Network Watcher diagnostics, Defender for Cloud baseline exports, Managed Identity validation, and Azure cost/tag governance. Scripts include polished headers, safe defaults, Azure CLI integration, jq JSON parsing, CSV/JSON reports, per-project documentation, and GitHub-ready structure.
