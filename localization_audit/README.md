# Localization Audit

## Automated Script

Generate both audit files from project root:

```bash
./scripts/export_and_audit_localizations.sh
```

Generates:
- `localization_audit.xlsx` - Localization keys by flow (General, AUTH_FLOW, MAIN_FLOW, etc.)
- `permissions_localization.xlsx` - iOS permission descriptions

## Manual Generation

### Localization Audit

```bash
cd localization_audit
source venv/bin/activate
python3 create_localization_excel.py
deactivate
```

### Permissions Localization

```bash
cd localization_audit
source venv/bin/activate
python3 update_permissions_localization.py
deactivate
```
