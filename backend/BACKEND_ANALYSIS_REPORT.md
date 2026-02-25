# Nawafeth Django Backend — Comprehensive Analysis Report

**Date:** 2026-02-25  
**Scope:** `backend/` — 22 Django apps, ~28,660 lines across 273 source files (excluding migrations)

---

## 1. Overall Architecture & Patterns

### High-Level Architecture
Nawafeth is an **Arabic-first services marketplace** (Saudi Arabia) built with:
- **Django 5.0+** with **Django REST Framework** (JWT auth) for mobile API
- **Django Channels** (Daphne/ASGI) for WebSocket real-time messaging
- **Server-side rendered dashboard** (Django templates) for internal operations
- **SQLite** (dev) / **PostgreSQL** (prod via `DATABASE_URL`)
- **Redis** (prod) for Channel Layers; in-memory fallback in dev
- **Celery** (prod only, in requirements but not wired in settings)

### Architectural Pattern
- **Monolithic modular** — 22 apps under `apps/` namespace
- **Service layer pattern** — most apps have `services.py` for business logic
- **Signal-driven side effects** — notifications, extras activation, unified request sync
- **Unified Request Engine** — `unified_requests` aggregates requests from support/promo/verification/subscriptions/extras into a single trackable system
- **Feature gating** — `features` app provides `has_feature()` checks combining subscription plans + extras/add-ons

