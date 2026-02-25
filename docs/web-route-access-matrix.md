# Web Route Access Matrix (Flutter Web)

This document defines who can access Flutter Web routes in `mobile/lib/main_web.dart`.

## Scope

- Flutter Web is intended for:
  - Client users
  - Provider users
- Staff/admin users must use the backend dashboard (`/dashboard/`) on the Django backend.

## Guarding Strategy

Implemented in:

- `mobile/lib/main_web.dart`
- `mobile/lib/screens/role_mode_access_guard_screen.dart`

Route guard helpers used in `main_web.dart`:

- `_publicWebRouteBuilder(...)` => public Flutter Web routes, blocks `staff`
- `_clientWebRouteBuilder(...)` => client routes only
- `_providerWebRouteBuilder(...)` => provider routes only
- `_clientGeneratedRoute(...)` => client deep links / query routes
- `_providerGeneratedRoute(...)` => provider deep links / query routes

## Access Rules

Legend:

- `Allow` = route is accessible
- `Block` = user is blocked from Flutter Web route
- `Redirect` = route guard redirects or shows guard screen with target action

## Public Flutter Web Routes (Non-Staff Only)

These routes are blocked for `staff` and show a guard screen with a button to open backend dashboard.

| Route | Client | Provider | Staff |
|---|---|---|---|
| `/entry` | Allow | Allow | Block -> Backend Dashboard |
| `/onboarding` | Allow | Allow | Block -> Backend Dashboard |
| `/home` | Allow | Allow | Block -> Backend Dashboard |
| `/login` | Allow | Allow | Block -> Backend Dashboard |
| `/signup` | Allow | Allow | Block -> Backend Dashboard |

## Client Routes (Client Mode Only)

Guard: `RoleModeAccessGuardScreen(mode: client)`

Rules:

- Requires login
- Blocks `staff`
- Blocks users currently in provider mode

| Route | Client (mode=client) | Provider (mode=provider) | Staff |
|---|---|---|---|
| `/client_dashboard` | Allow | Redirect to provider/client appropriate route via guard | Block -> Backend Dashboard |
| `/client_dashboard/orders` | Allow | Redirect by guard | Block -> Backend Dashboard |
| `/client_dashboard/notifications` | Allow | Redirect by guard | Block -> Backend Dashboard |
| `/client_dashboard/profile` | Allow | Redirect by guard | Block -> Backend Dashboard |
| `/client_dashboard/orders/<id>` | Allow | Redirect by guard | Block -> Backend Dashboard |
| `/client_dashboard/order/<id>` | Allow | Redirect by guard | Block -> Backend Dashboard |
| `/client_dashboard/orders?...` | Allow | Redirect by guard | Block -> Backend Dashboard |

## Provider Routes (Provider Mode Only)

Guard: `RoleModeAccessGuardScreen(mode: provider)`

Rules:

- Requires login
- Requires provider registration + provider mode enabled
- Blocks `staff`

| Route | Client (mode=client) | Provider (registered + mode=provider) | Staff |
|---|---|---|---|
| `/provider_dashboard` | Redirect to client/home by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/orders` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/services` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/reviews` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/notifications` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/profile` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/orders/<id>` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/order/<id>` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/orders?...` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/services?...` | Redirect by guard | Allow | Block -> Backend Dashboard |
| `/provider_dashboard/reviews?...` | Redirect by guard | Allow | Block -> Backend Dashboard |

## Notifications Route (Role-Aware)

| Route | Behavior |
|---|---|
| `/notifications` | Chooses client/provider notifications shell based on current role mode, then applies corresponding guard |

## Staff/Admin Policy

Staff/admin users are intentionally blocked from Flutter Web app routes and should use the Django backend dashboard:

- Backend dashboard URL: `${ApiConfig.baseUrl}/dashboard/`

The guard checks `staff` using `/accounts/me/` fields:

- `role_state == "staff"`
- or `is_staff == true`
- or `is_superuser == true`

## API Integration Notes

Flutter Web routes use the same backend API as mobile through shared service classes.

Base API config:

- `mobile/lib/services/api_config.dart`
  - `baseUrl` (default: `https://nawafeth-backend.onrender.com`)
  - `apiPrefix` (`/api`)

Examples of shared API services used by web screens:

- `mobile/lib/services/account_api.dart`
- `mobile/lib/services/marketplace_api.dart`
- `mobile/lib/services/providers_api.dart`
- `mobile/lib/services/reviews_api.dart`
- `mobile/lib/services/notifications_api.dart`

## Maintenance Rule (Important)

When adding a new Flutter Web route in `mobile/lib/main_web.dart`:

1. Choose the correct guard helper (`public/client/provider`).
2. For deep links in `onGenerateRoute`, use `_clientGeneratedRoute(...)` or `_providerGeneratedRoute(...)`.
3. Do not add unguarded routes for client/provider features.
4. Do not expose staff/admin management in Flutter Web; keep it in backend dashboard.
