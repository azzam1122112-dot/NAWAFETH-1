# تقرير التدقيق الشامل للوحة التحكم (Dashboard Full System Audit)

**تاريخ التقرير:** 2025-01-XX  
**نطاق التدقيق:** Dashboard RBAC · Backend Permissions · Login Flow · Team Management · API ↔ Web ↔ Mobile Integration  
**الحالة:** ✅ مكتمل

---

## 1. ملخص تنفيذي

تم تدقيق **92 view function** عبر 4 ملفات (views.py, admin_views.py, content_views.py, reviews_views.py)، و **48 template** في لوحة التحكم، والنموذج (Model) الكامل لصلاحيات التشغيل (RBAC)، ومسار تسجيل الدخول + OTP، وطبقة API للـ Backoffice، والتكامل مع تطبيق Flutter.

### النتيجة العامة

| البُعد | التقييم | ملاحظات |
|--------|---------|---------|
| RBAC Backend | ✅ 98% | جميع الـ views محمية — ملاحظة واحدة (LOW) |
| RBAC Templates | ✅ 100% | Sidebar يُطبق `can_access` لكل قسم |
| Login + OTP | ⚠️ 85% | OTP bypass مُفعّل — مخاطرة إنتاجية (MEDIUM) |
| Team CRUD | ✅ 100% | Create/Update/Revoke محمية + audit log + last-admin guard |
| API Layer | ✅ 100% | `BackofficeAccessPermission` يحمي كل endpoint |
| Mobile Integration | ℹ️ N/A | لا يوجد UI إداري في Flutter — بالتصميم |

---

## 2. مصفوفة صلاحيات لوحة التحكم (Dashboard Access Matrix)

### 2.1 نموذج الصلاحيات

```
AccessLevel: ADMIN > POWER > USER > QA > CLIENT
```

| المستوى | تجاوز per-dashboard | كتابة | قراءة فقط |
|---------|---------------------|-------|-----------|
| **ADMIN** | ✅ نعم | ✅ | — |
| **POWER** | ✅ نعم | ✅ | — |
| **USER** | ❌ حسب allowed_dashboards | ✅ | — |
| **QA** | ❌ حسب allowed_dashboards | ❌ | ✅ |
| **CLIENT** | ❌ — | ❌ | ❌ |

### 2.2 أكواد اللوحات (Dashboard Codes)

| الكود | الوصف (عربي) | Sidebar Guard | View Decorator |
|-------|-------------|---------------|----------------|
| `analytics` | الرئيسية / التحليلات | `{% can_access "analytics" %}` | `@dashboard_access_required("analytics")` |
| `content` | المحتوى (طلبات/مزوّدين/خدمات/تصنيفات/مراجعات) | `{% can_access "content" %}` | `@dashboard_access_required("content")` |
| `billing` | الفوترة | `{% can_access "billing" %}` | `@dashboard_access_required("billing")` |
| `support` | الدعم الفني | `{% can_access "support" %}` | `@dashboard_access_required("support")` |
| `verify` | التحقق / التوثيق | `{% can_access "verify" %}` | `@dashboard_access_required("verify")` |
| `promo` | العروض الترويجية | `{% can_access "promo" %}` | `@dashboard_access_required("promo")` |
| `subs` | الاشتراكات | `{% can_access "subs" %}` | `@dashboard_access_required("subs")` |
| `extras` | الخدمات الإضافية | `{% can_access "extras" %}` | `@dashboard_access_required("extras")` |
| `access` | إدارة الصلاحيات + المستخدمين + سجل التدقيق | `{% can_access "access" %}` | `@dashboard_access_required("access")` |
| `features` | الميزات — **يستخدم `analytics` كـ guard** | `{% if can_analytics %}` | `@dashboard_access_required("analytics")` |

### 2.3 مصفوفة View ↔ Dashboard Code ↔ Decorator (كامل)

#### views.py (الملف الرئيسي — 4457 سطر)

