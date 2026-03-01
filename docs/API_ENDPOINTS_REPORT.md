# Nawafeth — Complete API Endpoints & Flutter Routes Report

> Auto-generated from codebase analysis. All paths, methods, and auth requirements are verified from source.

---

## Table of Contents

1. [Accounts](#1-accounts--apiaccounts)
2. [Providers](#2-providers--apiproviders)
3. [Marketplace](#3-marketplace--apimarketplace)
4. [Messaging](#4-messaging--apimessaging)
5. [Notifications](#5-notifications--apinotifications)
6. [Reviews](#6-reviews--apireviews)
7. [Support](#7-support--apisupport)
8. [Subscriptions](#8-subscriptions--apisubscriptions)
9. [Promo](#9-promo--apipromo)
10. [Verification](#10-verification--apiverification)
11. [Billing](#11-billing--apibilling)
12. [Content](#12-content--apicontent)
13. [Backoffice](#13-backoffice--apibackoffice)
14. [Extras](#14-extras--apiextras)
15. [Features](#15-features--apifeatures)
16. [Analytics](#16-analytics--apianalytics)
17. [Health & Root](#17-health--root)
18. [Flutter Mobile Routes & Screens](#18-flutter-mobile-routes--screens)
19. [Auth Summary Matrix](#19-auth-summary-matrix)

---

## 1. Accounts — `/api/accounts/`

| # | Endpoint | Method(s) | Auth | Permission Class | Notes |
|---|----------|-----------|------|------------------|-------|
| 1 | `/api/accounts/otp/send/` | POST | No | `AllowAny` | Send OTP to phone. Throttled (`otp` scope). Returns `dev_code` in DEBUG. |
| 2 | `/api/accounts/otp/verify/` | POST | No | `AllowAny` | Verify OTP → returns JWT `access` + `refresh` tokens. Throttled (`otp` scope). |
| 3 | `/api/accounts/username-availability/` | GET | No | `AllowAny` | Query param `?username=xxx`. Returns `{available: bool}`. |
| 4 | `/api/accounts/complete/` | POST | Yes | `IsAuthenticated` | Upgrade from PHONE_ONLY → CLIENT. Fields: `username`, `first_name`, `last_name`, `email`, `password`, `city?`. |
| 5 | `/api/accounts/wallet/` | GET, POST | Yes | `IsAtLeastPhoneOnly` | Get or open wallet info. |
| 6 | `/api/accounts/token/` | POST | No | `AllowAny` | JWT token obtain (username+password). Throttled (`auth` scope). |
| 7 | `/api/accounts/token/refresh/` | POST | No | `AllowAny` | JWT token refresh. Throttled (`refresh` scope). |
| 8 | `/api/accounts/me/` | GET, PATCH, PUT, DELETE | Yes | `IsAuthenticated` | GET=profile, PATCH/PUT=update fields (`email`,`first_name`,`last_name`,`city`,`phone`), DELETE=delete account. |
| 9 | `/api/accounts/logout/` | POST | Yes | `IsAuthenticated` | Blacklist refresh token. Body: `{refresh: "..."}`. |
| 10 | `/api/accounts/delete/` | DELETE | Yes | `IsAuthenticated` | Permanently delete account. |

### Key Response Fields for `/me/`:
```json
{
  "id", "phone", "email", "username", "first_name", "last_name", "city",
  "role_state", "has_provider_profile", "is_provider",
  "following_count", "likes_count", "favorites_media_count",
  "provider_profile_id", "provider_display_name", "provider_city",
  "provider_followers_count", "provider_likes_received_count",
  "provider_rating_avg", "provider_rating_count"
}
```

---

## 2. Providers — `/api/providers/`

### Public Endpoints (AllowAny)

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/providers/categories/` | GET | No | `AllowAny` | List active service categories. |
| 2 | `/api/providers/list/` | GET | No | `AllowAny` | Search/list providers. Query params: `q`, `city`, `has_location`, `accepts_urgent`, `category_id`, `subcategory_id`. |
| 3 | `/api/providers/<id>/` | GET | No | `AllowAny` | Provider detail with stats. |
| 4 | `/api/providers/<provider_id>/portfolio/` | GET | No | `AllowAny` | Provider's portfolio items (media). |
| 5 | `/api/providers/<provider_id>/spotlights/` | GET | No | `AllowAny` | Provider's spotlight items. |
| 6 | `/api/providers/<provider_id>/subcategories/` | GET | No | `AllowAny` | Provider's service subcategories. |
| 7 | `/api/providers/<provider_id>/services/` | GET | No | `AllowAny` | Provider's active services. |
| 8 | `/api/providers/<provider_id>/followers/` | GET | No | `AllowAny` | Users who follow this provider. |
| 9 | `/api/providers/<provider_id>/following/` | GET | No | `AllowAny` | Providers that this provider follows. |
| 10 | `/api/providers/<provider_id>/stats/` | GET | No | `AllowAny` | Public stats: completed_requests, followers, following, likes, rating. |

### Authenticated — My Provider Profile

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 11 | `/api/providers/register/` | POST | Yes | `IsAtLeastClient` | Register as provider. Upgrades role to PROVIDER. |
| 12 | `/api/providers/me/profile/` | GET, PATCH, PUT | Yes | `IsAtLeastClient` | My provider profile (retrieve/update). |
| 13 | `/api/providers/me/subcategories/` | GET, PUT | Yes | `IsAtLeastProvider` | Get/set my service subcategory IDs. |
| 14 | `/api/providers/me/services/` | GET, POST | Yes | `IsAtLeastProvider` | List/create my services. |
| 15 | `/api/providers/me/services/<pk>/` | GET, PUT, PATCH, DELETE | Yes | `IsAtLeastProvider` | CRUD single service. |
| 16 | `/api/providers/me/portfolio/` | GET, POST | Yes | `IsAtLeastProvider` | List/create portfolio items. |
| 17 | `/api/providers/me/portfolio/<pk>/` | GET, DELETE | Yes | `IsAtLeastProvider` | Retrieve/delete portfolio item. |
| 18 | `/api/providers/me/spotlights/` | GET, POST | Yes | `IsAtLeastProvider` | List/create spotlight items. |
| 19 | `/api/providers/me/spotlights/<pk>/` | GET, DELETE | Yes | `IsAtLeastProvider` | Retrieve/delete spotlight item. |
| 20 | `/api/providers/me/following/` | GET | Yes | `IsAtLeastPhoneOnly` | Providers I follow. |
| 21 | `/api/providers/me/likes/` | GET | Yes | `IsAtLeastPhoneOnly` | Providers I liked. |
| 22 | `/api/providers/me/followers/` | GET | Yes | `IsAtLeastProvider` | My followers list. |
| 23 | `/api/providers/me/likers/` | GET | Yes | `IsAtLeastProvider` | Users who liked my profile. |
| 24 | `/api/providers/me/favorites/` | GET | Yes | `IsAtLeastPhoneOnly` | Portfolio items I saved (bookmarked). |
| 25 | `/api/providers/me/favorites/spotlights/` | GET | Yes | `IsAtLeastPhoneOnly` | Spotlight items I saved. |
| 26 | `/api/providers/me/likes/media/` | GET | Yes | `IsAtLeastPhoneOnly` | Portfolio items I liked. |
| 27 | `/api/providers/me/likes/spotlights/` | GET | Yes | `IsAtLeastPhoneOnly` | Spotlight items I liked. |

### Social Actions (Authenticated)

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 28 | `/api/providers/<provider_id>/follow/` | POST | Yes | `IsAtLeastPhoneOnly` | Follow a provider. |
| 29 | `/api/providers/<provider_id>/unfollow/` | POST | Yes | `IsAtLeastPhoneOnly` | Unfollow a provider. |
| 30 | `/api/providers/<provider_id>/like/` | POST | Yes | `IsAtLeastPhoneOnly` | Like a provider. |
| 31 | `/api/providers/<provider_id>/unlike/` | POST | Yes | `IsAtLeastPhoneOnly` | Unlike a provider. |
| 32 | `/api/providers/portfolio/<item_id>/like/` | POST | Yes | `IsAtLeastPhoneOnly` | Like a portfolio item. |
| 33 | `/api/providers/portfolio/<item_id>/unlike/` | POST | Yes | `IsAtLeastPhoneOnly` | Unlike a portfolio item. |
| 34 | `/api/providers/portfolio/<item_id>/save/` | POST | Yes | `IsAtLeastPhoneOnly` | Save (bookmark) portfolio item. |
| 35 | `/api/providers/portfolio/<item_id>/unsave/` | POST | Yes | `IsAtLeastPhoneOnly` | Unsave portfolio item. |
| 36 | `/api/providers/spotlights/<item_id>/like/` | POST | Yes | `IsAtLeastPhoneOnly` | Like a spotlight item. |
| 37 | `/api/providers/spotlights/<item_id>/unlike/` | POST | Yes | `IsAtLeastPhoneOnly` | Unlike a spotlight item. |
| 38 | `/api/providers/spotlights/<item_id>/save/` | POST | Yes | `IsAtLeastPhoneOnly` | Save spotlight item. |
| 39 | `/api/providers/spotlights/<item_id>/unsave/` | POST | Yes | `IsAtLeastPhoneOnly` | Unsave spotlight item. |

---

## 3. Marketplace — `/api/marketplace/`

### Client Endpoints

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/marketplace/requests/create/` | POST | Yes | `IsAtLeastClient` | Create service request. Fields: `request_type`, `title`, `description`, `subcategory_id`, `city`, `provider_id?`, `dispatch_mode?`. |
| 2 | `/api/marketplace/client/requests/` | GET | Yes | `IsAtLeastClient` | My requests as client. Filters: `status_group`, `status`, `type`, `q`. |
| 3 | `/api/marketplace/client/requests/<request_id>/` | GET, PATCH, PUT | Yes | `IsAtLeastClient` | Client request detail / update (title, description). |
| 4 | `/api/marketplace/requests/<request_id>/offers/` | GET | Yes | `IsAtLeastClient` | List offers for my request. |
| 5 | `/api/marketplace/offers/<offer_id>/accept/` | POST | Yes | `IsAtLeastClient` | Accept an offer (assigns provider). |
| 6 | `/api/marketplace/requests/<request_id>/cancel/` | POST | Yes | `IsAtLeastClient` | Cancel a request. |
| 7 | `/api/marketplace/requests/<request_id>/reopen/` | POST | Yes | `IsAtLeastClient` | Reopen a cancelled request. |
| 8 | `/api/marketplace/requests/<request_id>/provider-inputs/decision/` | POST | Yes | `IsAtLeastClient` | Approve/reject provider's execution inputs. Body: `{approved: bool, note?}`. |

### Provider Endpoints

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 9 | `/api/marketplace/provider/requests/` | GET | Yes | `IsAuthenticated + IsProvider` | My assigned requests. Filters: `status_group`, `client_user_id`. |
| 10 | `/api/marketplace/provider/requests/<request_id>/detail/` | GET | Yes | `IsAuthenticated + IsProvider` | Provider request detail. |
| 11 | `/api/marketplace/provider/requests/<request_id>/accept/` | POST | Yes | `IsAuthenticated + IsProvider` | Accept an assigned (normal) request. |
| 12 | `/api/marketplace/provider/requests/<request_id>/reject/` | POST | Yes | `IsAuthenticated + IsProvider` | Reject/cancel an assigned request. Body: `{cancel_reason, canceled_at, note?}`. |
| 13 | `/api/marketplace/provider/requests/<request_id>/progress-update/` | POST | Yes | `IsAuthenticated + IsProvider` | Update progress: `expected_delivery_at`, `estimated_service_amount`, etc. |
| 14 | `/api/marketplace/provider/urgent/available/` | GET | Yes | `IsAuthenticated + IsProvider` | Available urgent requests matching my specialties. |
| 15 | `/api/marketplace/provider/competitive/available/` | GET | Yes | `IsAuthenticated + IsProvider` | Available competitive requests matching my specialties. |
| 16 | `/api/marketplace/requests/urgent/accept/` | POST | Yes | `IsAuthenticated + IsProvider` | Accept an urgent request. Body: `{request_id}`. |
| 17 | `/api/marketplace/requests/<request_id>/offers/create/` | POST | Yes | `IsAuthenticated + IsProvider` | Create offer for competitive request. |
| 18 | `/api/marketplace/requests/<request_id>/start/` | POST | Yes | `IsAuthenticated + IsProvider` | Start execution. Body: `{expected_delivery_at, estimated_service_amount, received_amount, remaining_amount, note?}`. |
| 19 | `/api/marketplace/requests/<request_id>/complete/` | POST | Yes | `IsAuthenticated + IsProvider` | Complete request. Body: `{delivered_at, actual_service_amount, note?}`. |

### HTML/Dashboard Views (session-based)

| # | Endpoint | Method(s) | Auth | Notes |
|---|----------|-----------|------|-------|
| 20 | `/api/marketplace/provider/requests/page/` | GET | Session | HTML view for provider requests. |
| 21 | `/api/marketplace/requests/<request_id>/` | GET | Session | HTML request detail. |
| 22 | `/api/marketplace/requests/<request_id>/action/` | POST | Session | HTML request action form. |

---

## 4. Messaging — `/api/messaging/`

### Request-based Messaging

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/messaging/requests/<request_id>/thread/` | GET, POST | Yes | `IsAtLeastPhoneOnly + IsRequestParticipant` | Get/create thread for a service request. |
| 2 | `/api/messaging/requests/<request_id>/messages/` | GET | Yes | `IsAtLeastPhoneOnly + IsRequestParticipant` | List messages (paginated, newest first). |
| 3 | `/api/messaging/requests/<request_id>/messages/send/` | POST | Yes | `IsAtLeastPhoneOnly + IsRequestParticipant` | Send message. Supports file attachment (multipart). |
| 4 | `/api/messaging/requests/<request_id>/messages/read/` | POST | Yes | `IsAtLeastPhoneOnly + IsRequestParticipant` | Mark all messages in thread as read. |

### Direct Messaging (no request required)

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 5 | `/api/messaging/direct/thread/` | POST | Yes | `IsAtLeastPhoneOnly` | Get/create direct thread. Body: `{provider_id}`. |
| 6 | `/api/messaging/direct/thread/<thread_id>/messages/` | GET | Yes | `IsAtLeastPhoneOnly` | List messages in direct thread. |
| 7 | `/api/messaging/direct/thread/<thread_id>/messages/send/` | POST | Yes | `IsAtLeastPhoneOnly` | Send message in direct thread. |
| 8 | `/api/messaging/direct/thread/<thread_id>/messages/read/` | POST | Yes | `IsAtLeastPhoneOnly` | Mark direct thread messages as read. |
| 9 | `/api/messaging/direct/threads/` | GET | Yes | `IsAtLeastPhoneOnly` | List all my direct threads. Query: `?mode=client|provider`. |

### Thread State Management

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 10 | `/api/messaging/threads/states/` | GET | Yes | `IsAtLeastPhoneOnly` | All my thread states (favorite/block/archive). |
| 11 | `/api/messaging/thread/<thread_id>/state/` | GET | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Get state for specific thread. |
| 12 | `/api/messaging/thread/<thread_id>/favorite/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Toggle favorite. Body: `{action: "remove"}` to unfavorite. |
| 13 | `/api/messaging/thread/<thread_id>/archive/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Toggle archive. |
| 14 | `/api/messaging/thread/<thread_id>/block/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Toggle block. Sends WS notification. |
| 15 | `/api/messaging/thread/<thread_id>/report/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Report thread → creates support ticket. Body: `{reason, details?, reported_label?}`. |
| 16 | `/api/messaging/thread/<thread_id>/unread/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Mark thread as unread. |
| 17 | `/api/messaging/thread/<thread_id>/messages/<message_id>/delete/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Delete own message. |
| 18 | `/api/messaging/thread/<thread_id>/favorite-label/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Set favorite label: `potential_client`, `important_conversation`, `incomplete_contact`. |
| 19 | `/api/messaging/thread/<thread_id>/client-label/` | POST | Yes | `IsAtLeastPhoneOnly + IsThreadParticipant` | Tag client: `potential`, `current`, `past`. |

### Dashboard Fallback

| # | Endpoint | Method(s) | Auth | Notes |
|---|----------|-----------|------|-------|
| 20 | `/api/messaging/thread/<thread_id>/post/` | POST | Session+CSRF | Send message via session auth (dashboard fallback). |

---

## 5. Notifications — `/api/notifications/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/notifications/` | GET | Yes | `IsAtLeastPhoneOnly` | List notifications (paginated). Query: `?mode=client|provider`. |
| 2 | `/api/notifications/unread-count/` | GET | Yes | `IsAtLeastPhoneOnly` | Get unread count. Query: `?mode=client|provider`. |
| 3 | `/api/notifications/mark-read/<notif_id>/` | POST | Yes | `IsAtLeastPhoneOnly` | Mark single notification as read. |
| 4 | `/api/notifications/mark-all-read/` | POST | Yes | `IsAtLeastPhoneOnly` | Mark all notifications as read. |
| 5 | `/api/notifications/actions/<notif_id>/` | POST, DELETE | Yes | `IsAtLeastPhoneOnly` | POST: pin/follow_up toggle. DELETE: remove notification. |
| 6 | `/api/notifications/preferences/` | GET, PATCH | Yes | `IsAtLeastPhoneOnly` | GET: list prefs. PATCH: `{updates: [{key, enabled}]}`. |
| 7 | `/api/notifications/delete-old/` | POST | Yes | `IsAtLeastClient` | Delete notifications older than retention (90 days). |
| 8 | `/api/notifications/device-token/` | POST | Yes | `IsAtLeastClient` | Register FCM token. Body: `{token, platform}`. |

---

## 6. Reviews — `/api/reviews/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/reviews/requests/<request_id>/review/` | POST | Yes | `IsAtLeastClient` | Create review. Fields: `rating`, `response_speed?`, `cost_value?`, `quality?`, `credibility?`, `on_time?`, `comment?`. |
| 2 | `/api/reviews/reviews/<review_id>/provider-reply/` | POST, DELETE | Yes | `IsAtLeastProvider` | POST: add/edit reply. DELETE: remove reply. |
| 3 | `/api/reviews/providers/<provider_id>/reviews/` | GET | No | `AllowAny` | Public list of approved reviews for a provider. |
| 4 | `/api/reviews/providers/<provider_id>/rating/` | GET | No | `AllowAny` | Rating summary with axis breakdowns. |

---

## 7. Support — `/api/support/`

### Client

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/support/teams/` | GET | Yes | `IsRequesterOrBackofficeSupport` | List active support teams. |
| 2 | `/api/support/tickets/create/` | POST | Yes | `IsRequesterOrBackofficeSupport` | Create support ticket. |
| 3 | `/api/support/tickets/my/` | GET | Yes | `IsRequesterOrBackofficeSupport` | My tickets. Filters: `status`, `type`. |
| 4 | `/api/support/tickets/<pk>/` | GET | Yes | `IsRequesterOrBackofficeSupport` | Ticket detail. |
| 5 | `/api/support/tickets/<pk>/comments/` | POST | Yes | `IsRequesterOrBackofficeSupport` | Add comment. Body: `{text, is_internal?}`. |
| 6 | `/api/support/tickets/<pk>/attachments/` | POST | Yes | `IsRequesterOrBackofficeSupport` | Upload attachment (multipart `file`). |

### Backoffice

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 7 | `/api/support/backoffice/tickets/` | GET | Yes | `IsRequesterOrBackofficeSupport` | All tickets. Filters: `status`, `type`, `priority`, `q`. |
| 8 | `/api/support/backoffice/tickets/<pk>/assign/` | PATCH | Yes | `IsRequesterOrBackofficeSupport` | Assign ticket. Body: `{assigned_team?, assigned_to?, note?}`. |
| 9 | `/api/support/backoffice/tickets/<pk>/status/` | PATCH | Yes | `IsRequesterOrBackofficeSupport` | Change status. Body: `{status, note?}`. |

---

## 8. Subscriptions — `/api/subscriptions/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/subscriptions/plans/` | GET | Yes | `IsOwnerOrBackofficeSubscriptions` | List active subscription plans. |
| 2 | `/api/subscriptions/my/` | GET | Yes | `IsOwnerOrBackofficeSubscriptions` | My subscriptions. |
| 3 | `/api/subscriptions/subscribe/<plan_id>/` | POST | Yes | `IsOwnerOrBackofficeSubscriptions` | Subscribe to a plan → creates subscription + invoice. |

---

## 9. Promo — `/api/promo/`

### Public

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/promo/banners/home/` | GET | No | `AllowAny` | Active home banner ads. Query: `?limit=N`. |
| 2 | `/api/promo/active/` | GET | No | `AllowAny` | Active promo placements. Filters: `ad_type`, `city`, `category`, `limit`. |

### Client

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 3 | `/api/promo/requests/create/` | POST | Yes | `IsOwnerOrBackofficePromo` | Create promo request. |
| 4 | `/api/promo/requests/my/` | GET | Yes | `IsOwnerOrBackofficePromo` | My promo requests. |
| 5 | `/api/promo/requests/<pk>/` | GET | Yes | `IsOwnerOrBackofficePromo` | Promo request detail. |
| 6 | `/api/promo/requests/<pk>/assets/` | POST | Yes | `IsOwnerOrBackofficePromo` | Upload promo asset (multipart `file`). |

### Backoffice

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 7 | `/api/promo/backoffice/requests/` | GET | Yes | `IsOwnerOrBackofficePromo` | All promo requests. |
| 8 | `/api/promo/backoffice/requests/<pk>/assign/` | PATCH | Yes | `IsOwnerOrBackofficePromo` | Assign promo request. |
| 9 | `/api/promo/backoffice/requests/<pk>/quote/` | POST | Yes | `IsOwnerOrBackofficePromo` | Quote → creates invoice. |
| 10 | `/api/promo/backoffice/requests/<pk>/reject/` | POST | Yes | `IsOwnerOrBackofficePromo` | Reject promo request. |

---

## 10. Verification — `/api/verification/`

### Client

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/verification/requests/create/` | POST | Yes | `IsOwnerOrBackofficeVerify` | Create verification request. |
| 2 | `/api/verification/requests/my/` | GET | Yes | `IsOwnerOrBackofficeVerify` | My verification requests. |
| 3 | `/api/verification/requests/<pk>/` | GET | Yes | `IsOwnerOrBackofficeVerify` | Verification request detail. |
| 4 | `/api/verification/requests/<pk>/documents/` | POST | Yes | `IsOwnerOrBackofficeVerify` | Upload document (multipart `file`, `doc_type`, `title?`). |
| 5 | `/api/verification/requests/<pk>/requirements/<req_id>/attachments/` | POST | Yes | `IsOwnerOrBackofficeVerify` | Upload requirement attachment. |

### Backoffice

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 6 | `/api/verification/backoffice/requests/` | GET | Yes | `IsOwnerOrBackofficeVerify` | All verification requests. Filters: `status`, `q`. |
| 7 | `/api/verification/backoffice/requests/<pk>/assign/` | PATCH | Yes | `IsOwnerOrBackofficeVerify` | Assign to operator. |
| 8 | `/api/verification/backoffice/documents/<doc_id>/decision/` | POST | Yes | `IsOwnerOrBackofficeVerify` | Approve/reject document. |
| 9 | `/api/verification/backoffice/requirements/<req_id>/decision/` | POST | Yes | `IsOwnerOrBackofficeVerify` | Approve/reject requirement. |
| 10 | `/api/verification/backoffice/requests/<pk>/finalize/` | POST | Yes | `IsOwnerOrBackofficeVerify` | Finalize verification → creates invoice. |

---

## 11. Billing — `/api/billing/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/billing/invoices/` | POST | Yes | (default DRF) | Create invoice. |
| 2 | `/api/billing/invoices/my/` | GET | Yes | (default DRF) | My invoices. |
| 3 | `/api/billing/invoices/<pk>/` | GET | Yes | `IsInvoiceOwner` | Invoice detail. |
| 4 | `/api/billing/invoices/<pk>/init-payment/` | POST | Yes | (owner check in code) | Init payment → returns `checkout_url`. Body: `{provider, idempotency_key?}`. |
| 5 | `/api/billing/webhooks/<provider>/` | POST | No | None (no auth) | Payment webhook receiver. |

---

## 12. Content — `/api/content/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/content/public/` | GET | No | `AllowAny` | Public site content (about, terms, FAQ, etc.). |

---

## 13. Backoffice — `/api/backoffice/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/backoffice/dashboards/` | GET | Yes | `BackofficeAccessPermission` | List active dashboards. |
| 2 | `/api/backoffice/me/access/` | GET | Yes | `BackofficeAccessPermission` | My access profile. |

---

## 14. Extras — `/api/extras/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/extras/catalog/` | GET | Yes | `IsOwnerOrBackofficeExtras` | Extras catalog (SKU, title, price). |
| 2 | `/api/extras/my/` | GET | Yes | `IsOwnerOrBackofficeExtras` | My purchased extras. |
| 3 | `/api/extras/buy/<sku>/` | POST | Yes | `IsOwnerOrBackofficeExtras` | Buy extra → creates purchase + invoice. |

---

## 15. Features — `/api/features/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/features/my/` | GET | Yes | (IsAuthenticated default) | My features: `verify_blue`, `verify_green`, `promo_ads`, `priority_support`, `max_upload_mb`. |

---

## 16. Analytics — `/api/analytics/`

| # | Endpoint | Method(s) | Auth | Permission | Notes |
|---|----------|-----------|------|------------|-------|
| 1 | `/api/analytics/kpis/` | GET | Yes | `IsBackofficeAnalytics` | Dashboard KPIs. Query: `?start_date=&end_date=`. |
| 2 | `/api/analytics/revenue/daily/` | GET | Yes | `IsBackofficeAnalytics` | Daily revenue chart. |
| 3 | `/api/analytics/revenue/monthly/` | GET | Yes | `IsBackofficeAnalytics` | Monthly revenue chart. |
| 4 | `/api/analytics/requests/breakdown/` | GET | Yes | `IsBackofficeAnalytics` | Request status breakdown. |
| 5 | `/api/analytics/export/paid-invoices.csv` | GET | Yes | `IsBackofficeAnalytics` | CSV export of paid invoices. |

---

## 17. Health & Root

| # | Endpoint | Method(s) | Auth | Notes |
|---|----------|-----------|------|-------|
| 1 | `/` | GET | No | Mobile web home page (HTML). |
| 2 | `/healthz/` | GET | No | Simple health check. |
| 3 | `/health/` | GET | No | Health check view. |
| 4 | `/health/live/` | GET | No | Liveness probe. |
| 5 | `/health/ready/` | GET | No | Readiness probe. |
| 6 | `/admin-panel/` | GET | Session | Django admin. |
| 7 | `/dashboard/` | GET | Session | Dashboard app (HTML). |
| 8 | `/portal/extras/` | GET | Session | Extras portal (HTML). |
| 9 | `/mobile-web/` | GET | No | Mobile web views. |

---

## 18. Flutter Mobile Routes & Screens

### Named Routes (from `main.dart`)

| Route | Screen Class | Mode Guard | Description |
|-------|-------------|------------|-------------|
| `/onboarding` | `OnboardingScreen` | None | Initial onboarding/welcome. |
| `/home` | `HomeScreen` | None | Main home screen. |
| `/chats` | `MyChatsScreen` | None | Chat threads list. |
| `/orders` | `OrdersHubScreen` | None | Orders hub (client & provider). |
| `/interactive` | `InteractiveScreen` | None | Interactive feed (portfolio/spotlights). |
| `/profile` | `MyProfileScreen` | None | My profile. |
| `/add_service` | `AddServiceScreen` | Client only | Add service request. |
| `/login` | `LoginScreen` | None | Phone login / OTP. |
| `/search_provider` | `SearchProviderScreen` | Client only | Search for providers. |
| `/urgent_request` | `UrgentRequestScreen` | Client only | Create urgent request. |
| `/request_quote` | `RequestQuoteScreen` | Client only | Request quote (competitive). |

### All Screen Files (30 screens)

| Screen File | Purpose |
|-------------|---------|
| `about_screen.dart` | About / info page |
| `add_service_screen.dart` | Add service request form |
| `additional_services_screen.dart` | Browse additional services |
| `chat_detail_screen.dart` | Individual chat thread |
| `client_order_details_screen.dart` | Client's order detail view |
| `client_orders_screen.dart` | Client's orders list |
| `contact_screen.dart` | Contact page |
| `home_screen.dart` | Main home with banners/categories |
| `interactive_screen.dart` | Social feed (portfolio, spotlights) |
| `login_screen.dart` | OTP phone login |
| `login_settings_screen.dart` | Login/auth settings |
| `my_chats_screen.dart` | Chat threads list |
| `my_profile_screen.dart` | My profile + settings |
| `notification_settings_screen.dart` | Notification preferences |
| `notifications_screen.dart` | Notifications list |
| `onboarding_screen.dart` | Onboarding / first launch |
| `orders_hub_screen.dart` | Combined orders hub |
| `plans_screen.dart` | Subscription plans |
| `provider_profile_screen.dart` | Public provider profile |
| `providers_map_screen.dart` | Map view of providers |
| `request_quote_screen.dart` | Create competitive request |
| `search_provider_screen.dart` | Search providers |
| `search_screen.dart` | General search |
| `service_detail_screen.dart` | Service detail view |
| `service_request_form_screen.dart` | Full service request form |
| `signup_screen.dart` | Registration completion |
| `terms_screen.dart` | Terms & conditions |
| `twofa_screen.dart` | 2FA / OTP verification |
| `urgent_request_screen.dart` | Create urgent request |
| `verification_screen.dart` | Verification request |

### Flutter Services (API Clients)

| Service File | Maps To Backend Module |
|-------------|----------------------|
| `auth_service.dart` / `auth_api_service.dart` | `/api/accounts/` |
| `profile_service.dart` | `/api/accounts/me/`, `/api/providers/me/` |
| `marketplace_service.dart` | `/api/marketplace/` |
| `messaging_service.dart` | `/api/messaging/` |
| `notification_service.dart` | `/api/notifications/` |
| `reviews_service.dart` | `/api/reviews/` |
| `support_service.dart` | `/api/support/` |
| `subscriptions_service.dart` | `/api/subscriptions/` |
| `promo_service.dart` | `/api/promo/` |
| `verification_service.dart` | `/api/verification/` |
| `billing_service.dart` | `/api/billing/` |
| `content_service.dart` | `/api/content/` |
| `features_service.dart` | `/api/features/` |
| `extras_service.dart` | `/api/extras/` |
| `home_service.dart` | Various (banners, categories) |
| `interactive_service.dart` | `/api/providers/` (portfolio, spotlights) |
| `provider_services_service.dart` | `/api/providers/me/services/` |

---

## 19. Auth Summary Matrix

### Public Endpoints (No Auth Required — `AllowAny`)

| Endpoint | Module |
|----------|--------|
| `POST /api/accounts/otp/send/` | Accounts |
| `POST /api/accounts/otp/verify/` | Accounts |
| `GET /api/accounts/username-availability/` | Accounts |
| `POST /api/accounts/token/` | Accounts |
| `POST /api/accounts/token/refresh/` | Accounts |
| `GET /api/providers/categories/` | Providers |
| `GET /api/providers/list/` | Providers |
| `GET /api/providers/<id>/` | Providers |
| `GET /api/providers/<id>/portfolio/` | Providers |
| `GET /api/providers/<id>/spotlights/` | Providers |
| `GET /api/providers/<id>/subcategories/` | Providers |
| `GET /api/providers/<id>/services/` | Providers |
| `GET /api/providers/<id>/followers/` | Providers |
| `GET /api/providers/<id>/following/` | Providers |
| `GET /api/providers/<id>/stats/` | Providers |
| `GET /api/reviews/providers/<id>/reviews/` | Reviews |
| `GET /api/reviews/providers/<id>/rating/` | Reviews |
| `GET /api/promo/banners/home/` | Promo |
| `GET /api/promo/active/` | Promo |
| `GET /api/content/public/` | Content |
| `POST /api/billing/webhooks/<provider>/` | Billing |
| `GET /healthz/`, `/health/`, `/health/live/`, `/health/ready/` | Health |

### Authenticated — Phone-Only Level (`IsAtLeastPhoneOnly`)

All social actions (follow/unfollow/like/unlike/save/unsave), messaging, notifications, wallet.

### Authenticated — Client Level (`IsAtLeastClient`)

Marketplace create/cancel/reopen, reviews create, support, billing, device token, registration completion, provider registration.

### Authenticated — Provider Level (`IsAtLeastProvider`)

Provider profile management, services CRUD, portfolio/spotlight management, request accept/reject/start/complete, offers, review replies.

### Backoffice Only

| Module | Permission |
|--------|-----------|
| Analytics | `IsBackofficeAnalytics` |
| Backoffice dashboards | `BackofficeAccessPermission` |
| Support (backoffice) | `IsRequesterOrBackofficeSupport` |
| Promo (backoffice) | `IsOwnerOrBackofficePromo` |
| Verification (backoffice) | `IsOwnerOrBackofficeVerify` |

---

**Total API Endpoints: ~120+**
**Total Flutter Screens: 30**
**Total Flutter Services: 17**
