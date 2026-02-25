# تقرير المطابقة والتوافق (Flutter Mobile/Web ↔ Django Backend)

تاريخ التقرير: 2026-02-25

## 1) صورة عامة سريعة
### مكونات المشروع
- **Backend (Django + DRF)**: واجهات REST تحت `/api/*` + صفحات منصة HTML تحت `/dashboard/` + بوابة خدمات إضافية تحت `/portal/extras/`.
- **Flutter Mobile**: تطبيق موبايل رئيسي (routes في `mobile/lib/main.dart`).
- **Flutter Web**: واجهة ويب من نفس كود Flutter (routes في `mobile/lib/main_web.dart`) ومخصصة للمستخدمين فقط (العميل + مقدم الخدمة):
  - `/client_dashboard/*`
  - `/provider_dashboard/*`

### ملاحظة مهمة عن "الويب"
عندك نوعين ويب مختلفين:
1) **Django Web Dashboard**: صفحات HTML للمنصة (إدارية/تشغيلية) تحت `/dashboard/`.
2) **Flutter Web**: تطبيق ويب مبني بفلتر، يعتمد على REST APIs.

وبحسب قرار النطاق الحالي: **Flutter Web للمستخدمين (Client/Provider) فقط**، و**لوحة المنصة/التشغيل تبقى في Django Dashboard**.

---

## 2) الربط مع الـ API (Base URL + Prefix)
- في Flutter يتم بناء المسارات عبر:
  - `ApiConfig.baseUrl` (مثال افتراضي: Render)
  - `ApiConfig.apiPrefix = '/api'`

أي endpoint في الباكند مثل: `/api/support/teams/` يتم استدعاؤه من Flutter كالتالي:
- `${ApiConfig.apiPrefix}/support/teams/`

---

## 3) CORS (أهم نقطة لنجاح Flutter Web)
- الباكند يستخدم `django-cors-headers`.
- في `backend/config/settings/base.py` يوجد `CORS_ALLOW_ALL_ORIGINS` مبني على env (`CORS_ALLOW_ALL`)، وفي `prod.py` يتم جعله `False` مع `CORS_ALLOWED_ORIGINS`.

**النتيجة العملية**:
- Flutter Mobile عادة لا يتأثر بـ CORS.
- Flutter Web سيتأثر مباشرة: يجب ضبط `DJANGO_CORS_ALLOWED_ORIGINS` (أو `CORS_ALLOWED_ORIGINS` حسب إعداداتك) ليشمل دومين Flutter Web.

---

## 4) مصفوفة مطابقة عالية المستوى حسب الشخصية (Persona)

### أ) العميل (Client)
- Flutter Mobile: موجود (Home/Orders/Profile/Notifications/Chat…)
- Flutter Web: موجود تحت `/client_dashboard/*`
- Backend API: موجود تحت `/api/marketplace/*`, `/api/messaging/*`, `/api/support/*`, `/api/promo/*`…

**ملاحظات**:
- دعم التذاكر للعميل: `/api/support/tickets/my/`, `/api/support/tickets/create/`.
- طلبات الترويج للعميل: `/api/promo/requests/my/`, `/api/promo/requests/create/`.

### ب) مقدم الخدمة (Provider)
- Flutter Mobile: موجود
- Flutter Web: موجود تحت `/provider_dashboard/*` (طلبات/خدمات/تقييمات/إشعارات/ملف)
- Backend API: موجود تحت `/api/providers/*`, `/api/reviews/*`, `/api/marketplace/*`…

### ج) التشغيل (Operations / Staff)
- Django Dashboard: تغطية واسعة جدًا (Support, Promo, Verification, Subscriptions, Billing, Content, Categories…)
- Flutter Web: **غير مستهدف في هذا النطاق** للتشغيل/الموظفين (لا يتم تعريض مسارات Operations على الويب).

### د) لوحة المنصة (Admin Dashboard)
- Django Dashboard تحت `/dashboard/` يحتوي مسارات كثيرة جدًا (راجع `backend/apps/dashboard/urls.py`).
- Flutter Web لا يغطي غالب هذه المسارات حتى الآن.

---

## 5) فجوات مطابقة واضحة (Backlog مرتب)

### فجوة 1: تغطية وحدات المنصة (Dashboard) داخل Flutter Web
بناءً على قرار النطاق الحالي: **هذه ليست فجوة مطلوبة الآن** لأن التشغيل/المنصة على الويب يتم عبر Django Dashboard تحت `/dashboard/`.

### فجوة 2: Status labels/filters في Promotions
في الباكند statuses للترويج:
- `new`, `in_review`, `quoted`, `pending_payment`, `active`, `rejected`, ...

في Flutter Web كانت فلترة UI تستخدم مفاهيم مثل `approved/pending/rejected`.
- تم توسيع المطابقة بالمنطق (بدون تغيير مسميات الواجهة) لتشمل `active/in_review/new/...`.
- قد تحتاج لاحقًا توحيد مسميات الفلاتر لتكون 1:1 مع `PromoRequestStatus`.

### فجوة 3: الربط بين Flutter و Django Dashboard
في Flutter يوجد فتح خارجي لـ `${ApiConfig.baseUrl}/dashboard/` بدل دمج/استبدال.
- هذا لا يعتبر "تكامل" بقدر ما هو "تحويل لصفحات خارجية".

---

## 6) تغييرات تم تطبيقها لتحسين التوافق (بدون تغيير UX)

> ملاحظة: التغييرات التالية تم تطبيقها لدعم تكامل backoffice داخل Flutter (تحضيرًا/للاستخدام الداخلي)، لكن **مسارات Operations غير مفعلة على Flutter Web** بحسب قرار النطاق الحالي.

### 6.1 Operations Support (Flutter Web)
- تم تحويل مصدر البيانات من:
  - `/api/support/tickets/my/`
- إلى:
  - `/api/support/backoffice/tickets/`

### 6.2 Operations Promotions (Flutter Web)
- تم تحويل مصدر البيانات من:
  - `/api/promo/requests/my/`
- إلى:
  - `/api/promo/backoffice/requests/`

### 6.3 إضافة backoffice methods في Flutter services
تم إضافة/توسيع خدمات API التالية لتدعم backoffice endpoints:
- `SupportApi`: list backoffice + assign + status
- `PromoApi`: list backoffice + assign + quote + reject
- `VerificationApi`: list backoffice + assign + finalize (تهيئة للمستقبل)

---

## 7) توصيات تنفيذية سريعة (أعلى عائد بأقل مخاطرة)
1) **تثبيت نطاق الويب**: Flutter Web للمستخدمين (Client/Provider) فقط، وعمليات المنصة عبر Django Dashboard.
2) **تثبيت CORS للـ Flutter Web** في بيئة الإنتاج عبر `DJANGO_CORS_ALLOWED_ORIGINS`.
3) **تقليل التداخل**: أي روابط/تحويلات تخص `/dashboard/` تبقى للأدوار الداخلية فقط.
4) **توحيد statuses/filters** عبر enums أو mapping موحد في Flutter لتفادي اختلاف الفلاتر مع قيم الباكند.

---

## 8) ملاحق
### أهم ملفات مرجعية
- Backend routes: `backend/config/urls.py`
- Dashboard routes: `backend/apps/dashboard/urls.py`
- Flutter Mobile routes: `mobile/lib/main.dart`
- Flutter Web routes: `mobile/lib/main_web.dart`
- Flutter API configs: `mobile/lib/services/api_config.dart`

