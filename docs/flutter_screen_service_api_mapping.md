# Nawafeth Flutter — Screen → Service → API Endpoint → Fields Mapping

> **Auto-generated research document.** Read-only reference for the mobile Flutter app at `mobile/lib/`.

---

## Table of Contents

1. [Infrastructure](#1-infrastructure)
2. [Service Files Summary](#2-service-files-summary)
3. [Screen → Service → API Mapping](#3-screen--service--api-mapping)
4. [Registration Steps (Sub-Screens)](#4-registration-steps-sub-screens)
5. [Provider Dashboard Screens](#5-provider-dashboard-screens)
6. [Utility / Orchestration Services](#6-utility--orchestration-services)

---

## 1. Infrastructure

| Item | Detail |
|---|---|
| **Base URL** | `https://nawafeth-backend.onrender.com` (env `API_BASE_URL`) |
| **API Prefix** | `/api` |
| **HTTP Client** | Dio singleton (`core/network/api_dio.dart`) |
| **Auth** | JWT Bearer — access + refresh in `FlutterSecureStorage` |
| **Token Refresh** | `POST /api/accounts/token/refresh/` → `{refresh}` → `{access, refresh}` |
| **WebSocket** | `ws(s)://host/ws/thread/{threadId}/?token={accessToken}` |
| **Push** | Firebase Cloud Messaging — device token registered via `POST /api/notifications/device-token/` |

---

## 2. Service Files Summary

### 2.1 `auth_api.dart` — AuthApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `sendOtp(phone)` | POST | `/api/accounts/otp/send/` | `{phone}` | `{dev_code?}` |
| `otpVerify(phone, code)` | POST | `/api/accounts/otp/verify/` | `{phone, code}` | `{ok, is_new_user, needs_completion, access, refresh}` |
| `completeRegistration(...)` | POST | `/api/accounts/complete/` | `{first_name, last_name, username, email, password, password_confirm, accept_terms, city?}` + Bearer | — |

### 2.2 `account_api.dart` — AccountApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `me()` | GET | `/api/accounts/me/` | — | `{id, username, email, first_name, last_name, phone, has_provider_profile, provider_profile_id, role_state, is_provider, following_count, favorites_media_count, provider_followers_count, provider_likes_received_count, ...}` |
| `deleteMe()` | DELETE | `/api/accounts/me/` | — | — |
| `updateMe(patch)` | PATCH (fallback PUT) | `/api/accounts/me/` | patch map | updated profile map |

### 2.3 `billing_api.dart` — BillingApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `createInvoice(payload)` | POST | `/api/billing/invoices/` | payload map | invoice map |
| `getMyInvoices()` | GET | `/api/billing/invoices/my/` | — | list of invoices |
| `getInvoiceDetail(id)` | GET | `/api/billing/invoices/{id}/` | — | invoice detail |
| `initPayment(invoiceId, provider, idempotencyKey?)` | POST | `/api/billing/invoices/{id}/init-payment/` | `{provider, idempotency_key?}` | `{checkout_url, ...}` |

### 2.4 `extras_api.dart` — ExtrasApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getCatalog()` | GET | `/api/extras/catalog/` | — | list of extras |
| `getMyExtras()` | GET | `/api/extras/my/` | — | list of purchased extras |
| `buy(sku)` | POST | `/api/extras/buy/{sku}/` | — | `{invoice?, unified_request_code?}` |

### 2.5 `features_api.dart` — FeaturesApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getMyFeatures()` | GET | `/api/features/my/` | — | features map |

### 2.6 `marketplace_api.dart` — MarketplaceApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `createRequest(...)` | POST | `/api/marketplace/requests/create/` | FormData: `{provider?, subcategory, title, description, request_type, city, dispatch_mode?, images[], videos[], files[], audio}` | bool success |
| `getMyRequests(statusGroup?, type?)` | GET | `/api/marketplace/client/requests/` | query params | list of request maps |
| `getMyProviderRequests(statusGroup?, clientUserId?)` | GET | `/api/marketplace/provider/requests/` | query params | list of request maps |
| `getAvailableUrgentRequestsForProvider()` | GET | `/api/marketplace/provider/urgent/available/` | — | list |
| `getAvailableCompetitiveRequestsForProvider()` | GET | `/api/marketplace/provider/competitive/available/` | — | list |
| `acceptUrgentRequest(requestId)` | POST | `/api/marketplace/requests/urgent/accept/` | `{request_id}` | bool |
| `acceptAssignedRequestDetailed(requestId)` | POST | `/api/marketplace/provider/requests/{id}/accept/` | `{}` | response map |
| `rejectAssignedRequest(requestId, ...)` | POST | `/api/marketplace/provider/requests/{id}/reject/` | `{note?, canceled_at?, cancel_reason?}` | bool |
| `getMyRequestDetail(requestId)` | GET | `/api/marketplace/client/requests/{id}/` | — | request detail map |
| `updateMyRequestDetail(requestId, patch)` | PATCH | `/api/marketplace/client/requests/{id}/` | `{title?, description?}` | updated map |
| `cancelMyRequest(requestId, note?)` | POST | `/api/marketplace/requests/{id}/cancel/` | `{note?}` | bool |
| `reopenMyRequest(requestId, note?)` | POST | `/api/marketplace/requests/{id}/reopen/` | `{note?}` | bool |
| `sendRequestReminder(requestId, body)` | POST | `/api/messaging/requests/{id}/messages/send/` | `{body}` | bool |
| `startAssignedRequest(requestId, ...)` | POST | `/api/marketplace/requests/{id}/start/` | `{note?, expected_delivery_at?, estimated_service_amount?, received_amount?}` | bool |
| `completeAssignedRequest(requestId, ...)` | POST | `/api/marketplace/requests/{id}/complete/` | `{note?, delivered_at?, actual_service_amount?}` | bool |
| `updateProviderProgress(requestId, ...)` | POST | `/api/marketplace/provider/requests/{id}/progress-update/` | `{note?, expected_delivery_at?, estimated_service_amount?, received_amount?}` | bool |
| `createOffer(requestId, price, durationDays, note?)` | POST | `/api/marketplace/requests/{id}/offers/create/` | `{price, duration_days, note?}` | bool |
| `getProviderRequestDetail(requestId)` | GET | `/api/marketplace/provider/requests/{id}/detail/` | — | detail map |
| `getRequestOffers(requestId)` | GET | `/api/marketplace/requests/{id}/offers/` | — | list of Offer |
| `acceptOffer(offerId)` | POST | `/api/marketplace/offers/{id}/accept/` | `{}` | bool |
| `submitProviderInputsDecision(requestId, approved, note?)` | POST | `/api/marketplace/requests/{id}/provider-inputs/decision/` | `{approved, note?}` | bool |

### 2.7 `messaging_api.dart` — MessagingApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getOrCreateThread(requestId)` | GET | `/api/messaging/requests/{id}/thread/` | — | thread map |
| `getThreadMessages(requestId)` | GET | `/api/messaging/requests/{id}/messages/` | — | list of messages |
| `sendMessage(requestId, body, attachment?)` | POST | `/api/messaging/requests/{id}/messages/send/` | `{body}` or FormData with file | message map |
| `markRead(requestId)` | POST | `/api/messaging/requests/{id}/messages/read/` | — | — |
| `getMyThreadStates()` | GET | `/api/messaging/threads/states/` | — | list of thread-state maps |
| `getThreadState(threadId)` | GET | `/api/messaging/thread/{id}/state/` | — | `{is_favorite, favorite_label, client_label, is_blocked, blocked_by_other}` |
| `toggleFavorite(threadId, remove?)` | POST | `/api/messaging/thread/{id}/favorite/` | `{action?:'remove'}` | — |
| `toggleArchive(threadId, remove?)` | POST | `/api/messaging/thread/{id}/archive/` | `{action?:'remove'}` | — |
| `toggleBlock(threadId, remove?)` | POST | `/api/messaging/thread/{id}/block/` | `{action?:'remove'}` | — |
| `reportThread(threadId, ...)` | POST | `/api/messaging/thread/{id}/report/` | `{reason?, details?, description?, reported_label?}` | — |
| `markUnread(threadId)` | POST | `/api/messaging/thread/{id}/unread/` | — | — |
| `deleteMessage(threadId, msgId)` | POST | `/api/messaging/thread/{id}/messages/{msgId}/delete/` | — | — |
| `setFavoriteLabel(threadId, label)` | POST | `/api/messaging/thread/{id}/favorite-label/` | `{label}` | — |
| `setClientLabel(threadId, label)` | POST | `/api/messaging/thread/{id}/client-label/` | `{label}` | — |
| `getOrCreateDirectThread(providerId)` | POST | `/api/messaging/direct/thread/` | `{provider_id}` | thread map |
| `getDirectMessages(threadId)` | GET | `/api/messaging/direct/thread/{id}/messages/` | — | list |
| `sendDirectMessage(threadId, body, attachment?)` | POST | `/api/messaging/direct/thread/{id}/messages/send/` | `{body}` or FormData | message map |
| `markDirectRead(threadId)` | POST | `/api/messaging/direct/thread/{id}/messages/read/` | — | — |
| `getMyDirectThreads()` | GET | `/api/messaging/direct/threads/` | — | list of direct threads |
| **WebSocket** | WS | `ws(s)://host/ws/thread/{threadId}/?token={token}` | JSON frames | real-time messages |

### 2.8 `notifications_api.dart` — NotificationsApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getUnreadCount()` | GET | `/api/notifications/unread-count/` | — | `{unread: int}` |
| `list(limit, offset)` | GET | `/api/notifications/` | query `{limit, offset}` | `{results: [...]}` |
| `markRead(id)` | POST | `/api/notifications/mark-read/{id}/` | — | — |
| `markAllRead()` | POST | `/api/notifications/mark-all-read/` | — | — |
| `togglePin(id)` / `toggleFollowUp(id)` | POST | `/api/notifications/actions/{id}/` | `{action: 'pin'\|'follow_up'}` | — |
| `removeAction(id)` | DELETE | `/api/notifications/actions/{id}/` | — | — |
| `getPreferences()` | GET | `/api/notifications/preferences/` | — | `{results: [...]}` |
| `updatePreferences(updates)` | PATCH | `/api/notifications/preferences/` | `{updates: [{key, enabled}]}` | — |
| `registerDeviceToken(token, platform)` | POST | `/api/notifications/device-token/` | `{token, platform}` | — |

### 2.9 `promo_api.dart` — PromoApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `createRequest(payload)` | POST | `/api/promo/requests/create/` | payload map | promo request map |
| `getMyRequests()` | GET | `/api/promo/requests/my/` | — | list |
| `getRequestDetail(id)` | GET | `/api/promo/requests/{id}/` | — | detail |
| `uploadAsset(requestId, assetType, title?, file)` | POST | `/api/promo/requests/{id}/assets/` | FormData `{asset_type, title?, file}` | — |
| `getHomeBanners(limit?)` | GET | `/api/promo/banners/home/` | query `{limit}` | list (shaped as ProviderPortfolioItem) |
| `getActivePlacements(adType?, city?, category?, limit?)` | GET | `/api/promo/active/` | query filters | list of active placements |

### 2.10 `providers_api.dart` — ProvidersApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getCategories()` | GET | `/api/providers/categories/` | — | list of Category |
| `getProviders(q?, city?, categoryId?, subcategoryId?, hasLocation?, acceptsUrgent?)` | GET | `/api/providers/list/` | query params | list of ProviderProfile |
| `getProviderDetail(id)` | GET | `/api/providers/{id}/` | — | ProviderProfile map |
| `getProviderServices(id)` | GET | `/api/providers/{id}/services/` | — | list of ProviderService |
| `getProviderSubcategories(id)` | GET | `/api/providers/{id}/subcategories/` | — | list |
| `getMyServices()` | GET | `/api/providers/me/services/` | — | list of ProviderService |
| `createMyService(...)` | POST | `/api/providers/me/services/` | `{title, subcategory_id, description?, price_from?, price_to?, price_unit, is_active}` | ProviderService |
| `updateMyService(id, patch)` | PATCH | `/api/providers/me/services/{id}/` | patch map | updated |
| `deleteMyService(id)` | DELETE | `/api/providers/me/services/{id}/` | — | bool |
| `getMyFollowingProviders()` | GET | `/api/providers/me/following/` | — | list |
| `getMyLikedProviders()` | GET | `/api/providers/me/likes/` | — | list |
| `getMyFollowers()` | GET | `/api/providers/me/followers/` | — | list of UserSummary |
| `getMyLikers()` | GET | `/api/providers/me/likers/` | — | list of UserSummary |
| `getProviderFollowers(id)` | GET | `/api/providers/{id}/followers/` | — | list |
| `getProviderFollowing(id)` | GET | `/api/providers/{id}/following/` | — | list |
| `getMyFavoriteMedia()` | GET | `/api/providers/me/favorites/` | — | list of ProviderPortfolioItem |
| `getProviderPortfolio(id)` | GET | `/api/providers/{id}/portfolio/` | — | list of ProviderPortfolioItem |
| `getMyPortfolio()` | GET | `/api/providers/me/portfolio/` | — | list of ProviderPortfolioItem |
| `createMyPortfolioItem(file, fileType, caption)` | POST | `/api/providers/me/portfolio/` | FormData `{file_type, caption, file}` | ProviderPortfolioItem |
| `deleteMyPortfolioItem(id)` | DELETE | `/api/providers/me/portfolio/{id}/` | — | bool |
| `likePortfolioItem(id)` | POST | `/api/providers/portfolio/{id}/like/` | — | — |
| `unlikePortfolioItem(id)` | POST | `/api/providers/portfolio/{id}/unlike/` | — | — |
| `likeProvider(id)` | POST | `/api/providers/{id}/like/` | — | — |
| `unlikeProvider(id)` | POST | `/api/providers/{id}/unlike/` | — | — |
| `followProvider(id)` | POST | `/api/providers/{id}/follow/` | — | — |
| `unfollowProvider(id)` | POST | `/api/providers/{id}/unfollow/` | — | — |
| `registerProvider(...)` | POST | `/api/providers/register/` | `{provider_type, display_name, bio, city, accepts_urgent, years_experience?, subcategory_ids?}` | — |
| `getMyProviderProfile()` | GET | `/api/providers/me/profile/` | — | provider profile map |
| `updateMyProviderProfile(patch)` | PATCH | `/api/providers/me/profile/` | patch map (or FormData for images) | updated map |
| `createMySpotlightItem(file, fileType)` | POST | `/api/providers/me/spotlights/` | FormData | ProviderPortfolioItem |
| `getMySpotlights()` | GET | `/api/providers/me/spotlights/` | — | list |
| `getProviderSpotlights(id)` | GET | `/api/providers/{id}/spotlights/` | — | list |
| `deleteMySpotlight(id)` | DELETE | `/api/providers/me/spotlights/{id}/` | — | bool |
| `getMyProviderSubcategories()` | GET | `/api/providers/me/subcategories/` | — | `{subcategory_ids: [...]}` |
| `setMyProviderSubcategories(ids)` | PUT | `/api/providers/me/subcategories/` | `{subcategory_ids: [...]}` | — |

### 2.11 `reviews_api.dart` — ReviewsApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getProviderRatingSummary(providerId)` | GET | `/api/reviews/providers/{id}/rating/` | — | `{rating_avg, rating_count, likes_count, response_speed, cost_value, quality, credibility, on_time}` |
| `getProviderReviews(providerId)` | GET | `/api/reviews/providers/{id}/reviews/` | — | list of `{id, client_name, client_phone, comment, rating, created_at, response_speed, cost_value, quality, credibility, on_time}` |
| `createReview(requestId, ...)` | POST | `/api/reviews/requests/{id}/review/` | `{response_speed, cost_value, quality, credibility, on_time, comment?, rating?}` | `{review_id}` |

### 2.12 `subscriptions_api.dart` — SubscriptionsApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getPlans()` | GET | `/api/subscriptions/plans/` | — | list of plans |
| `getMySubscriptions()` | GET | `/api/subscriptions/my/` | — | list |
| `subscribe(planId)` | POST | `/api/subscriptions/subscribe/{planId}/` | — | `{invoice?}` |

### 2.13 `support_api.dart` — SupportApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `getTeams()` | GET | `/api/support/teams/` | — | list of teams |
| `createTicket(...)` | POST | `/api/support/tickets/create/` | `{ticket_type, description, reported_kind?, reported_object_id?, reported_user?}` | ticket map |
| `getMyTickets(status?, type?)` | GET | `/api/support/tickets/my/` | query params | list |
| `getTicketDetail(id)` | GET | `/api/support/tickets/{id}/` | — | detail |
| `addComment(ticketId, text, isInternal)` | POST | `/api/support/tickets/{id}/comments/` | `{text, is_internal}` | — |
| `addAttachment(ticketId, file)` | POST | `/api/support/tickets/{id}/attachments/` | FormData with file | — |

### 2.14 `verification_api.dart` — VerificationApi

| Method | HTTP | Endpoint | Sends | Returns |
|---|---|---|---|---|
| `createRequest(badgeType)` | POST | `/api/verification/requests/create/` | `{badge_type}` | request map |
| `getMyRequests()` | GET | `/api/verification/requests/my/` | — | list |
| `getRequestDetail(id)` | GET | `/api/verification/requests/{id}/` | — | detail |
| `addDocument(requestId, docType, title?, file)` | POST | `/api/verification/requests/{id}/documents/` | FormData `{doc_type, title?, file}` | — |

---

## 3. Screen → Service → API Mapping

### 3.1 `entry_screen.dart` — EntryScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| AccountApi | `me()` | `GET /api/accounts/me/` |
| SessionStorage | `isLoggedIn()`, `readAccessToken()` | (local) |
| RoleSync | `sync()` | calls AccountApi.me() + ProvidersApi.getMyProviderProfile() |
| RoleController | `notifier` | (local state) |

**Fields read**: `id`, `username`, `has_provider_profile`, `role_state`, `is_provider`
**Navigates to**: HomeScreen (logged in) · LoginScreen (guest)

---

### 3.2 `onboarding_screen.dart` — OnboardingScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| *(none)* | — | — |

**Static onboarding slides.** Navigates to `/entry`.

---

### 3.3 `login_screen.dart` — LoginScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| AuthApi | `sendOtp(phone)` | `POST /api/accounts/otp/send/` |
| AccountApi | `me()` | `GET /api/accounts/me/` |
| SessionStorage | `saveTokens()`, `saveProfile()` | (local) |
| RoleSync | `sync()` | (AccountApi + ProvidersApi) |

**Fields sent**: `phone`
**Fields read from OTP**: `dev_code`
**Navigates to**: TwoFAScreen · SignUpScreen · HomeScreen

---

### 3.4 `twofa_screen.dart` — TwoFAScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| AuthApi | `otpVerify(phone, code)` | `POST /api/accounts/otp/verify/` |
| AccountApi | `me()` | `GET /api/accounts/me/` |
| SessionStorage | `saveTokens()`, `saveProfile()` | (local) |
| RoleSync | `sync()` | (composite) |

**Fields read**: `ok`, `is_new_user`, `needs_completion`, `access`, `refresh`
**Navigates to**: SignUpScreen (new user) · HomeScreen (existing)

---

### 3.5 `signup_screen.dart` — SignUpScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| AuthApi | `completeRegistration(...)` | `POST /api/accounts/complete/` |
| AccountApi | `me()` | `GET /api/accounts/me/` |
| SessionStorage | `saveProfile()` | (local) |
| RoleSync | `sync()` | (composite) |

**Fields sent**: `first_name`, `last_name`, `username`, `email`, `password`, `password_confirm`, `accept_terms`, `city`
**Navigates to**: HomeScreen · LoginScreen

---

### 3.6 `home_screen.dart` — HomeScreen

| Service | Method Called | API Endpoint(s) |
|---|---|---|
| HomeFeedService | `getTopProviders()` | `GET /api/providers/list/` |
| HomeFeedService | `getBannerItems()` | `GET /api/promo/banners/home/` |
| HomeFeedService | `getMediaItems()` | `GET /api/providers/me/favorites/` (if logged in) + promo |
| HomeFeedService | `getTestimonials()` | `GET /api/reviews/providers/{id}/reviews/` (for top providers) |

**Fields displayed**: provider `display_name`, `profile_image`, `rating_avg`, banner images/videos, portfolio items
**Navigates to**: ProviderProfileScreen · SearchProviderScreen · various via drawer/bottom-nav

---

### 3.7 `search_screen.dart` — SearchScreen

Renders `RequestQuoteScreen` directly. No additional API calls.

---

### 3.8 `search_provider_screen.dart` — SearchProviderScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getCategories()` | `GET /api/providers/categories/` |
| ProvidersApi | `getProviders(...)` | `GET /api/providers/list/` |
| HomeFeedService | `reorderProvidersForPromos()` | (local reordering) |

**Fields displayed**: provider `display_name`, `profile_image`, `city`, `bio`, `rating_avg`, category/subcategory names
**Navigates to**: ProviderProfileScreen

---

### 3.9 `request_quote_screen.dart` — RequestQuoteScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getCategories()` | `GET /api/providers/categories/` |
| MarketplaceApi | `createRequest(...)` | `POST /api/marketplace/requests/create/` |

**Fields sent**: `subcategory`, `title`, `description`, `request_type='competitive'`, `city`
**Navigates to**: `/orders`

---

### 3.10 `service_request_form_screen.dart` — ServiceRequestFormScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getCategories()` | `GET /api/providers/categories/` |
| MarketplaceApi | `createRequest(...)` | `POST /api/marketplace/requests/create/` |

**Fields sent**: `provider` (optional), `subcategory`, `title`, `description`, `request_type`, `city`, `dispatch_mode`, `images[]`, `videos[]`, `files[]`, `audio`
**Navigates to**: `/orders`

---

### 3.11 `urgent_request_screen.dart` — UrgentRequestScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getCategories()` | `GET /api/providers/categories/` |
| MarketplaceApi | `createRequest(...)` | `POST /api/marketplace/requests/create/` |

**Fields sent**: `subcategory`, `title`, `description`, `request_type='urgent'`, `city`, `dispatch_mode`
**Navigates to**: UrgentProvidersMapScreen

---

### 3.12 `provider_profile_screen.dart` — ProviderProfileScreen (2561 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getProviderDetail(id)` | `GET /api/providers/{id}/` |
| ProvidersApi | `getProviderServices(id)` | `GET /api/providers/{id}/services/` |
| ProvidersApi | `getProviderSubcategories(id)` | `GET /api/providers/{id}/subcategories/` |
| ProvidersApi | `getProviderPortfolio(id)` | `GET /api/providers/{id}/portfolio/` |
| ProvidersApi | `getProviderSpotlights(id)` | `GET /api/providers/{id}/spotlights/` |
| ProvidersApi | `followProvider(id)` / `unfollowProvider(id)` | `POST /api/providers/{id}/follow\|unfollow/` |
| ProvidersApi | `likeProvider(id)` / `unlikeProvider(id)` | `POST /api/providers/{id}/like\|unlike/` |
| ProvidersApi | `likePortfolioItem(id)` / `unlikePortfolioItem(id)` | `POST /api/providers/portfolio/{id}/like\|unlike/` |
| ProvidersApi | `getMyFollowingProviders()` | `GET /api/providers/me/following/` |
| ProvidersApi | `getMyLikedProviders()` | `GET /api/providers/me/likes/` |
| ProvidersApi | `getMyFavoriteMedia()` | `GET /api/providers/me/favorites/` |
| AccountApi | `me()` | `GET /api/accounts/me/` |
| MessagingApi | `getOrCreateDirectThread(providerId)` | `POST /api/messaging/direct/thread/` |
| ReviewsApi | `getProviderRatingSummary(id)` | `GET /api/reviews/providers/{id}/rating/` |
| ReviewsApi | `getProviderReviews(id)` | `GET /api/reviews/providers/{id}/reviews/` |
| SupportApi | `createTicket(...)` | `POST /api/support/tickets/create/` |

**Fields displayed**: `display_name`, `bio`, `profile_image`, `cover_image`, `city`, `provider_type`, `years_experience`, `rating_avg`, `rating_count`, `followers_count`, `likes_count`, services list, portfolio gallery, spotlights, reviews
**Navigates to**: ServiceRequestFormScreen · ChatDetailScreen · ProviderPortfolioManageScreen

---

### 3.13 `my_profile_screen.dart` — MyProfileScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| AccountApi | `me()` | `GET /api/accounts/me/` |
| ProvidersApi | `getMyProviderProfile()` | `GET /api/providers/me/profile/` |
| ProvidersApi | `getMyFavoriteMedia()` | `GET /api/providers/me/favorites/` |
| SessionStorage | read all fields | (local) |
| RoleController | `notifier`, `setProviderMode()` | (local) |
| AccountSwitcher | `switchToClient()`, `switchToProvider()` | (local + AccountApi.me) |

**Fields displayed**: `first_name`, `last_name`, `username`, `email`, `phone`, `profile_image`, `has_provider_profile`, favorites
**Navigates to**: ProviderHomeScreen · RegisterServiceProvider · LoginSettingsScreen · NotificationSettingsScreen · TermsScreen · InteractiveScreen

---

### 3.14 `notifications_screen.dart` — NotificationsScreen (705 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| NotificationsApi | `list(limit, offset)` | `GET /api/notifications/` |
| NotificationsApi | `markRead(id)` | `POST /api/notifications/mark-read/{id}/` |
| NotificationsApi | `markAllRead()` | `POST /api/notifications/mark-all-read/` |
| NotificationsApi | `togglePin(id)` / `toggleFollowUp(id)` | `POST /api/notifications/actions/{id}/` |
| NotificationsApi | `removeAction(id)` | `DELETE /api/notifications/actions/{id}/` |
| NotificationsBadgeController | `refresh()` | `GET /api/notifications/unread-count/` |

**Fields displayed**: notification `title`, `body`, `created_at`, `is_read`, `is_pinned`, `is_follow_up`, `notification_type`
**Navigates to**: NotificationDetailsScreen · NotificationSettingsScreen

---

### 3.15 `notification_details_screen.dart` — NotificationDetailsScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| MarketplaceApi | `getMyRequestDetail(id)` | `GET /api/marketplace/client/requests/{id}/` |
| MarketplaceApi | `getProviderRequestDetail(id)` | `GET /api/marketplace/provider/requests/{id}/detail/` |
| NotificationLinkHandler | `openRequestDetails()` | (navigation) |

**Fields displayed**: request `title`, `description`, `status`, `created_at`
**Navigates to**: ClientOrderDetailsScreen or ProviderOrderDetailsScreen

---

### 3.16 `notification_settings_screen.dart` — NotificationSettingsScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| NotificationsApi | `getPreferences()` | `GET /api/notifications/preferences/` |
| NotificationsApi | `updatePreferences(updates)` | `PATCH /api/notifications/preferences/` |

**Fields displayed/toggled**: list of `{key, label, enabled}` preference items

---

### 3.17 `my_chats_screen.dart` — MyChatsScreen (906 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| MessagingApi | `getOrCreateThread(requestId)` | `GET /api/messaging/requests/{id}/thread/` |
| MessagingApi | `getThreadMessages(requestId)` | `GET /api/messaging/requests/{id}/messages/` |
| MessagingApi | `getMyThreadStates()` | `GET /api/messaging/threads/states/` |
| MessagingApi | `getMyDirectThreads()` | `GET /api/messaging/direct/threads/` |
| MessagingApi | WebSocket | `ws(s)://host/ws/thread/{threadId}/?token=...` |
| MarketplaceApi | `getMyRequests()` | `GET /api/marketplace/client/requests/` |
| MarketplaceApi | `getMyProviderRequests()` | `GET /api/marketplace/provider/requests/` |
| RoleController | `notifier` | (local) |

**Fields displayed**: thread `last_message`, `unread_count`, `updated_at`, participant names
**Navigates to**: ChatDetailScreen

---

### 3.18 `chat_detail_screen.dart` — ChatDetailScreen (2401 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| MessagingApi | `getThreadMessages(requestId)` / `getDirectMessages(threadId)` | `GET /api/messaging/requests/{id}/messages/` or `GET /api/messaging/direct/thread/{id}/messages/` |
| MessagingApi | `sendMessage(...)` / `sendDirectMessage(...)` | `POST .../messages/send/` |
| MessagingApi | `markRead(...)` / `markDirectRead(...)` | `POST .../messages/read/` |
| MessagingApi | `getThreadState(threadId)` | `GET /api/messaging/thread/{id}/state/` |
| MessagingApi | `toggleFavorite(threadId)` | `POST /api/messaging/thread/{id}/favorite/` |
| MessagingApi | `toggleBlock(threadId)` | `POST /api/messaging/thread/{id}/block/` |
| MessagingApi | `toggleArchive(threadId)` | `POST /api/messaging/thread/{id}/archive/` |
| MessagingApi | `reportThread(threadId)` | `POST /api/messaging/thread/{id}/report/` |
| MessagingApi | `markUnread(threadId)` | `POST /api/messaging/thread/{id}/unread/` |
| MessagingApi | `deleteMessage(threadId, msgId)` | `POST /api/messaging/thread/{id}/messages/{msgId}/delete/` |
| MessagingApi | `setFavoriteLabel(threadId, label)` | `POST /api/messaging/thread/{id}/favorite-label/` |
| MessagingApi | `setClientLabel(threadId, label)` | `POST /api/messaging/thread/{id}/client-label/` |
| MessagingApi | WebSocket | `ws(s)://host/ws/thread/{threadId}/?token=...` |
| MarketplaceApi | `getMyRequestDetail(id)` | `GET /api/marketplace/client/requests/{id}/` |
| MarketplaceApi | `getProviderRequestDetail(id)` | `GET /api/marketplace/provider/requests/{id}/detail/` |

**Fields displayed**: messages `body`, `attachment`, `created_at`, `sender_id`, thread state
**Navigates to**: ServiceRequestFormScreen · ProviderOrderDetailsScreen

---

### 3.19 `client_orders_screen.dart` — ClientOrdersScreen (921 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| MarketplaceApi | `getMyRequests(statusGroup?, type?)` | `GET /api/marketplace/client/requests/` |

**Fields displayed**: `title`, `subcategory_name`, `status_label`, `created_at`, `request_type`, `city`, `provider_name`
**Navigates to**: ClientOrderDetailsScreen

---

### 3.20 `client_order_details_screen.dart` — ClientOrderDetailsScreen (1656 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| MarketplaceApi | `getMyRequestDetail(id)` | `GET /api/marketplace/client/requests/{id}/` |
| MarketplaceApi | `getRequestOffers(id)` | `GET /api/marketplace/requests/{id}/offers/` |
| MarketplaceApi | `acceptOffer(offerId)` | `POST /api/marketplace/offers/{id}/accept/` |
| MarketplaceApi | `cancelMyRequest(id, note?)` | `POST /api/marketplace/requests/{id}/cancel/` |
| MarketplaceApi | `reopenMyRequest(id, note?)` | `POST /api/marketplace/requests/{id}/reopen/` |
| MarketplaceApi | `sendRequestReminder(id, body)` | `POST /api/messaging/requests/{id}/messages/send/` |
| MarketplaceApi | `updateMyRequestDetail(id, patch)` | `PATCH /api/marketplace/client/requests/{id}/` |
| MarketplaceApi | `submitProviderInputsDecision(id, approved, note?)` | `POST /api/marketplace/requests/{id}/provider-inputs/decision/` |
| ReviewsApi | `createReview(requestId, ...)` | `POST /api/reviews/requests/{id}/review/` |
| ChatNav | `openThread(...)` | (navigation) |

**Fields displayed**: `title`, `description`, `status`, `status_label`, `created_at`, `provider_name`, `city`, `subcategory_name`, `request_type`, offers list (`price`, `duration_days`, `note`), `expected_delivery_at`, `estimated_service_amount`, `received_amount`, `actual_service_amount`, `delivered_at`, attachments, status_logs
**Navigates to**: chat thread

---

### 3.21 `orders_hub_screen.dart` — OrdersHubScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| RoleController | `notifier` | (local) |

**Delegates to**: `ProviderOrdersScreen` (if provider) or `ClientOrdersScreen` (if client). No direct API calls.

---

### 3.22 `plans_screen.dart` — PlansScreen

| Service | Method Called | API Endpoint |
|---|---|---|
| SubscriptionsApi | `getPlans()` | `GET /api/subscriptions/plans/` |
| SubscriptionsApi | `subscribe(planId)` | `POST /api/subscriptions/subscribe/{planId}/` |
| BillingApi | `initPayment(invoiceId, ...)` | `POST /api/billing/invoices/{id}/init-payment/` |
| PaymentCheckout | `checkout(invoiceId)` | (calls BillingApi.initPayment + url_launcher) |

**Fields displayed**: plan `name`, `description`, `price`, `duration_days`, `features`
**Navigates to**: external payment URL

---

### 3.23 `contact_screen.dart` — ContactScreen (1332 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| SupportApi | `getTeams()` | `GET /api/support/teams/` |
| SupportApi | `createTicket(...)` | `POST /api/support/tickets/create/` |
| SupportApi | `getMyTickets(status?, type?)` | `GET /api/support/tickets/my/` |
| SupportApi | `getTicketDetail(id)` | `GET /api/support/tickets/{id}/` |
| SupportApi | `addComment(id, text, isInternal)` | `POST /api/support/tickets/{id}/comments/` |
| SupportApi | `addAttachment(id, file)` | `POST /api/support/tickets/{id}/attachments/` |

**Fields displayed**: ticket `type`, `description`, `status`, `created_at`, comments list, attachments
**Navigates to**: (in-screen tabs)

---

### 3.24 `verification_screen.dart` — VerificationScreen (1550 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| VerificationApi | `createRequest(badgeType)` | `POST /api/verification/requests/create/` |
| VerificationApi | `getMyRequests()` | `GET /api/verification/requests/my/` |
| VerificationApi | `getRequestDetail(id)` | `GET /api/verification/requests/{id}/` |
| VerificationApi | `addDocument(id, docType, title?, file)` | `POST /api/verification/requests/{id}/documents/` |
| BillingApi | `initPayment(...)` | `POST /api/billing/invoices/{id}/init-payment/` |
| PaymentCheckout | `checkout(invoiceId)` | (BillingApi + url_launcher) |

**Fields displayed**: badge type, request `status`, document list, invoice status

---

### 3.25 `additional_services_screen.dart` — AdditionalServicesScreen (546 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| ExtrasApi | `getCatalog()` | `GET /api/extras/catalog/` |
| ExtrasApi | `getMyExtras()` | `GET /api/extras/my/` |
| ExtrasApi | `buy(sku)` | `POST /api/extras/buy/{sku}/` |
| PromoApi | `getMyRequests()` | `GET /api/promo/requests/my/` |
| PromoApi | `createRequest(payload)` | `POST /api/promo/requests/create/` |
| BillingApi | `initPayment(...)` | `POST /api/billing/invoices/{id}/init-payment/` |
| PaymentCheckout | `checkout(invoiceId)` | (BillingApi + url_launcher) |

**3 tabs**: Catalog, My Extras, Promo Requests
**Fields displayed**: extra `sku`, `name`, `description`, `price`, promo `status`, `ad_type`

---

### 3.26 `about_screen.dart` — AboutScreen

No API calls. Static informational page.

---

### 3.27 `service_detail_screen.dart` — ServiceDetailScreen (631 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| ReviewsApi | `getProviderRatingSummary(providerId)` | `GET /api/reviews/providers/{id}/rating/` |
| ReviewsApi | `getProviderReviews(providerId)` | `GET /api/reviews/providers/{id}/reviews/` |
| ProvidersApi | `getMyLikedProviders()` | `GET /api/providers/me/likes/` |
| ProvidersApi | `likeProvider(id)` / `unlikeProvider(id)` | `POST /api/providers/{id}/like\|unlike/` |
| SupportApi | `createTicket(...)` | `POST /api/support/tickets/create/` |

**Fields displayed**: service `title`, `images`, `provider_name`, `likes_count`, reviews list
**Navigates to**: ServiceRequestFormScreen

---

### 3.28 `providers_map_screen.dart` — ProvidersMapScreen (1332 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getProviders(...)` | `GET /api/providers/list/` |
| MessagingApi | `getOrCreateDirectThread(providerId)` | `POST /api/messaging/direct/thread/` |

**Fields displayed**: provider markers on map, `name`, `phone`, `is_available`, `profile_image`, `rating`
**Navigates to**: ProviderProfileScreen · ChatDetailScreen · ServiceRequestFormScreen

---

## 4. Registration Steps (Sub-Screens)

### 4.1 `register_service_provider.dart` — RegisterServiceProviderPage (886 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| AccountApi | `me()` | `GET /api/accounts/me/` |
| AccountApi | `updateMe({phone})` | `PATCH /api/accounts/me/` |
| ProvidersApi | `registerProvider(...)` | `POST /api/providers/register/` |
| ProvidersApi | `updateMyProviderProfile({whatsapp})` | `PATCH /api/providers/me/profile/` |
| RoleController | `setProviderMode(true)` | (local) |

**3-step wizard**: PersonalInfoStep → ServiceClassificationStep → ContactInfoStep
**Fields sent**: `provider_type`, `display_name`, `bio`, `city`, `accepts_urgent`, `subcategory_ids`, `phone`, `whatsapp`

### 4.2 Registration Steps (in `registration/steps/`)

| Step File | Services Used | API Endpoints |
|---|---|---|
| `personal_info_step.dart` | *(none)* | (UI only — data passed via controllers) |
| `service_classification_step.dart` | ProvidersApi | `GET /api/providers/categories/` |
| `contact_info_step.dart` | AccountApi, ProvidersApi | `GET /api/accounts/me/`, `GET /api/providers/me/profile/`, `PATCH /api/providers/me/profile/` |
| `additional_details_step.dart` | ProvidersApi | `GET /api/providers/me/profile/`, `PATCH /api/providers/me/profile/` |
| `language_location_step.dart` | ProvidersApi | `GET /api/providers/me/profile/`, `PATCH /api/providers/me/profile/` |
| `seo_step.dart` | ProvidersApi | `GET /api/providers/me/profile/`, `PATCH /api/providers/me/profile/` |
| `content_step.dart` | ProvidersApi | `GET /api/providers/me/profile/`, `PATCH /api/providers/me/profile/` |

---

## 5. Provider Dashboard Screens

### 5.1 `provider_home_screen.dart` — ProviderHomeScreen (1607 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| AccountApi | `me()` | `GET /api/accounts/me/` |
| ProvidersApi | `getMyProviderProfile()` | `GET /api/providers/me/profile/` |
| ProvidersApi | `getMyProviderSubcategories()` | `GET /api/providers/me/subcategories/` |
| ProvidersApi | `getMySpotlights()` | `GET /api/providers/me/spotlights/` |
| ProvidersApi | `createMySpotlightItem(...)` | `POST /api/providers/me/spotlights/` |
| ProvidersApi | `deleteMySpotlight(id)` | `DELETE /api/providers/me/spotlights/{id}/` |
| ReviewsApi | `getProviderRatingSummary(id)` | `GET /api/reviews/providers/{id}/rating/` |
| MarketplaceApi | `getMyProviderRequests(statusGroup:'completed')` | `GET /api/marketplace/provider/requests/` |
| AccountSwitcher | `switchToClient()` | (local) |

**Fields displayed**: `display_name`, `username`, `profile_image`, `cover_image`, `bio`, `about_details`, `followers_count`, `likes_received_count`, `rating_avg`, `rating_count`, `profile_completion`, spotlights, completed orders count
**Tabs**: ServicesTab, ReviewsTab
**Navigates to**: ProviderProfileCompletionScreen · ProviderOrdersScreen · ProviderPortfolioManageScreen · PlansScreen · AdditionalServicesScreen

---

### 5.2 `provider_orders_screen.dart` — ProviderOrdersScreen (1016 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| MarketplaceApi | `getMyProviderRequests(statusGroup)` | `GET /api/marketplace/provider/requests/` |
| MarketplaceApi | `getAvailableUrgentRequestsForProvider()` | `GET /api/marketplace/provider/urgent/available/` |
| MarketplaceApi | `getAvailableCompetitiveRequestsForProvider()` | `GET /api/marketplace/provider/competitive/available/` |

**3 tabs**: Assigned (by status), Urgent Available, Competitive Available
**Fields displayed**: `id`, `title`, `subcategory_name`, `status`, `status_label`, `client_name`, `city`, `created_at`, `request_type`, attachments
**Navigates to**: ProviderOrderDetailsScreen

---

### 5.3 `provider_order_details_screen.dart` — ProviderOrderDetailsScreen (1517 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| MarketplaceApi | `getProviderRequestDetail(requestId)` | `GET /api/marketplace/provider/requests/{id}/detail/` |
| MarketplaceApi | `updateProviderProgress(requestId, ...)` | `POST /api/marketplace/provider/requests/{id}/progress-update/` |
| MarketplaceApi | `acceptAssignedRequestDetailed(requestId)` | `POST /api/marketplace/provider/requests/{id}/accept/` |
| MarketplaceApi | `startAssignedRequest(requestId, ...)` | `POST /api/marketplace/requests/{id}/start/` |
| MarketplaceApi | `completeAssignedRequest(requestId, ...)` | `POST /api/marketplace/requests/{id}/complete/` |
| MarketplaceApi | `rejectAssignedRequest(requestId, ...)` | `POST /api/marketplace/provider/requests/{id}/reject/` |
| MarketplaceApi | `acceptUrgentRequest(requestId)` | `POST /api/marketplace/requests/urgent/accept/` |
| MarketplaceApi | `createOffer(requestId, ...)` | `POST /api/marketplace/requests/{id}/offers/create/` |
| ChatNav | `openThread(...)` | (navigation) |

**Fields displayed**: `title`, `description`, `status`, `client_name`, `client_phone`, `city`, `created_at`, `expected_delivery_at`, `estimated_service_amount`, `received_amount`, `actual_service_amount`, `delivered_at`, `canceled_at`, `cancel_reason`, attachments, status_logs
**Navigates to**: ChatDetailScreen

---

### 5.4 `provider_portfolio_manage_screen.dart` — ProviderPortfolioManageScreen (483 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getMyPortfolio()` | `GET /api/providers/me/portfolio/` |
| ProvidersApi | `createMyPortfolioItem(file, fileType, caption)` | `POST /api/providers/me/portfolio/` |
| ProvidersApi | `deleteMyPortfolioItem(id)` | `DELETE /api/providers/me/portfolio/{id}/` |

**Fields displayed**: portfolio items `file_url`, `file_type`, `caption`

---

### 5.5 `services_tab.dart` — ServicesTab (698 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getCategories()` | `GET /api/providers/categories/` |
| ProvidersApi | `getMyServices()` | `GET /api/providers/me/services/` |
| ProvidersApi | `createMyService(...)` | `POST /api/providers/me/services/` |
| ProvidersApi | `updateMyService(id, patch)` | `PATCH /api/providers/me/services/{id}/` |
| ProvidersApi | `deleteMyService(id)` | `DELETE /api/providers/me/services/{id}/` |

**Fields displayed/edited**: `title`, `subcategory_id`, `description`, `is_active`

---

### 5.6 `reviews_tab.dart` — ReviewsTab (627 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| AccountApi | `me()` | `GET /api/accounts/me/` (to resolve provider_profile_id) |
| ReviewsApi | `getProviderRatingSummary(id)` | `GET /api/reviews/providers/{id}/rating/` |
| ReviewsApi | `getProviderReviews(id)` | `GET /api/reviews/providers/{id}/reviews/` |
| SupportApi | (available via report) | `POST /api/support/tickets/create/` |

**Fields displayed**: `rating_avg`, `rating_count`, criteria breakdown (`response_speed`, `cost_value`, `quality`, `credibility`, `on_time`), reviews list with `client_name`, `comment`, `rating`, `created_at`

---

### 5.7 `provider_profile_completion_screen.dart` — ProviderProfileCompletionScreen (1301 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| AccountApi | `me()` | `GET /api/accounts/me/` |
| ProvidersApi | `getMyProviderProfile()` | `GET /api/providers/me/profile/` |
| ProvidersApi | `getMyProviderSubcategories()` | `GET /api/providers/me/subcategories/` |
| SessionStorage | read all fields | (local) |

**Sections managed**: service_details, additional, contact_full, lang_loc, content (portfolio), seo
**Navigates to**: ProviderServiceCategoriesScreen, AdditionalDetailsStep, ContactInfoStep, LanguageLocationStep, ProviderPortfolioManageScreen, SeoStep

---

### 5.8 `provider_service_categories_screen.dart` — ProviderServiceCategoriesScreen (307 lines)

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getCategories()` | `GET /api/providers/categories/` |
| ProvidersApi | `getMyProviderSubcategories()` | `GET /api/providers/me/subcategories/` |
| ProvidersApi | `setMyProviderSubcategories(ids)` | `PUT /api/providers/me/subcategories/` |
| ProvidersApi | `getMyProviderProfile()` | `GET /api/providers/me/profile/` |
| ProvidersApi | `updateMyProviderProfile({accepts_urgent})` | `PATCH /api/providers/me/profile/` |

**Fields displayed/edited**: category tree with subcategory checkboxes, `accepts_urgent` toggle

---

### 5.9 `profile_tab_impl.dart` — ProfileTab

| Service | Method Called | API Endpoint |
|---|---|---|
| ProvidersApi | `getMyProviderProfile()` | `GET /api/providers/me/profile/` |
| ProvidersApi | `updateMyProviderProfile(patch)` | `PATCH /api/providers/me/profile/` |

**Fields displayed/edited**: `bio`, `about_details`, `city`, `lat`, `lng`, geo-location on map

---

### 5.10 Empty / Placeholder Files

- `promotion_screen.dart` — empty
- `upgrade_screen.dart` — empty
- `verification_screen.dart` (provider_dashboard) — empty

---

## 6. Utility / Orchestration Services

| Service File | Purpose | API Calls |
|---|---|---|
| `home_feed_service.dart` | Orchestrates providers, reviews, promo APIs with local caching for home feed | ProvidersApi.getProviders, ReviewsApi.getProviderRatingSummary/Reviews, PromoApi.getHomeBanners/getActivePlacements |
| `session_storage.dart` | FlutterSecureStorage wrapper for tokens & profile fields | (local only) |
| `role_controller.dart` | ValueNotifier for client/provider role state | (local only) |
| `role_sync.dart` | Syncs role from backend | AccountApi.me() + ProvidersApi.getMyProviderProfile() |
| `account_switcher.dart` | Switches between client/provider modes | (calls role_controller) |
| `fcm_notification_service.dart` | Firebase Cloud Messaging init, device token registration | NotificationsApi.registerDeviceToken() |
| `notification_link_handler.dart` | Resolves notification payloads to navigation routes | (navigation only) |
| `notifications_badge_controller.dart` | Polls unread count periodically | NotificationsApi.getUnreadCount() |
| `payment_checkout.dart` | Wraps BillingApi.initPayment + url_launcher | BillingApi.initPayment() |
| `app_navigation.dart` | Central named-route definitions | (navigation only) |
| `chat_nav.dart` | Helper to open chat threads | MessagingApi.getOrCreateThread() |
| `app_snackbar.dart` | Snackbar helper | (UI only) |
| `google_map_location_picker_screen.dart` | Map picker for lat/lng | (geolocator/geocoding — no backend API) |
| `google_map_coverage_picker_screen.dart` | Coverage area picker | (geolocator — no backend API) |

---

*End of mapping.*