### Key Design Decisions
- Custom `User` model with **phone-based authentication** (OTP)
- **SAR currency** with **15% VAT** baked into billing
- **Generic invoice system** — `billing.Invoice` linked to any module via `reference_type`/`reference_id`
- **Code generation** pattern (IV######, HD######, AD######, MD######) for all trackable entities

---

## 2. Configuration Summary

### Settings Structure
| File | Purpose |
|------|---------|
| `base.py` (272 lines) | Core config: apps, middleware, DRF, JWT, CORS, Channels, promo pricing |
| `dev.py` (7 lines) | `DEBUG=True`, `OTP_DEV_ACCEPT_ANY_CODE=True` |
| `prod.py` (137 lines) | HTTPS, HSTS, CSP, Sentry, structured logging, CORS lockdown |
| `__init__.py` | Auto-selects dev/prod based on `DJANGO_ENV` env var |

### Middleware Stack (order)
1. `CorsMiddleware`
2. `SecurityMiddleware`
3. `WhiteNoiseMiddleware` (static files)
4. `CSPMiddleware` (prod only)
5. `SessionMiddleware`
6. `CommonMiddleware`
7. `CsrfViewMiddleware`
8. `AuthenticationMiddleware`
9. **`SubscriptionRefreshMiddleware`** (custom — refreshes subscription status on every request)
10. `MessageMiddleware`
11. `XFrameOptionsMiddleware`

### Authentication & Authorization
- **JWT (SimpleJWT)** — access: 60 min, refresh: 30 days
- **OTP-based login** — phone number → 4-digit OTP → JWT tokens
- **Role system:** `UserRole` enum: visitor → phone_only → client → provider → staff
- **Feature gating:** subscription plan features + extras add-ons
- **Dashboard auth:** separate OTP + staff check (server-rendered)
- **Backoffice:** `AccessLevel` (admin/power/user/qa/client) with dashboard-level scoping

### Throttling
| Scope | Rate |
|-------|------|
| `user` | 200/min |
| `anon` | 60/min |
| `otp` | 5/min |
| `auth` | 15/min |
| `refresh` | 60/min |

---

## 3. Dependencies

### Base (base.txt)
| Package | Purpose |
|---------|---------|
| Django ≥5.0 | Framework |
| djangorestframework ≥3.15 | REST API |
| python-dotenv | Env vars |
| psycopg[binary] ≥3.1 | PostgreSQL driver |
| Pillow ≥10.0 | Image processing |
| django-cors-headers | CORS |
| whitenoise ≥6.6 | Static files |
| dj-database-url | DB URL parsing |
| djangorestframework-simplejwt | JWT auth |
| django-filter | Query filtering |
| channels ≥4.1 | WebSocket support |
| daphne ≥4.1 | ASGI server |
| sentry-sdk | Error tracking |
| django-csp | Content Security Policy |
| openpyxl | XLSX exports |
| reportlab + arabic-reshaper + python-bidi | PDF exports with Arabic |

### Dev (dev.txt)
pytest, pytest-django, pytest-asyncio, pytest-mock, ruff (linter)

### Prod (prod.txt)
gunicorn, uvicorn, whitenoise, **celery ≥5.4**, **redis ≥5.0**, channels-redis

---

## 4. App-by-App Analysis

### 4.1 `accounts` — User & Auth
| Metric | Value |
|--------|-------|
| Models | `User`, `Wallet`, `OTP` |
| Views | 562 lines (function-based) |
| Serializers | 149 lines |
| Tests | 2 files |
| Special files | `otp.py`, `permissions.py` |

**Purpose:** Custom user model (phone-based), OTP generation/verification, JWT token issuance, user registration (3-level: visitor → phone_only → client), wallet, profile management.  
**Key patterns:** Phone normalization (Saudi format), OTP cooldown/rate limits, `UserRole` state machine.

### 4.2 `analytics` — Business Intelligence
| Metric | Value |
|--------|-------|
| Models | None (queries across other apps) |
| Views | 57 lines |
| Services | 103 lines |
| Tests | 2 files |
| Special files | `export.py`, `filters.py`, `permissions.py` |

**Purpose:** KPI dashboard — revenue, subscriptions, verification/promo request counts. Daily/monthly revenue charts. Export to XLSX.

### 4.3 `audit` — Audit Trail
| Metric | Value |
|--------|-------|
| Models | `AuditLog` (with 30+ `AuditAction` choices) |
| Views | 3 lines (empty) |
| Services | 37 lines |
| Tests | 1 file (tests.py) |
| Management commands | `cleanup_old_data` |

**Purpose:** Immutable audit log recording all significant actions (invoice, subscription, verification, promo, login, content changes). Generic reference system.

### 4.4 `backoffice` — Access Control
| Metric | Value |
|--------|-------|
| Models | `Dashboard`, `UserAccessProfile` (with `AccessLevel`) |
| Views | 25 lines |
| Serializers | 37 lines |
| Tests | 2 files |
| Special files | `permissions.py` |

**Purpose:** RBAC for the ops dashboard. Maps staff users to dashboards (support, content, promo, verify, subs, extras, analytics) with levels: admin/power/user/qa/client.

### 4.5 `billing` — Invoicing & Payments
| Metric | Value |
|--------|-------|
| Models | `Invoice`, `InvoiceLineItem`, `PaymentAttempt`, `WebhookEvent` |
| Views | 84 lines |
| Services | 153 lines |
| Serializers | 74 lines |
| Tests | 1 file |
| Special files | `permissions.py` |

**Purpose:** Generic invoice system with statuses (draft → pending → paid/failed/cancelled/refunded). Payment attempts with idempotency. Webhook event storage. VAT calculation. Currently only **mock payment provider** — no real gateway integration yet.

### 4.6 `content` — CMS
| Metric | Value |
|--------|-------|
| Models | `SiteContentBlock`, `SiteLegalDocument`, `SiteLinks` |
| Views | 12 lines |
| Services | exists |
| Tests | 2 files |

**Purpose:** Static content management — onboarding screens, help text, legal documents (Terms, Privacy, Regulations), social/store links. File validation (PDF/DOC, 10MB max).

### 4.7 `core` — Infrastructure
| Metric | Value |
|--------|-------|
| Models | None |
| Special files | `health.py`, `logging_filters.py` |
| Tests | 1 file |

**Purpose:** Health check endpoints (`/health/`, `/health/live/`, `/health/ready/` — checks DB + Redis). Logging filter to exclude health check access logs.

### 4.8 `dashboard` — Ops Dashboard (Server-Rendered)
| Metric | Value |
|--------|-------|
| Models | None |
| Views | **4,236 lines** ⚠️ |
| URLs | 219 lines (100+ routes) |
| Tests | **0 files** ⚠️ |
| Special files | `auth.py`, `auth_views.py`, `content_views.py`, `reviews_views.py`, `exports.py`, `forms.py`, `templates/`, `static/`, `templatetags/` |

**Purpose:** Full internal operations dashboard with Django templates. Manages requests, providers, services, billing, support, verification, promo, subscriptions, extras, unified requests, analytics, access control, content, reviews. OTP-based staff login.  
**⚠️ MAJOR CONCERN:** Single 4,236-line views.py — a "God file" anti-pattern. Zero test coverage for the most complex module.

### 4.9 `extras` — Add-on Purchases
| Metric | Value |
|--------|-------|
| Models | `ExtraPurchase` (time-based or credit-based) |
| Views | 73 lines |
| Services | exists |
| Serializers | 24 lines |
| Tests | 1 file |
| Special files | `signals.py`, `permissions.py` |

**Purpose:** Purchasable add-ons (extra uploads, VIP support, promo boost, support tickets). Activated via signal on invoice paid.

### 4.10 `extras_portal` — Provider Extras Portal
| Metric | Value |
|--------|-------|
| Models | `ExtrasPortalSubscription`, `ExtrasPortalFinanceSettings`, `ExtrasPortalScheduledMessage`, `ExtrasPortalScheduledMessageRecipient` |
| Views | 450 lines |
| URLs | 24 lines |
| Tests | 0 |
| Special files | `auth.py`, `forms.py`, `templates/`, management command `send_due_extras_portal_messages` |

**Purpose:** Separate portal for providers to manage extended features — subscription status, finance/IBAN settings, scheduled messages to customers.

### 4.11 `features` — Feature Gating Engine
| Metric | Value |
|--------|-------|
| Models | None |
| Views | 3 lines |
| API | 21 lines |
| Special files | `checks.py`, `decorators.py`, `drf_permissions.py`, `exceptions.py`, `keys.py`, `middleware.py`, `upload_limits.py` |
| Tests | 2 files |

**Purpose:** Central feature gate — `has_feature(user, key)` checks subscription plan features first, falls back to extras/add-ons. Provides DRF permission class `HasFeature.with_key("promo_ads")`. Upload size limits based on plan tier (10/50/100 MB).

### 4.12 `marketplace` — Service Requests (Core Business)
| Metric | Value |
|--------|-------|
| Models | `ServiceRequest`, `Offer`, `RequestStatusLog`, `ServiceRequestAttachment` |
| API | **1,049 lines** |
| Views | 219 lines (template views) |
| Serializers | 447 lines |
| URLs | 132 lines |
| Tests | **8 files** (best covered) |
| Services | `services/actions.py` |

**Purpose:** Core marketplace — clients create service requests (normal/competitive/urgent), providers submit offers, client selects offer, request progresses through status machine (new → sent → accepted → in_progress → completed/cancelled/expired). Urgent requests auto-notify matching providers. Attachment support.

### 4.13 `messaging` — Real-Time Chat
| Metric | Value |
|--------|-------|
| Models | `Thread`, `Message`, `MessageRead`, `ThreadUserState` |
| API | 648 lines |
| Consumers | **513 lines** (WebSocket) |
| Views | 184 lines |
| Serializers | 86 lines |
| Tests | 4 files |
| Special files | `jwt_auth.py`, `pagination.py`, `permissions.py`, `routing.py` |

**Purpose:** WebSocket chat (Django Channels) tied to service requests + direct messaging. Thread-based with read receipts, favorites, archiving, blocking, client labels. JWT auth on WebSocket via query parameter. Two consumers: `RequestChatConsumer`, `ThreadConsumer`.

### 4.14 `notifications` — Push & In-App Notifications
| Metric | Value |
|--------|-------|
| Models | `EventLog`, `Notification`, `NotificationPreference`, `DeviceToken` |
| Views | 293 lines |
| Signals | 181 lines |
| Serializers | 33 lines |
| Tests | 2 files |
| Special files | `services.py`, `pagination.py` |

**Purpose:** In-app notifications with audience modes (client/provider/shared). Device token registration (Android/iOS/Web). Notification preferences per user per tier. Event logging. Signal-driven: auto-creates notifications on offer created, offer selected, new message, request status change.

### 4.15 `promo` — Advertising & Promotion
| Metric | Value |
|--------|-------|
| Models | `PromoRequest`, `PromoAsset`, `PromoAdPrice` |
| Views | 307 lines |
| Services | 209 lines |
| Serializers | 255 lines |
| Tests | 1 file |
| Special files | `signals.py`, `validators.py`, `permissions.py`, management command `expire_promo_requests` |

**Purpose:** Promotional campaigns — banner ads, popups, featured listings, profile boosts, push notifications. Complex pricing engine with base prices × position multiplier × frequency multiplier × days. Invoice auto-generation. Syncs to unified requests.

### 4.16 `providers` — Provider Profiles
| Metric | Value |
|--------|-------|
| Models | `Category`, `SubCategory`, `ProviderProfile`, `ProviderPortfolioItem`, `ProviderSpotlightItem`, `ProviderPortfolioLike/Save`, `ProviderSpotlightLike/Save`, `ProviderCategory`, `ProviderService`, `ProviderFollow`, `ProviderLike` (12 models) |
| Views | 737 lines |
| Serializers | 398 lines |
| URLs | 91 lines |
| Tests | 2 files |
| Management commands | 4 cleanup scripts (duplicate likes/follows/relations) |

**Purpose:** Provider profiles (individual/company) with categories, services, portfolio items, spotlight items, social interactions (like/save/follow). Verification badges (blue/green). Geo-location (lat/lng, coverage radius). SEO fields.

### 4.17 `reviews` — Rating System
| Metric | Value |
|--------|-------|
| Models | `Review` (with detailed sub-ratings) |
| Views | 183 lines |
| Serializers | 180 lines |
| Signals | 50 lines |
| Tests | 2 files |

**Purpose:** 5-star reviews on completed/cancelled/overdue requests. Sub-ratings: response speed, cost value, quality, credibility, on-time. Provider reply, management reply. Moderation (approved/rejected/hidden). Rating aggregation.

### 4.18 `subscriptions` — Subscription Plans
| Metric | Value |
|--------|-------|
| Models | `SubscriptionPlan`, `Subscription`, `FeatureKey` enum |
| Views | 44 lines |
| Services | 163 lines |
| Serializers | 18 lines |
| Tests | 1 file |
| Special files | `signals.py`, `permissions.py`, management command `seed_plans` |

**Purpose:** Subscription plans (monthly/yearly) with feature keys. Status machine: pending_payment → active → grace → expired → cancelled. Grace period (7 days). Invoice auto-generation. Unified request sync.

### 4.19 `support` — Help Desk
| Metric | Value |
|--------|-------|
| Models | `SupportTeam`, `SupportTicket`, `SupportAttachment`, `SupportComment`, `SupportStatusLog` |
| Views | 199 lines |
| Services | exists |
| Serializers | 133 lines |
| Tests | 1 file |
| Special files | `permissions.py`, `validators.py` |

**Purpose:** Support tickets (tech/subs/verify/suggest/ads/complaint/extras) with status tracking, team assignment, comments (internal/public), attachments, complaint/report targeting.

### 4.20 `unified_requests` — Request Aggregation Engine
| Metric | Value |
|--------|-------|
| Models | `UnifiedRequest`, `UnifiedRequestMetadata`, `UnifiedRequestAssignmentLog`, `UnifiedRequestStatusLog` |
| Services | 127 lines |
| Tests | 3 files |
| Management commands | `backfill_unified_requests` |

**Purpose:** Cross-module request aggregation — maps HD (helpdesk), MD (promo), AD (verification), SD (subscription), P (extras) into a single queryable/trackable system with status/assignment logs. **No URL routes** — consumed internally by dashboard.

### 4.21 `uploads` — File Validation
| Metric | Value |
|--------|-------|
| Models | None |
| Files | `validators.py` only |

**Purpose:** Shared file upload validators (size, extension). Used by other apps.

### 4.22 `verification` — Provider Verification
| Metric | Value |
|--------|-------|
| Models | `VerificationRequest`, `VerificationDocument`, `VerificationRequirement`, `VerificationRequirementAttachment`, `VerifiedBadge` |
| Views | 269 lines |
| Services | exists |
| Serializers | 214 lines |
| Tests | 1 file |
| Special files | `signals.py`, `validators.py`, `permissions.py` |

**Purpose:** Blue/green badge verification — providers submit documents (ID, CR, IBAN, license), requirements reviewed individually, invoice generated on approval, badge activated after payment (1-year validity). Syncs to unified requests.

---

## 5. Database Schema Overview

### Entity Relationship Summary

```
User (phone, role_state)
 ├── Wallet (1:1)
 ├── ProviderProfile (1:1, optional)
 │    ├── Category ←→ SubCategory (M2M via ProviderCategory)
 │    ├── ProviderService (1:N)
 │    ├── ProviderPortfolioItem (1:N) ← Likes, Saves
 │    ├── ProviderSpotlightItem (1:N) ← Likes, Saves
 │    ├── ProviderFollow (N:M)
 │    └── ProviderLike (N:M)
 │
 ├── ServiceRequest (1:N as client)
 │    ├── Offer (1:N from providers)
 │    ├── RequestStatusLog (1:N)
 │    ├── ServiceRequestAttachment (1:N)
 │    ├── Thread (1:1) → Message (1:N) → MessageRead
 │    └── Review (1:1)
 │
 ├── Invoice (1:N)
 │    ├── InvoiceLineItem (1:N)
 │    ├── PaymentAttempt (1:N)
 │    └── Links to: Subscription, VerificationRequest, PromoRequest, ExtraPurchase
 │
 ├── Subscription (1:N) → SubscriptionPlan
 ├── VerificationRequest (1:N) → VerificationDocument, VerificationRequirement → VerifiedBadge
 ├── PromoRequest (1:N) → PromoAsset
 ├── ExtraPurchase (1:N)
 ├── SupportTicket (1:N) → SupportAttachment, SupportComment, SupportStatusLog
 ├── UnifiedRequest (1:N) → Metadata, AssignmentLog, StatusLog
 ├── Notification (1:N), NotificationPreference, DeviceToken
 └── AuditLog (1:N)

Standalone:
 ├── SiteContentBlock, SiteLegalDocument, SiteLinks (CMS)
 ├── Dashboard, UserAccessProfile (RBAC)
 ├── SupportTeam
 ├── PromoAdPrice
 └── WebhookEvent
```

### Model Count by App
| App | Models |
|-----|--------|
| providers | 12 |
| marketplace | 4 |
| messaging | 4 |
| notifications | 4 |
| billing | 4 |
| support | 5 |
| verification | 5 |
| unified_requests | 4 |
| promo | 3 |
| accounts | 3 |
| content | 3 |
| reviews | 1 |
| subscriptions | 2 |
| extras | 1 |
| extras_portal | 4 |
| backoffice | 2 |
| audit | 1 |
| **Total** | **~62 models** |

---

## 6. WebSocket / Real-Time Features

- **Django Channels** with **Daphne** ASGI server
- **Two WebSocket endpoints:**
  - `ws/requests/<request_id>/` — `RequestChatConsumer` (request-bound chat)
  - `ws/thread/<thread_id>/` — `ThreadConsumer` (direct thread chat)
- **JWT Auth on WebSocket:** Token passed as `?token=` query parameter, validated by `JwtAuthMiddleware`
- **Channel Layer:** Redis in production, InMemoryChannelLayer in dev
- **Features:** real-time message delivery, typing indicators possible, read receipts
- **Consumer size:** 513 lines — fairly complex with blocking detection, thread state management

---

## 7. Third-Party Integrations

| Integration | Status |
|-------------|--------|
| **Payment Gateway** | ⚠️ **Mock only** — `PaymentProvider` has MANUAL + MOCK; no real gateway (Moyasar/HyperPay/Tap/STC Pay commented out) |
| **SMS/OTP** | ⚠️ **No SMS provider** — OTP generated locally, dev mode accepts any code |
| **Push Notifications** | ⚠️ **DeviceToken model exists** but no Firebase/APNs integration |
| **Sentry** | ✅ Configured in prod (0.2 trace sample rate) |
| **Redis** | ✅ For Channels layer + optional cache |
| **Celery** | ⚠️ **In prod requirements only** — no `celery.py` config, no actual tasks |
| **File Storage** | Local filesystem + Render persistent disk (no S3/cloud storage) |

---

## 8. Code Quality Issues

### Critical Issues

1. **`dashboard/views.py` is 4,236 lines** — A God file containing all ops dashboard logic. Should be split into separate view modules (at minimum per-domain: support_views, billing_views, verification_views, promo_views, subscription_views, etc.)

2. **Zero test coverage on dashboard** — The most complex module (4,236 lines) has 0 test files.

3. **No real payment gateway** — Billing infrastructure is built but only mock provider exists. No Moyasar/HyperPay/Tap integration.

4. **No SMS provider** — OTP system works but never sends actual SMS. Dev mode accepts any 4-digit code.

5. **No push notification sender** — `DeviceToken` model stores tokens but no Firebase Cloud Messaging or APNs integration exists.

6. **`SubscriptionRefreshMiddleware` runs on EVERY request** — Queries the database on every authenticated request to refresh subscription status. This is a performance bottleneck.

### Security Concerns

7. **`OTP_APP_BYPASS` in production settings** — While defaulting to disabled, the mechanism exists and could be accidentally enabled. The code comment warns about this but it's still risky.

8. **`CORS_ALLOW_ALL_ORIGINS = True`** in dev settings (inherited from base) — acceptable for dev but should never leak to prod.

9. **`SECRET_KEY` has a dev default** — `dev-secret-key-change-me` hardcoded. If `DJANGO_SECRET_KEY` env var missing in prod, this is catastrophic.

10. **OTP code is only 4 digits** — With 5/min throttle, brute-force is feasible (10,000 combinations × multiple phones).

11. **No CSRF protection on WebSocket** — JWT token in query string is visible in server logs and browser history.

### Design Issues

12. **`marketplace/api.py` at 1,049 lines** — Should be split into viewsets or separate view modules.

13. **Generic reference pattern (`reference_type`/`reference_id`)** — Used in Invoice and AuditLog. This prevents foreign key integrity and makes joins impossible. Consider using Django's `ContentType` framework or separate FK fields.

14. **Duplicate cleanup management commands** — 4 separate commands to clean duplicate portfolio likes, provider follows, provider likes, provider relations. This suggests the `UniqueConstraint`s were added after data corruption.

15. **No pagination configuration in DRF settings** — Missing `DEFAULT_PAGINATION_CLASS` in REST_FRAMEWORK config. Individual views must set this manually.

16. **`phone` field nullable on User** — Comment says "temporary" but it's still nullable, which could cause issues since it's the `USERNAME_FIELD`.

---

## 9. Performance Concerns

### N+1 Query Risks
1. **`SubscriptionRefreshMiddleware`** — Runs `Subscription.objects.filter(user=user).order_by("-id").first()` on every request. Should at minimum use caching.
2. **Notification signals** — `post_save` signals on `Offer`, `Message`, `RequestStatusLog` do additional DB queries synchronously.
3. **Dashboard views** — 4,236 lines of template views with manual queryset building; likely many N+1 issues.
4. **Deep `select_related` chains** in marketplace/messaging consumers.

### Missing Indexes
- Generally well-indexed — most models have appropriate `Index()` and `UniqueConstraint` definitions.
- `ServiceRequest` missing index on `(client, status)` and `(provider, status)` for common dashboard queries.
- `Invoice` missing index on `(user, status)` and `(reference_type, reference_id)`.

### Missing Caching
- **No cache framework configured** — No `CACHES` setting in `base.py`. Redis is available in prod but not configured for Django cache.
- No caching on:
  - Category/SubCategory lists (rarely change)
  - Subscription plan lists
  - Feature checks (`has_feature` queries on every gated view)
  - Promo pricing lookups

### Other Performance Issues
- **`STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"`** — Deprecated in Django 4.2+. Should use `STORAGES` dict.
- **No database connection pooling** — `conn_max_age=600` is set but no PgBouncer or similar.
- **File uploads stored locally** — No CDN, no thumbnail pre-generation for portfolio items (though `media_thumbnails.py` exists in providers).

---

## 10. Testing Assessment

| App | Test Files | Coverage |
|-----|-----------|----------|
| marketplace | 8 | Best covered |
| messaging | 4 | Good |
| unified_requests | 3 | Good |
| accounts | 2 | Basic |
| analytics | 2 | Basic |
| backoffice | 2 | Basic |
| content | 2 | Basic |
| features | 2 | Basic |
| notifications | 2 | Basic |
| providers | 2 | Basic |
| reviews | 2 | Basic |
| billing | 1 | Minimal |
| extras | 1 | Minimal |
| promo | 1 | Minimal |
| subscriptions | 1 | Minimal |
| support | 1 | Minimal |
| verification | 1 | Minimal |
| **dashboard** | **0** | **None** ⚠️ |
| extras_portal | 0 | None ⚠️ |

**Test framework:** pytest + pytest-django + pytest-asyncio + pytest-mock  
**Test config:** `pytest.ini` with `asyncio_mode = auto`

---

## 11. Missing Best Practices

1. **No API documentation** — No Swagger/OpenAPI/drf-spectacular. API contract exists only in docs/ markdown files.
2. **No database migration squashing** — Likely many migration files after iterative development.
3. **No Celery configuration** — In prod requirements but no `celery.py`, no task definitions, no beat schedule. Scheduled operations (expire promos, send messages) rely on management commands run manually or via cron.
4. **No structured logging in dev** — Only prod has `LOGGING` configuration.
5. **No email backend configured** — No password reset, email notifications, or admin emails.
6. **No `select_related`/`prefetch_related` in DRF serializers** — Serializers don't override `get_queryset` pattern consistently.
7. **No API versioning** — All endpoints under `/api/` without version prefix.
8. **No rate limiting on WebSocket** — Chat consumers have no message rate limiting.
9. **No file size limits in Channels** — WebSocket messages not size-limited at the consumer level.
10. **No soft-delete pattern** — Most models use hard deletes via CASCADE.

---

## 12. Summary Metrics

| Metric | Value |
|--------|-------|
| Total apps | 22 |
| Total models | ~62 |
| Source files (excl. migrations) | 273 |
| Source lines (excl. migrations) | ~28,660 |
| Largest file | `dashboard/views.py` (4,236 lines) |
| Second largest | `marketplace/api.py` (1,049 lines) |
| Test directories | 18 / 22 apps |
| Test files | ~37 |
| Management commands | 8 |
| WebSocket consumers | 2 |
| URL namespaces | 19 (API) + dashboard + extras_portal |
| Language | Arabic-first (ar, Asia/Riyadh) |
| Currency | SAR with 15% VAT |

---

## 13. Recommendations (Priority Order)

### P0 — Critical
1. **Integrate real payment gateway** (Moyasar/HyperPay/Tap) — billing infrastructure is ready
2. **Integrate SMS provider** for OTP delivery
3. **Split `dashboard/views.py`** into domain-specific modules
4. **Add tests for dashboard** — 0% coverage on 4,236 lines

### P1 — High
5. **Configure Django cache** (Redis) and cache feature checks, plan lists, categories
6. **Fix `SubscriptionRefreshMiddleware`** — move to per-view or cached check
7. **Integrate Firebase Cloud Messaging** for push notifications
8. **Add API documentation** (drf-spectacular)
9. **Remove `OTP_APP_BYPASS`** mechanism from production settings entirely

### P2 — Medium
10. **Set up Celery** properly with beat schedule for periodic tasks
11. **Add API versioning** (`/api/v1/`)
12. **Configure cloud file storage** (S3/GCS) with CDN
13. **Add missing database indexes** on Invoice and ServiceRequest
14. **Fix deprecated `STATICFILES_STORAGE`** → use `STORAGES` setting
15. **Add pagination defaults** to DRF settings

### P3 — Low
16. Squash migrations
17. Add WebSocket rate limiting
18. Implement soft-delete for critical models
19. Add structured logging in development
20. Make `User.phone` non-nullable
