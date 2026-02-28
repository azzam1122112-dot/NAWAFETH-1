# 📋 Nawafeth Mobile — Complete Audit Report

> **Generated from**: `mobile/lib/`  
> **Total**: 20 service files, 15 model files, 42 screen files  
> **Backend**: `https://nawafeth-2290.onrender.com`

---

## Table of Contents

1. [Routing & Navigation](#1-routing--navigation)
2. [Services — API Endpoint Map](#2-services--api-endpoint-map)
3. [Models](#3-models)
4. [Screens — Complete Audit](#4-screens--complete-audit)
5. [Registration Steps](#5-registration-steps)
6. [Critical Issues & Findings](#6-critical-issues--findings)

---

## 1. Routing & Navigation

**File**: `lib/main.dart`  
**Initial Route**: `/onboarding` → `OnboardingScreen`  
**No separate router file** — all routes in `MaterialApp`

| Route | Screen | Guard |
|---|---|---|
| `/onboarding` | `OnboardingScreen` | — |
| `/home` | `HomeScreen` | — |
| `/chats` | `MyChatsScreen` | — |
| `/orders` | `OrdersHubScreen` | — |
| `/interactive` | `InteractiveScreen` | — |
| `/profile` | `MyProfileScreen` | — |
| `/add_service` | `AddServiceScreen` | `_ModeRouteGuard` (client-only) |
| `/login` | `LoginScreen` | — |
| `/search_provider` | `SearchProviderScreen` | `_ModeRouteGuard` (client-only) |
| `/urgent_request` | `UrgentRequestScreen` | `_ModeRouteGuard` (client-only) |
| `/request_quote` | `RequestQuoteScreen` | `_ModeRouteGuard` (client-only) |

`_ModeRouteGuard` redirects providers to `/profile`.

---

## 2. Services — API Endpoint Map

### 2.1 `auth_api_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `sendOtp` | POST | `/api/accounts/otp/send/` |
| `verifyOtp` | POST | `/api/accounts/otp/verify/` |
| `checkUsernameAvailability` | GET | `/api/accounts/username-availability/?username=` |
| `completeRegistration` | POST | `/api/accounts/complete/` |

### 2.2 `auth_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| — | LOCAL | SharedPreferences token management (access/refresh) |

### 2.3 `account_mode_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| — | LOCAL | SharedPreferences `isProvider` toggle |

### 2.4 `api_client.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `_tryRefreshToken` | POST | `/api/accounts/token/refresh/` |
| `get/post/patch/put/delete` | * | Generic HTTP with JWT auth, auto-refresh on 401 |

### 2.5 `billing_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchMyInvoices` | GET | `/api/billing/invoices/my/` |
| `fetchInvoiceDetail` | GET | `/api/billing/invoices/{id}/` |
| `initPayment` | POST | `/api/billing/invoices/{id}/init-payment/` |

### 2.6 `content_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchPublicContent` | GET | `/api/content/public/` |

### 2.7 `extras_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchCatalog` | GET | `/api/extras/catalog/` |
| `fetchMyExtras` | GET | `/api/extras/my/` |
| `buy` | POST | `/api/extras/buy/{sku}/` |

### 2.8 `features_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchMyFeatures` | GET | `/api/features/my/` |

### 2.9 `home_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchCategories` | GET | `/api/providers/categories/` |
| `fetchFeaturedProviders` | GET | `/api/providers/list/?page_size=` |
| `fetchHomeBanners` | GET | `/api/promo/banners/home/?limit=` |

### 2.10 `interactive_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchFollowing` | GET | `/api/providers/me/following/` |
| `fetchFollowers` | GET | `/api/providers/me/followers/` |
| `fetchFavorites` (portfolio) | GET | `/api/providers/me/favorites/` |
| `fetchFavorites` (spotlights) | GET | `/api/providers/me/favorites/spotlights/` |
| `followProvider` | POST | `/api/providers/{id}/follow/` |
| `unfollowProvider` | POST | `/api/providers/{id}/unfollow/` |
| `unsaveItem` (portfolio) | POST | `/api/providers/portfolio/{id}/unsave/` |
| `unsaveItem` (spotlight) | POST | `/api/providers/spotlights/{id}/unsave/` |
| `fetchMyPortfolio` | GET | `/api/providers/me/portfolio/` |
| `fetchMySpotlights` | GET | `/api/providers/me/spotlights/` |
| `fetchProviderPortfolio` | GET | `/api/providers/{id}/portfolio/` |
| `fetchProviderSpotlights` | GET | `/api/providers/{id}/spotlights/` |
| `deletePortfolioItem` | DELETE | `/api/providers/me/portfolio/{id}/` |
| `deleteSpotlightItem` | DELETE | `/api/providers/me/spotlights/{id}/` |
| `likePortfolio` | POST | `/api/providers/portfolio/{id}/like/` |
| `unlikePortfolio` | POST | `/api/providers/portfolio/{id}/unlike/` |
| `savePortfolio` | POST | `/api/providers/portfolio/{id}/save/` |
| `likeSpotlight` | POST | `/api/providers/spotlights/{id}/like/` |
| `unlikeSpotlight` | POST | `/api/providers/spotlights/{id}/unlike/` |
| `saveSpotlight` | POST | `/api/providers/spotlights/{id}/save/` |
| `likeProvider` | POST | `/api/providers/{id}/like/` |
| `unlikeProvider` | POST | `/api/providers/{id}/unlike/` |
| `fetchProviderDetail` | GET | `/api/providers/{id}/` |
| `fetchProviderServices` | GET | `/api/providers/{id}/services/` |
| `fetchProviderStats` | GET | `/api/providers/{id}/stats/` |

### 2.11 `marketplace_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `getCategories` | GET | `/api/providers/categories/` |
| `createRequest` | POST (multipart) | `/api/marketplace/requests/create/` |
| `getClientRequests` | GET | `/api/marketplace/client/requests/` |
| `getClientRequestDetail` | GET | `/api/marketplace/client/requests/{id}/` |
| `updateClientRequest` | PATCH | `/api/marketplace/client/requests/{id}/` |
| `getProviderRequests` | GET | `/api/marketplace/provider/requests/` |
| `getProviderRequestDetail` | GET | `/api/marketplace/provider/requests/{id}/detail/` |
| `acceptRequest` | POST | `/api/marketplace/provider/requests/{id}/accept/` |
| `rejectRequest` | POST | `/api/marketplace/provider/requests/{id}/reject/` |
| `startRequest` | POST | `/api/marketplace/requests/{id}/start/` |
| `updateProgress` | POST | `/api/marketplace/provider/requests/{id}/progress-update/` |
| `completeRequest` | POST | `/api/marketplace/requests/{id}/complete/` |
| `getAvailableUrgentRequests` | GET | `/api/marketplace/provider/urgent/available/` |
| `acceptUrgentRequest` | POST | `/api/marketplace/requests/urgent/accept/` |
| `getAvailableCompetitiveRequests` | GET | `/api/marketplace/provider/competitive/available/` |
| `createOffer` | POST | `/api/marketplace/requests/{id}/offers/create/` |
| `getRequestOffers` | GET | `/api/marketplace/requests/{id}/offers/` |
| `acceptOffer` | POST | `/api/marketplace/offers/{id}/accept/` |
| `cancelRequest` | POST | `/api/marketplace/requests/{id}/cancel/` |
| `reopenRequest` | POST | `/api/marketplace/requests/{id}/reopen/` |

### 2.12 `messaging_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchThreads` | GET | `/api/messaging/direct/threads/` |
| (thread states) | GET | `/api/messaging/threads/states/` |
| `fetchMessages` | GET | `/api/messaging/direct/thread/{id}/messages/` |
| `sendTextMessage` | POST | `/api/messaging/direct/thread/{id}/messages/send/` |
| `sendAttachment` | POST (multipart) | `/api/messaging/direct/thread/{id}/messages/send/` |
| `markRead` | POST | `/api/messaging/direct/thread/{id}/messages/read/` |
| `markUnread` | POST | `/api/messaging/thread/{id}/unread/` |
| `toggleFavorite` | POST | `/api/messaging/thread/{id}/favorite/` |
| `toggleBlock` | POST | `/api/messaging/thread/{id}/block/` |
| `toggleArchive` | POST | `/api/messaging/thread/{id}/archive/` |
| `report` | POST | `/api/messaging/thread/{id}/report/` |
| `deleteMessage` | POST | `/api/messaging/thread/{id}/messages/{mid}/delete/` |
| `getOrCreateDirectThread` | POST | `/api/messaging/direct/thread/` |

### 2.13 `notification_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchNotifications` | GET | `/api/notifications/` |
| `fetchUnreadCount` | GET | `/api/notifications/unread-count/` |
| `markRead` | POST | `/api/notifications/mark-read/{id}/` |
| `markAllRead` | POST | `/api/notifications/mark-all-read/` |
| `togglePin` | POST | `/api/notifications/actions/{id}/` (action=pin) |
| `toggleFollowUp` | POST | `/api/notifications/actions/{id}/` (action=follow_up) |
| `deleteNotification` | DELETE | `/api/notifications/actions/{id}/` |
| `fetchPreferences` | GET | `/api/notifications/preferences/` |
| `updatePreferences` | PATCH | `/api/notifications/preferences/` |
| `registerDeviceToken` | POST | `/api/notifications/device-token/` |
| `deleteOld` | POST | `/api/notifications/delete-old/` |

### 2.14 `profile_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchMyProfile` | GET | `/api/accounts/me/` |
| `fetchProviderProfile` | GET | `/api/providers/me/profile/` |
| `updateMyProfile` | PATCH | `/api/accounts/me/` |
| `updateProviderProfile` | PATCH | `/api/providers/me/profile/` |
| `fetchWallet` | GET | `/api/accounts/wallet/` |

### 2.15 `promo_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `createRequest` | POST | `/api/promo/requests/create/` |
| `fetchMyRequests` | GET | `/api/promo/requests/my/` |
| `fetchRequestDetail` | GET | `/api/promo/requests/{id}/` |
| `uploadAsset` | POST (multipart) | `/api/promo/requests/{id}/assets/` |

### 2.16 `provider_services_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchMyServices` | GET | `/api/providers/me/services/` |
| `createService` | POST | `/api/providers/me/services/` |
| `updateService` | PATCH | `/api/providers/me/services/{id}/` |
| `deleteService` | DELETE | `/api/providers/me/services/{id}/` |
| `fetchCategories` | GET | `/api/providers/categories/` |

### 2.17 `reviews_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `createReview` | POST | `/api/reviews/requests/{id}/review/` |
| `fetchProviderReviews` | GET | `/api/reviews/providers/{id}/reviews/` |
| `fetchProviderRating` | GET | `/api/reviews/providers/{id}/rating/` |
| `replyToReview` | POST | `/api/reviews/reviews/{id}/provider-reply/` |

### 2.18 `subscriptions_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `getPlans` | GET | `/api/subscriptions/plans/` |
| `mySubscriptions` | GET | `/api/subscriptions/my/` |
| `subscribe` | POST | `/api/subscriptions/subscribe/{id}/` |

### 2.19 `support_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `fetchTeams` | GET | `/api/support/teams/` |
| `createTicket` | POST | `/api/support/tickets/create/` |
| `fetchMyTickets` | GET | `/api/support/tickets/my/` |
| `fetchTicketDetail` | GET | `/api/support/tickets/{id}/` |
| `addComment` | POST | `/api/support/tickets/{id}/comments/` |
| `uploadAttachment` | POST (multipart) | `/api/support/tickets/{id}/attachments/` |

### 2.20 `verification_service.dart`
| Method | HTTP | Endpoint |
|---|---|---|
| `createRequest` | POST | `/api/verification/requests/create/` |
| `fetchMyRequests` | GET | `/api/verification/requests/my/` |
| `fetchRequestDetail` | GET | `/api/verification/requests/{id}/` |
| `uploadDocument` | POST (multipart) | `/api/verification/requests/{id}/documents/` |

---

## 3. Models

| File | Classes | Purpose | Notes |
|---|---|---|---|
| `banner_model.dart` | `BannerModel` | Promo banner (file_type, file_url, provider info) | Used by HomeService |
| `category_model.dart` | `CategoryModel`, `SubCategoryModel` | Categories/subcategories (id, name) | Used broadly |
| `chat_message_model.dart` | `ChatMessage` | Chat message (senderId, body, attachment) | Used by MessagingService |
| `chat_thread_model.dart` | `ChatThread`, `ThreadState` | Thread with peer info, unread count, fav/block/archive states | Used by MessagingService |
| `client_order.dart` | `ClientOrder`, `ClientOrderAttachment` | ⚠️ **LEGACY** — hardcoded local model with rating/cancel fields | **NOT used** — `ServiceRequest` used instead |
| `media_item_model.dart` | `MediaItemModel`, `MediaItemSource` | Portfolio/spotlight items with like/save counts | Used by InteractiveService |
| `notification_model.dart` | `NotificationModel`, `NotificationPreference` | Notifications with kind, pin/follow_up, tier-based prefs | Used by NotificationService |
| `provider_order.dart` | `ProviderOrder`, `ProviderOrderAttachment` | ⚠️ **LEGACY** — local model | **NOT used** — `ServiceRequest` used instead |
| `provider_profile_model.dart` | `ProviderProfileModel` | Full provider profile with profileCompletion calc (6 optional sections × ~11.67%) | Used by ProfileService |
| `provider_public_model.dart` | `ProviderPublicModel` | Public provider data with social stats | Used by InteractiveService |
| `service_provider_location.dart` | `ServiceProviderLocation` | Map data (lat/lng, urgentServices, responseTime) | ⚠️ Uses camelCase JSON — possibly local-only |
| `service_request_model.dart` | `ServiceRequest`, `RequestAttachment`, `StatusLog`, `Offer` | **MAIN order model** used by MarketplaceService | Active model for all orders |
| `ticket_model.dart` | `Ticket`, `TicketReply` | Support tickets | Used by SupportService |
| `user_profile.dart` | `UserProfile` | User profile from `/api/accounts/me/` (with optional provider stats) | Used by ProfileService |
| `user_public_model.dart` | `UserPublicModel` | Minimal public user (optional providerId) | Used in threads/messages |

---

## 4. Screens — Complete Audit

### 4.1 Main Screens

| # | Screen File | What It Displays | Services / API Calls | Status |
|---|---|---|---|---|
| 1 | `onboarding_screen.dart` (230 lines) | 3-page welcome intro with animations | NONE (static) | ✅ Complete |
| 2 | `home_screen.dart` (735 lines) | Hero video header, auto-scrolling reels, categories grid, featured providers, promo banners | `HomeService.fetchCategories`, `fetchFeaturedProviders`, `fetchHomeBanners`, `ApiClient.buildMediaUrl` | ✅ API-connected; static fallback categories if API empty |
| 3 | `login_screen.dart` (300 lines) | Phone number input for OTP, guest option | `AuthApiService.sendOtp`, `AuthService.logout` | ✅ API-connected |
| 4 | `twofa_screen.dart` (476 lines) | 4-digit OTP verification with countdown | `AuthApiService.verifyOtp`, `AuthApiService.sendOtp` | ✅ API-connected; routes to SignUpScreen if `needsCompletion` |
| 5 | `signup_screen.dart` (752 lines) | Registration form (name, username, email, city, password) | `AuthApiService.completeRegistration`, `checkUsernameAvailability` | ✅ API-connected |
| 6 | `my_profile_screen.dart` (642 lines) | Client profile with cover/avatar, stats, quick actions, provider CTA | `ProfileService.fetchMyProfile`, `AccountModeService`, `AuthService` | ⚠️ Profile/cover image picking is LOCAL only (no upload) |
| 7 | `interactive_screen.dart` (793 lines) | Tabs: following, followers (provider), favorites | `InteractiveService.fetchFollowing`, `fetchFollowers`, `fetchFavorites` | ✅ API-connected |
| 8 | `my_chats_screen.dart` (690 lines) | Chat threads list with filters, search, actions | `MessagingService.fetchThreads`, `markRead`, `markUnread`, `toggleFavorite`, `toggleBlock`, `toggleArchive`, `report` | ✅ API-connected |
| 9 | `chat_detail_screen.dart` (1053 lines) | Full chat with text/attachment sending, pagination | `MessagingService.getOrCreateDirectThread`, `fetchMessages`, `sendTextMessage`, `sendAttachment`, `markRead`, `deleteMessage` | ✅ API-connected |
| 10 | `orders_hub_screen.dart` (68 lines) | Routes to client/provider orders based on mode | `AccountModeService` | ✅ Pure router |
| 11 | `client_orders_screen.dart` (471 lines) | Client's requests list with status filters | `MarketplaceService.getClientRequests`, `AccountModeService` | ✅ API-connected |
| 12 | `client_order_details_screen.dart` (940 lines) | Client request detail with edit, rating | `MarketplaceService.getClientRequestDetail`, `updateClientRequest`, `AccountModeService` | ⚠️ `_openChat()` is placeholder (snackbar only) |
| 13 | `add_service_screen.dart` (336 lines) | Hub: search provider, urgent, competitive | `HomeService.fetchCategories`, `AuthService.isLoggedIn` | ✅ API-connected |
| 14 | `search_provider_screen.dart` (536 lines) | Provider search with filters/sort | Direct `ApiClient.get('/api/providers/list/')`, `HomeService.fetchCategories` | ⚠️ Direct ApiClient call instead of using a service |
| 15 | `provider_profile_screen.dart` (2302 lines) | Provider public profile with tabs | **⛔ MOSTLY HARDCODED** | See [Critical Issues](#6-critical-issues--findings) |
| 16 | `service_detail_screen.dart` (826 lines) | Service detail with comments, likes | **⛔ ENTIRELY HARDCODED** | See [Critical Issues](#6-critical-issues--findings) |
| 17 | `service_request_form_screen.dart` (703 lines) | Create service request (normal/competitive/urgent) with attachments | `MarketplaceService.getCategories`, `createRequest` | ✅ API-connected with multipart upload |
| 18 | `request_quote_screen.dart` (552 lines) | Competitive quote form with deadline | `MarketplaceService.createRequest` (type='competitive'), `HomeService.fetchCategories` | ✅ API-connected |
| 19 | `urgent_request_screen.dart` (532 lines) | Urgent request with dispatch mode | `MarketplaceService.createRequest` (type='urgent'), `HomeService.fetchCategories` | ✅ API-connected |
| 20 | `search_screen.dart` (260 lines) | "طلبات الخدمة التنافسية" form | **⛔ HARDCODED** categories/subcategories | ⚠️ Appears **LEGACY** — replaced by `request_quote_screen` |
| 21 | `providers_map_screen.dart` (1355 lines) | Map view of nearby providers | **⛔ DUMMY DATA** (`_providers` list is hardcoded) | See [Critical Issues](#6-critical-issues--findings) |
| 22 | `notifications_screen.dart` (450 lines) | Notifications list with actions | `NotificationService.fetchNotifications`, `markRead`, `markAllRead`, `togglePin`, `toggleFollowUp`, `deleteNotification`, `AccountModeService` | ✅ API-connected |
| 23 | `notification_settings_screen.dart` (355 lines) | Notification preferences with tier toggles | `NotificationService.fetchPreferences`, `updatePreferences`, `AccountModeService` | ✅ API-connected |
| 24 | `plans_screen.dart` (276 lines) | Subscription plans list | `SubscriptionsService.getPlans`, `subscribe` | ✅ API-connected |
| 25 | `contact_screen.dart` (1124 lines) | Support tickets + new ticket form + detail | `SupportService.fetchTeams`, `fetchMyTickets`, `createTicket`, `fetchTicketDetail`, `addComment` | ✅ API-connected |
| 26 | `login_settings_screen.dart` (501 lines) | Account settings (phone, email, name) | `ProfileService.fetchMyProfile`, `updateMyProfile` | ⚠️ Security code & FaceID sections are LOCAL UI only |
| 27 | `about_screen.dart` (256 lines) | About page with expandable cards | NONE (static) | ⚠️ TODO: real App Store/Google Play links |
| 28 | `terms_screen.dart` (216 lines) | Terms & conditions | `ContentService.fetchPublicContent` | ✅ Fallback to hardcoded if API empty |
| 29 | `verification_screen.dart` (1541 lines) | 3-step verification wizard | `VerificationService.createRequest`, `uploadDocument` | ✅ API-connected; payment method selection is UI-only |
| 30 | `additional_services_screen.dart` (404 lines) | Extras catalog with buy flow | `ExtrasService.fetchCatalog`, `buy` | ⚠️ Main categories are static; items from API |

### 4.2 Provider Dashboard Screens

| # | Screen File | What It Displays | Services / API Calls | Status |
|---|---|---|---|---|
| 31 | `provider_home_screen.dart` (1272 lines) | Dashboard: header, completion %, stats, subscriptions | `ProfileService.fetchMyProfile`, `fetchProviderProfile`, `SubscriptionsService.mySubscriptions`, `AccountModeService` | ✅ API-connected |
| 32 | `provider_orders_screen.dart` (404 lines) | Provider's orders list with status filters | `MarketplaceService.getProviderRequests`, `AccountModeService` | ✅ API-connected |
| 33 | `provider_order_details_screen.dart` (1066 lines) | Order detail with accept/reject/start/progress/complete | `MarketplaceService.getProviderRequestDetail`, `acceptRequest`, `rejectRequest`, `startRequest`, `updateProgress`, `completeRequest` | ✅ API-connected |
| 34 | `services_tab.dart` (739 lines) | Services CRUD organized by category | `ProviderServicesService.fetchCategories`, `fetchMyServices`, `createService`, `updateService`, `deleteService` | ✅ API-connected |
| 35 | `profile_tab.dart` (643 lines) | Provider profile editor with inline editing | `ProfileService.fetchMyProfile`, `fetchProviderProfile`, `updateProviderProfile` | ✅ API-connected |
| 36 | `reviews_tab.dart` (738 lines) | Reviews + rating breakdown + reply | `ReviewsService.fetchProviderReviews`, `fetchProviderRating`, `replyToReview`, `ProfileService.fetchMyProfile` | ✅ API-connected |
| 37 | `promotion_screen.dart` (873 lines) | Promo/ads: create + view requests | `PromoService.createRequest`, `fetchMyRequests`, `uploadAsset` | ✅ API-connected |
| 38 | `upgrade_screen.dart` (15 lines) | Wrapper for PlansScreen | (delegates to `PlansScreen`) | ✅ Wrapper |
| 39 | `provider_profile_completion_screen.dart` (596 lines) | Multi-section profile completion wizard | `ProfileService.fetchProviderProfile` | ✅ API-connected; launches registration step screens |
| 40 | `verification_screen.dart` (provider_dashboard/) (15 lines) | Wrapper for main VerificationScreen | (delegates to `VerificationScreen`) | ✅ Wrapper |

---

## 5. Registration Steps

**Entry Point**: `register_service_provider.dart` (595 lines) — 3-step wizard (personal info → classification → contact), completion tracking, success overlay → `ProviderHomeScreen`

| # | Step File | Lines | What It Collects | Service / API | Status |
|---|---|---|---|---|---|
| R1 | `personal_info_step.dart` | 188 | Name (AR+EN), bio, account type (فرد/شركة) | NONE (local form) | ⚠️ No API save — may rely on parent wizard |
| R2 | `service_classification_step.dart` | 977 | Main category, subcategories, urgent toggle | NONE (local form) | ⚠️ Categories are **HARDCODED** static lists |
| R3 | `service_details_step.dart` | 795 | Service name, description, accepts_urgent | `ProfileService.fetchProviderProfile`, `updateProviderProfile` | ✅ Auto-saves via `DebouncedSaveRunner` |
| R4 | `additional_details_step.dart` | 721 | About text, qualifications list, experiences list | `ProfileService.fetchProviderProfile`, `updateProviderProfile` | ✅ Auto-saves via `DebouncedSaveRunner` |
| R5 | `contact_info_step.dart` | 872 | Website, phone, WhatsApp, social media (9 platforms), logo, map location | `ProfileService.fetchProviderProfile`, `updateProviderProfile` | ✅ Auto-saves; image picker for logo |
| R6 | `language_location_step.dart` | 669 | Languages, service range, map radius picker | `ProfileService.fetchProviderProfile`, `updateProviderProfile` | ✅ Auto-saves; uses `MapRadiusPickerScreen` |
| R7 | `content_step.dart` | 1249 | Content sections (title + body + images) | `ProfileService.fetchProviderProfile`, `updateProviderProfile` | ✅ Auto-saves; section CRUD with image upload |
| R8 | `seo_step.dart` | 253 | SEO keywords, meta description, slug | `ProfileService.fetchProviderProfile`, `updateProviderProfile` | ✅ Auto-saves |
| R9 | `map_radius_picker_screen.dart` | 188 | Map location + radius circle | NONE (returns LatLng result) | ✅ Uses flutter_map + OpenStreetMap tiles |

---

## 6. Critical Issues & Findings

### ⛔ CRITICAL — Screens With Hardcoded/Dummy Data

| Screen | Problem | Fix Required |
|---|---|---|
| **`provider_profile_screen.dart`** | Stats (completedRequests=79, followersCount=33, etc.), highlights, services grid, and gallery all use **LOCAL DUMMY DATA**. Only basic constructor params from caller are used. | Integrate `InteractiveService.fetchProviderDetail`, `fetchProviderServices`, `fetchProviderStats` |
| **`service_detail_screen.dart`** | **Entirely hardcoded**. Comments are fake, likes/shares are local counters. No API integration at all. | Build new service detail API or integrate with `ProviderServicesService` / `InteractiveService` |
| **`providers_map_screen.dart`** | `_providers` list is populated with **hardcoded test data**. No API call for nearby providers. | Create nearby-providers API endpoint and integrate |
| **`search_screen.dart`** | Categories/subcategories are **static strings**. Appears to be LEGACY, duplicated by `request_quote_screen.dart`. | Remove or redirect to `request_quote_screen` |

### ⚠️ WARNINGS — Partial Issues

| Issue | Location | Detail |
|---|---|---|
| Legacy models not used | `client_order.dart`, `provider_order.dart` | These models are NOT imported anywhere else. `ServiceRequest` from `service_request_model.dart` is the active model. Safe to delete. |
| `_openChat()` placeholder | `client_order_details_screen.dart` | Shows snackbar "سيتم فتح المحادثة قريباً" instead of opening a chat. Should call `MessagingService.getOrCreateDirectThread` then navigate to `ChatDetailScreen`. |
| Profile image upload missing | `my_profile_screen.dart` | Image picker selects file locally but never uploads to API. Need multipart PATCH to `/api/accounts/me/` or dedicated upload endpoint. |
| Security/FaceID is UI-only | `login_settings_screen.dart` | Security code toggle and FaceID toggle are local switches with no backend endpoints. |
| Direct ApiClient call | `search_provider_screen.dart` | Uses `ApiClient.get('/api/providers/list/')` directly instead of going through a service layer. |
| Registration categories hardcoded | `service_classification_step.dart` | Categories like "اتصالات وشبكات", "التسويق", etc. are hardcoded instead of fetched from `/api/providers/categories/`. |
| Store links TODO | `about_screen.dart` | Comment: "روابط المتاجر الحقيقية" — real App Store / Google Play links needed. |
| `ServiceProviderLocation` model | `service_provider_location.dart` | Uses camelCase JSON keys — inconsistent with backend snake_case convention. Only used by `providers_map_screen` (which is itself hardcoded). |

### 📊 Summary Statistics

| Metric | Count |
|---|---|
| Total service files | 20 |
| Total model files | 15 |
| Total screen files | 42 (30 main + 3 wrappers + 9 registration steps) |
| Unique API endpoints | ~120 |
| Screens fully API-connected | **30** ✅ |
| Screens with hardcoded/dummy data | **4** ⛔ |
| Screens with partial issues | **6** ⚠️ |
| Screens that are static/no-API needed | **2** (onboarding, about) |
| Legacy/unused models | **2** (client_order, provider_order) |
| Registration steps without API save | **2** (personal_info, service_classification) |