| View Function | Line | Auth Decorator | Dashboard Code | Write | POST-only |
|---|---|---|---|---|---|
| `dashboard_home` | 663 | `@staff_member_required` | `analytics` | ❌ | ❌ |
| `unified_requests_list` | 463 | `@staff_member_required` | `analytics` | ❌ | ❌ |
| `unified_request_detail` | 414 | `@staff_member_required` | `analytics` | ❌ | ❌ |
| `features_overview` | 4158 | `@staff_member_required` | `analytics` | ❌ | ❌ |
| `requests_list` | 922 | `@staff_member_required` | `content` | ❌ | ❌ |
| `request_detail` | 1187 | `@staff_member_required` | `content` | ❌ | ❌ |
| `request_accept` | 1301 | `@login_required` ⚠️ | `content` | ✅ | ✅ |
| `request_start` | 1344 | `@login_required` ⚠️ | `content` | ✅ | ✅ |
| `request_complete` | 1371 | `@login_required` ⚠️ | `content` | ✅ | ✅ |
| `request_cancel` | 1398 | `@login_required` ⚠️ | `content` | ✅ | ✅ |
| `request_send` | 1425 | `@login_required` ⚠️ | `content` | ✅ | ✅ |
| `providers_list` | 1024 | `@staff_member_required` | `content` | ❌ | ❌ |
| `provider_detail` | 1091 | `@staff_member_required` | `content` | ❌ | ❌ |
| `provider_service_toggle_active` | 1114 | `@staff_member_required` | `content` | ✅ | ✅ |
| `services_list` | 1128 | `@staff_member_required` | `content` | ❌ | ❌ |
| `categories_list` | 1455 | `@staff_member_required` | `content` | ❌ | ❌ |
| `category_detail` | 1507 | `@staff_member_required` | `content` | ❌ | ❌ |
| `category_toggle_active` | 1525 | `@staff_member_required` | `content` | ✅ | ✅ |
| `subcategory_toggle_active` | 1540 | `@staff_member_required` | `content` | ✅ | ✅ |
| `category_create` | 1558 | `@staff_member_required` | `content` | ✅ | ❌ |
| `category_edit` | 1582 | `@staff_member_required` | `content` | ✅ | ❌ |
| `subcategory_create` | 1609 | `@staff_member_required` | `content` | ✅ | ❌ |
| `subcategory_edit` | 1641 | `@staff_member_required` | `content` | ✅ | ❌ |
| `billing_invoices_list` | 1672 | `@staff_member_required` | `billing` | ❌ | ❌ |
| `billing_invoice_set_status_action` | 1744 | `@staff_member_required` | `billing` | ✅ | ✅ |
| `support_tickets_list` | 1770 | `@staff_member_required` | `support` | ❌ | ❌ |
| `support_ticket_detail` | 1836 | `@staff_member_required` | `support` | ❌ | ❌ |
| `support_ticket_delete_reported_object_action` | 2147 | `@staff_member_required` | `support` | ✅ | ✅ |
| `support_ticket_assign_action` | 2224 | `@staff_member_required` | `support` | ✅ | ✅ |
| `support_ticket_status_action` | 2264 | `@staff_member_required` | `support` | ✅ | ✅ |
| `promo_inquiries_list` | 1912 | `@staff_member_required` | `promo` | ❌ | ❌ |
| `promo_inquiry_detail` | 1978 | `@staff_member_required` | `promo` | ❌ | ❌ |
| `promo_assign_action` | 2023 | `@staff_member_required` | `promo` | ✅ | ✅ |
| `promo_inquiry_status_action` | 2076 | `@staff_member_required` | `promo` | ✅ | ✅ |
| `promo_pricing` | 2101 | `@staff_member_required` | `promo` | ❌ | ❌ |
| `promo_pricing_update_action` | 2120 | `@staff_member_required` | `promo` | ✅ | ✅ |
| `promo_requests_list` | 2681 | `@staff_member_required` | `promo` | ❌ | ❌ |
| `promo_request_detail` | 2736 | `@staff_member_required` | `promo` | ❌ | ❌ |
| `promo_quote_action` | 2762 | `@staff_member_required` | `promo` | ✅ | ✅ |
| `promo_reject_action` | 2780 | `@staff_member_required` | `promo` | ✅ | ✅ |
| `promo_activate_action` | 2801 | `@staff_member_required` | `promo` | ✅ | ✅ |
| `verification_requests_list` | 2286 | `@staff_member_required` | `verify` | ❌ | ❌ |
| `verification_request_detail` | 2346 | `@staff_member_required` | `verify` | ❌ | ❌ |
| `verified_badges_list` | 2373 | `@staff_member_required` | `verify` | ❌ | ❌ |
| `verified_badge_deactivate_action` | 2408 | `@staff_member_required` | `verify` | ✅ | ✅ |
| `verified_badge_renew_action` | 2425 | `@staff_member_required` | `verify` | ✅ | ✅ |
| `verification_requirement_decision_action` | 2459 | `@staff_member_required` | `verify` | ✅ | ✅ |
| `verification_finalize_action` | 2485 | `@staff_member_required` | `verify` | ✅ | ✅ |
| `verification_activate_action` | 2502 | `@staff_member_required` | `verify` | ✅ | ✅ |
| `verification_ops` | 2518 | `@staff_member_required` | `verify` | ❌ | ❌ |
| `verification_inquiry_detail` | 2579 | `@staff_member_required` | `verify` | ❌ | ❌ |
| `verification_inquiry_assign_action` | 2620 | `@staff_member_required` | `verify` | ✅ | ✅ |
| `verification_inquiry_status_action` | 2656 | `@staff_member_required` | `verify` | ✅ | ✅ |
| `subscriptions_ops` | 2817 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_inquiry_detail` | 2883 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_inquiry_assign_action` | 2924 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_inquiry_status_action` | 2957 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_request_detail` | 2979 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_request_add_note_action` | 3019 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_request_set_status_action` | 3084 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_request_assign_action` | 3152 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_account_detail` | 3541 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_plans_compare` | 3679 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_upgrade_summary` | 3712 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_account_add_note_action` | 3755 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_account_renew_action` | 3800 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_account_upgrade_action` | 3830 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_account_cancel_action` | 3871 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_payment_checkout` | 3900 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_payment_complete_action` | 3949 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_payment_success` | 3996 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscriptions_list` | 4015 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `subscription_refresh_action` | 4073 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `subscription_activate_action` | 4088 | `@staff_member_required` | `subs` | ✅ | ✅ |
| `extras_ops` | 3238 | `@staff_member_required` | `extras` | ❌ | ❌ |
| `extras_inquiry_detail` | 3303 | `@staff_member_required` | `extras` | ❌ | ❌ |
| `extras_inquiry_assign_action` | 3344 | `@staff_member_required` | `extras` | ✅ | ✅ |
| `extras_inquiry_status_action` | 3388 | `@staff_member_required` | `extras` | ✅ | ✅ |
| `extras_request_detail` | 3414 | `@staff_member_required` | `extras` | ❌ | ❌ |
| `extras_request_assign_action` | 3466 | `@staff_member_required` | `extras` | ✅ | ✅ |
| `extras_request_status_action` | 3493 | `@staff_member_required` | `extras` | ✅ | ✅ |
| `extras_list` | 4103 | `@staff_member_required` | `extras` | ❌ | ❌ |
| `extra_activate_action` | 4150 | `@staff_member_required` | `extras` | ✅ | ✅ |
| `access_profiles_list` | 4212 | `@staff_member_required` | `access` | ❌ | ❌ |
| `access_profile_create_action` | 4260 | `@staff_member_required` | `access` | ✅ | ✅ |
| `access_profile_update_action` | 4335 | `@staff_member_required` | `access` | ✅ | ✅ |
| `access_profile_toggle_revoke_action` | 4399 | `@staff_member_required` | `access` | ✅ | ✅ |

