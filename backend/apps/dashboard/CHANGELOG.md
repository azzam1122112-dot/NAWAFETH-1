# Dashboard Changes

## Security / RBAC
- Added `require_dashboard_access(dashboard_key, write=False)` and kept `dashboard_access_required` as backward-compatible alias.
- Added unified write-access logging inside the dashboard RBAC decorator (`user_id`, dashboard key, path, method).

## OTP
- Kept current dev behavior (accept any 4-digit code for dashboard OTP).
- Added warning log when this bypass is active while `DEBUG=False`.

## Exports
- Hardened CSV export centrally against CSV Injection by prefixing dangerous leading characters (`=`, `+`, `-`, `@`) with apostrophe.

## Home Analytics
- Added `date_from` / `date_to` GET filters to `dashboard_home`.
- Applied selected date range to request KPIs, unified request KPIs, and trend series.
- Moved primary quick-link decision from template into view (`primary_ops_url`) to reduce template logic.

## Tests
- Added tests for:
  - QA readonly blocking POST write actions
  - Power user global write access
  - CSV export sanitization
  - Home analytics date range filtering
  - OTP gating and dev OTP acceptance flow

## Docs
- Added `IMPLEMENTATION_PLAN.md`
- Added `README.md` for dashboard operations and OTP dev-only warning
