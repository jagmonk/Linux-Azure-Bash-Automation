# Operations Guide: Log Analytics Linux Ingest Pattern

## Pre-checks

- Confirm Azure CLI is installed.
- Confirm `jq` is installed.
- Run `az account show` to verify authentication.
- Confirm RBAC permissions are scoped appropriately.
- Review the script header and parameters.

## Runbook

1. Run the script in report mode.
2. Review CSV, JSON, or text output.
3. Validate findings with the resource owner or change manager.
4. Do not enable action modes until the output is reviewed.
5. Store reports with the related ticket, change record, or audit evidence.

## Security notes

- Prefer managed identity, workload identity, or certificate authentication.
- Do not hardcode secrets.
- Do not commit `.env` files.
- Keep production identifiers out of GitHub.
- Use least-privilege RBAC.

## Success indicators

- Script authenticates successfully.
- Report output is generated.
- Findings are clear and actionable.
- No destructive action occurs by default.