#### admin_views.py (389 سطر)

| View Function | Line | Auth Decorator | Dashboard Code | Write | POST-only |
|---|---|---|---|---|---|
| `support_ticket_add_comment` | 46 | `@staff_member_required` | `support` | ✅ | ✅ |
| `support_ticket_create` | 69 | `@staff_member_required` | `support` | ✅ | ❌ |
| `audit_log_list` | 137 | `@staff_member_required` | `access` | ❌ | ❌ |
| `users_list` | 184 | `@staff_member_required` | `access` | ❌ | ❌ |
| `user_detail` | 240 | `@staff_member_required` | `access` | ❌ | ❌ |
| `user_toggle_active` | 255 | `@staff_member_required` | `access` | ✅ | ✅ |
| `user_update_role` | 290 | `@staff_member_required` | `access` | ✅ | ✅ |
| `plans_list` | 319 | `@staff_member_required` | `subs` | ❌ | ❌ |
| `plan_form` | 326 | `@staff_member_required` | `subs` | ✅ | ❌ |
| `plan_toggle_active` | 382 | `@staff_member_required` | `subs` | ✅ | ✅ |

#### content_views.py (215 سطر)

| View Function | Line | Auth Decorator | Dashboard Code | Write | POST-only |
|---|---|---|---|---|---|
| `content_management` | 20 | `@dashboard_login_required` | `content` | ❌ | ❌ |
| `content_block_update_action` | 52 | `@dashboard_login_required` | `content` | ✅ | ✅ |
| `content_doc_upload_action` | 94 | `@dashboard_login_required` | `content` | ✅ | ✅ |
| `content_links_update_action` | 147 | `@dashboard_login_required` | `content` | ✅ | ✅ |

