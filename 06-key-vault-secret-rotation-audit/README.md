# Key Vault Secret Rotation Audit

## Purpose

Audit Azure Key Vault secrets for missing expiration dates and aging rotation metadata.

## Why this matters

This project shows practical Linux administration in Azure. It turns cloud operational checks into repeatable evidence that can support troubleshooting, patch planning, backup review, security review, cost governance, or change management.

## Skills demonstrated

- Bash scripting with strict mode
- Azure CLI automation
- jq JSON parsing
- CSV and JSON report output
- Hybrid cloud operations
- Safe-by-default script design
- Documentation-first administration

## Example usage

```bash
chmod +x scripts/key-vault-secret-rotation-audit.sh
./scripts/key-vault-secret-rotation-audit.sh
```

## Output

Reports are written to the local `reports/` folder inside this project unless `REPORT_DIR` is set.

## Production notes

Use a lab subscription first. Do not commit tenant IDs, subscription IDs, resource IDs, internal hostnames, usernames, client data, or secrets.

## Resume bullet

Built a Bash-based key vault secret rotation audit automation project using Azure CLI, jq, structured reporting, polished headers, and operational documentation for hybrid cloud Systems Administration.
