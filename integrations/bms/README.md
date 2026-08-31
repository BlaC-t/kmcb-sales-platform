# BMS integration and DEV-to-PROD transfer package

This directory preserves BMS-owned menu, route metadata and permission mappings separately from Sales Platform domain data.

## Boundary

- Sales Platform projects, content, equipment, workbook imports, recommendations and releases belong to the Sales Platform API and `kj_sale_platform` on server 121.
- BMS owns employee authentication, menu records, roles, function permissions and the future BFF/identity adapter configuration.
- BMS metadata must never be inserted into `kj_sale_platform`.
- BMS pages are registered through menu management; no Sales Platform page is hardcoded in `routes.ts`.

## Files

- `001_dev_menu_permission_snapshot.sql`: the idempotent snapshot used for the current BMS DEV menu configuration. It targets the recorded DEV schema only.
- `002_target_menu_permission_template.sql`: future DEV-to-PROD transfer template. Replace `__BMS_TARGET_SCHEMA__` only after the target BMS schema, backup and change window are approved.

## Transfer checklist

1. Export the current `PMS023%` records from BMS DEV and compare them with the snapshot.
2. Confirm every component path exists in the target frontend release.
3. Confirm target `function_code` values do not collide and role assignments are intentionally excluded from the transfer.
4. Replace `__BMS_TARGET_SCHEMA__` with the approved target BMS schema in a reviewed release copy.
5. Run the target copy inside a BMS database change window, then verify dynamic routing and permissions with a non-admin test role.
6. Never run either BMS SQL file against server 121's `kj_sale_platform` schema.

Role/user grants are not included because DEV identities and PROD identities may differ. They must be assigned through BMS permission management after the menu records are present.