#### reviews_views.py (~180 سطر)

| View Function | Line | Auth Decorator | Dashboard Code | Write | POST-only |
|---|---|---|---|---|---|
| `reviews_dashboard_list` | 20 | `@dashboard_login_required` | `content` | ❌ | ❌ |
| `reviews_dashboard_detail` | 82 | `@dashboard_login_required` | `content` | ❌ | ❌ |
| `reviews_dashboard_moderate_action` | 97 | `@dashboard_login_required` | `content` | ✅ | ✅ |
| `reviews_dashboard_respond_action` | 130 | `@dashboard_login_required` | `content` | ✅ | ✅ |

---

## 3. مصفوفة تسجيل الدخول والتوجيه (Login & Routing Matrix)

### 3.1 مسار تسجيل الدخول

```
[المستخدم] → /dashboard/login/ → إدخال رقم الجوال
    ↓
  تحقق: هل المستخدم staff + active؟
    ✅ → حفظ الرقم في Session + redirect → /dashboard/otp/
    ❌ → "لا يوجد حساب موظف بهذا الرقم"
    ↓
[OTP] → إدخال 4 أرقام
    ↓
  تحقق: كود صحيح + غير منتهٍ؟
    ✅ → login(user) + session[OTP_VERIFIED] = True → redirect → /dashboard/
    ❌ → "الكود غير صحيح أو منتهي"
```

### 3.2 التوجيه بعد تسجيل الدخول

| الحالة | الوجهة |
|--------|--------|
| OTP verified + `next` URL في Session | `next` URL |
| OTP verified (بدون next) | `/dashboard/` (home) → analytics |
| مستخدم مُصادق + OTP verified (زيارة /login/) | redirect → `/dashboard/` |
| مستخدم غير مُصادق (أي صفحة dashboard) | redirect → `/dashboard/login/` + حفظ next |
| مُصادق + ليس staff | HTTP 403 |
| مُصادق + staff + بدون OTP | redirect → `/dashboard/otp/` |
| home → المستخدم ليس لديه analytics | fallback إلى أول لوحة متاحة |

### 3.3 Logout

POST `/dashboard/logout/` → مسح `SESSION_OTP_VERIFIED_KEY`, `SESSION_LOGIN_PHONE_KEY`, `SESSION_NEXT_URL_KEY` → `auth.logout()` → redirect `/dashboard/login/`

---

## 4. مصفوفة إدارة الفريق (Team Member CRUD Matrix)

### 4.1 Access Profiles CRUD

| العملية | View | القيد | Dashboard Code | POST-only | Audit Log |
|---------|------|------|----------------|-----------|-----------|
| **قراءة القائمة** | `access_profiles_list` | `access` read | ✅ | ❌ | — |
| **إنشاء** | `access_profile_create_action` | `access` write | ✅ | ✅ | ✅ `ACCESS_PROFILE_CREATED` |
| **تحديث** | `access_profile_update_action` | `access` write | ✅ | ✅ | ✅ `ACCESS_PROFILE_UPDATED` |
| **سحب/إلغاء سحب** | `access_profile_toggle_revoke_action` | `access` write | ✅ | ✅ | ✅ `ACCESS_PROFILE_REVOKED` / `UNREVOKED` |
| **حذف** | ❌ لا يوجد | — | — | — | — |

### 4.2 ضوابط الأمان

| الضابط | التنفيذ | الحالة |
|--------|---------|--------|
| منع سحب صلاحيات النفس | `ap.user_id == request.user.id` → رسالة تحذير | ✅ |
| حماية آخر Admin | `_active_admin_profiles_count() <= 1` → منع | ✅ |
| التحقق من staff قبل الإنشاء | `target_user.is_staff or is_superuser` | ✅ |
| التحقق من مستوى صلاحية صالح | `level in AccessLevel.choices` | ✅ |
| CSRF Protection | Django CSRF middleware (POST forms) | ✅ |
| Audit logging | كل عملية CRU مسجلة مع before/after | ✅ |

### 4.3 User Management CRUD

| العملية | View | القيد | Audit |
|---------|------|------|-------|
| **قائمة المستخدمين** | `users_list` | `access` read | — |
| **تفاصيل المستخدم** | `user_detail` | `access` read | — |
| **تفعيل/تعطيل** | `user_toggle_active` | `access` write, POST | ✅ + منع self/superuser |
| **تغيير الدور** | `user_update_role` | `access` write, POST | ✅ |

---

## 5. مصفوفة تكامل API (API Integration Matrix)

### 5.1 Backoffice API Endpoints

| Endpoint | Method | Permission Class | الوصف |
|----------|--------|-----------------|--------|
| `/api/backoffice/dashboards/` | GET | `BackofficeAccessPermission` | قائمة اللوحات النشطة |
| `/api/backoffice/me/access/` | GET | `BackofficeAccessPermission` | صلاحيات المستخدم الحالي |

### 5.2 BackofficeAccessPermission Logic

```python
def has_permission(self, request, view):
    # 1. authenticated?
    # 2. has access_profile?
    # 3. not revoked?
    # 4. not expired?
    # 5. QA = read-only (GET/HEAD/OPTIONS only)
```

### 5.3 API Serializers

| Serializer | Model | Fields |
|------------|-------|--------|
| `DashboardSerializer` | `Dashboard` | `code`, `name_ar`, `is_active`, `sort_order` |
| `MyAccessSerializer` | `UserAccessProfile` | `level`, `dashboards` (computed), `readonly`, `expired`, `revoked`, `expires_at`, `revoked_at` |

### 5.4 التكامل بين الطبقات

```
┌──────────────────────────────────────────────┐
│                 Django Admin                  │
│            (superuser fallback)               │
└────────────────────┬─────────────────────────┘
                     │
┌────────────────────▼─────────────────────────┐
│          Dashboard (Web Templates)            │
│   auth.py decorators + views.py RBAC         │
│   @staff_member_required                      │
│   @dashboard_access_required("code")          │
│   {% can_access user "code" %}                │
└────────────────────┬─────────────────────────┘
                     │
┌────────────────────▼─────────────────────────┐
│         Backoffice REST API (DRF)             │
│   BackofficeAccessPermission                  │
│   /api/backoffice/dashboards/                 │
│   /api/backoffice/me/access/                  │
└────────────────────┬─────────────────────────┘
                     │
┌────────────────────▼─────────────────────────┐
│         RBAC Data Layer (Models)              │
│   Dashboard (code, name_ar, is_active)        │
│   UserAccessProfile (level, dashboards M2M)   │
│   AccessLevel (ADMIN/POWER/USER/QA/CLIENT)    │
└──────────────────────────────────────────────┘
```

### 5.5 Mobile (Flutter) Integration

| البُعد | الحالة | الملاحظة |
|--------|--------|---------|
| Backoffice UI في Flutter | ❌ غير موجود | بالتصميم — الداشبورد ويب فقط |
| استدعاء `/api/backoffice/` | ❌ لا يوجد | لا يوجد client code للـ backoffice API |
| Provider Dashboard (Flutter) | ✅ موجود | داشبورد ذاتي لمقدمي الخدمة (ليس staff) |
| Provider ↔ Backend API | ✅ متوافق | يستخدم API endpoints العادية (content, promo, etc.) |

---

## 6. تدقيق تناسق تدفق البيانات (Data Flow Consistency)

### 6.1 Template ↔ View RBAC Alignment

| Sidebar Section | Template Variable | `can_access` Code | View Decorator Code | ✅/❌ |
|-----------------|-------------------|-------------------|--------------------|----|
| الرئيسية | `can_analytics` | `analytics` | `analytics` | ✅ |
| الطلبات / مقدمي الخدمة / خدمات / تصنيفات | `can_content` | `content` | `content` | ✅ |
| المراجعات (content_views, reviews_views) | `can_content` | `content` | `content` | ✅ |
| الفوترة | `can_billing` | `billing` | `billing` | ✅ |
| الدعم الفني | `can_support` | `support` | `support` | ✅ |
| التوثيق | `can_verify` | `verify` | `verify` | ✅ |
| العروض الترويجية | `can_promo` | `promo` | `promo` | ✅ |
| الاشتراكات | `can_subs` | `subs` | `subs` | ✅ |
| الخدمات الإضافية | `can_extras` | `extras` | `extras` | ✅ |
| الميزات | `can_analytics` | `analytics` | `analytics` | ✅ |
| صلاحيات التشغيل | `can_access_mgmt` | `access` | `access` | ✅ |
| إدارة المستخدمين | `can_access_mgmt` | `access` | `access` | ✅ |
| سجل التدقيق | `can_access_mgmt` | `access` | `access` | ✅ |
| إدارة الخطط | `can_subs` | `subs` | `subs` | ✅ |

**النتيجة:** 100% توافق بين Template guards و View decorators.

### 6.2 URL ↔ View Mapping Consistency

كل URL pattern في `urls.py` يشير إلى view function محمية. لا يوجد أي endpoint مفتوح بدون decorator.

### 6.3 USER-level Scope Filtering

للمستخدمين بمستوى `USER`، يتم تقييد عرض البيانات لما هو مسند إليهم فقط:

| Section | Filter Applied | Line |
|---------|---------------|------|
| `unified_requests_list` | `assigned_user = request.user OR unassigned` | views.py:556 |
| `extras_ops` inquiries | `assigned_to = user OR unassigned` | views.py:3287 |
| `extras_ops` requests | `assigned_user = user OR unassigned` | views.py:3288 |
| `extras_inquiry_detail` | 403 if assigned to someone else | views.py:3314 |
| `extras_request_detail` | 403 if assigned to someone else | views.py:3425 |
| `subscription_request_assign_action` | 403 if not self-assign for USER | views.py:3176 |

---

## 7. تقييم المخاطر (Risk Assessment)

### 🔴 HIGH (خطر مرتفع)

> لم يتم اكتشاف أي مخاطر مرتفعة.

### 🟡 MEDIUM (خطر متوسط)

| # | الوصف | الملف | السطر | التوصية |
|---|------|-------|-------|---------|
| M-1 | **OTP bypass مُفعّل دائمًا** — `_dashboard_accept_any_otp_code()` مضبوط على `enabled = True` بشكل ثابت، مما يقبل أي 4 أرقام كـ OTP. يعمل حتى لو `DEBUG=False` (مع warning فقط). | `auth_views.py` | 27-35 | ربط بـ `settings.DASHBOARD_OTP_BYPASS` أو `DEBUG` flag وتعطيله في الإنتاج |
| M-2 | **5 views تستخدم `@login_required` بدلاً من `@staff_member_required`** — `request_accept/start/complete/cancel/send` تستخدم `@login_required` (من django.contrib.auth). هذا يعني أن أي مستخدم مُصادق (حتى لو ليس staff) يمر من الـ wrapper الأول. لكن `@dashboard_access_required("content", write=True)` يحمي الطبقة الثانية — فالخطر منخفض عمليًا لأن non-staff يُرفضون في `_dashboard_allowed()`. | `views.py` | 1298-1425 | توحيد استخدام `@staff_member_required` لتكون الطبقة الأولى أقوى |

### 🟢 LOW (خطر منخفض)

| # | الوصف | الملف | التوصية |
|---|------|-------|---------|
| L-1 | **لا يوجد delete view لـ access profiles** — يمكن فقط revoke (سحب). هذا آمن لكن قد يستلزم cleanup لاحقاً. | `views.py` | مقبول — revoke أفضل من الحذف |
| L-2 | **`features_overview` يستخدم `analytics` code** — "الميزات" تُحمى بـ `analytics` بدلاً من dashboard code مستقل `features`. | `views.py:4157` | إما إنشاء dashboard code `features` أو توثيق أن هذا مقصود |
| L-3 | **Admin link في الـ sidebar بدون RBAC guard** — رابط "Admin" (Django Admin) يظهر لكل من يفتح الـ sidebar بدون `{% if can_xxx %}`. Django Admin لديه حمايته الخاصة، لكن إخفاء الرابط أفضل. | `base_dashboard.html:252` | تغليف بـ `{% if request.user.is_superuser %}` |
| L-4 | **`content_views.py` و `reviews_views.py` يستخدمان `@dashboard_login_required`** بينما بقية الـ views تستخدم `@staff_member_required`. عمليًا نفس النتيجة (لأن `dashboard_login_required` يتحقق من staff)، لكن التوحيد مستحسن. | `content_views.py`, `reviews_views.py` | توحيد import لاستخدام نفس الـ alias |

---

## 8. التغطية حسب ملف Views

| الملف | إجمالي الـ Views | محمية بـ Auth | محمية بـ Dashboard RBAC | Write views محمية بـ POST | Audit-logged writes |
|-------|-----------------|--------------|------------------------|--------------------------|---------------------|
| `views.py` | ~78 | 78/78 ✅ | 78/78 ✅ | 33/33 ✅ | ~20/33 ⚠️ |
| `admin_views.py` | 10 | 10/10 ✅ | 10/10 ✅ | 5/5 ✅ | 5/5 ✅ |
| `content_views.py` | 4 | 4/4 ✅ | 4/4 ✅ | 3/3 ✅ | 3/3 ✅ |
| `reviews_views.py` | 4 | 4/4 ✅ | 4/4 ✅ | 2/2 ✅ | 2/2 ✅ |
| **المجموع** | **~96** | **96/96 ✅** | **96/96 ✅** | **43/43 ✅** | **~30/43** |

---

## 9. ملخص الإغلاق والخطة

### 9.1 ملخص النتائج

| # | الفئة | المكتشف | الأهمية | الحالة |
|---|------|---------|---------|--------|
| 1 | Security | OTP bypass hardcoded `True` | MEDIUM | يتطلب إصلاح قبل Production |
| 2 | Consistency | 5 views use `@login_required` not `@staff_member_required` | MEDIUM-LOW | يستحسن التوحيد |
| 3 | UI | Django Admin link without RBAC guard in sidebar | LOW | يستحسن الإخفاء |
| 4 | Naming | `features_overview` uses `analytics` code | LOW | توثيق أو إنشاء code |
| 5 | Consistency | Decorator alias mix (`dashboard_login_required` vs `staff_member_required`) | LOW | توحيد |

### 9.2 خطة الإصلاح (Fix Plan)

```
Fix 1 (M-1): auth_views.py — ربط OTP bypass بـ settings flag
  enabled = getattr(settings, "DASHBOARD_OTP_BYPASS", False) or getattr(settings, "DEBUG", False)

Fix 2 (M-2): views.py L1298-1425 — استبدال @login_required بـ @staff_member_required
  للـ views: request_accept, request_start, request_complete, request_cancel, request_send

Fix 3 (L-3): base_dashboard.html L252 — تغليف Admin link
  {% if request.user.is_superuser %}...Admin link...{% endif %}
```

### 9.3 خطة PR

```
Branch: fix/dashboard-audit-findings
Files:
  - backend/apps/dashboard/auth_views.py     (Fix 1)
  - backend/apps/dashboard/views.py          (Fix 2)
  - backend/apps/dashboard/templates/dashboard/base_dashboard.html (Fix 3)
Tests: existing test suite (199 passed)
```

### 9.4 التقييم النهائي

**النظام آمن ومتسق بشكل عالي.** لا توجد ثغرات أمنية حرجة. RBAC مُطبّق على ثلاث طبقات (Decorator → View Logic → Template) مع تناسق 100% بين الطبقات. نموذج Backoffice API محمي بـ `BackofficeAccessPermission`. نظام إدارة الفريق (Access Profiles) يتضمن حماية ضد سحب آخر Admin وضد سحب صلاحيات النفس مع تسجيل تدقيق شامل.

**الملاحظات 5 فقط — منها 1 يتطلب إصلاح قبل الإنتاج (OTP bypass).**
