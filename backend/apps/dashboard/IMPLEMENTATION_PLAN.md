# Dashboard Gap & Plan

## الموجود الآن (مختصر)
- تطبيق `dashboard` يحتوي مسارات تشغيل رئيسية كاملة تقريبًا: Support / Content / Promo / Verification / Subscriptions / Extras / Access Profiles / Home.
- RBAC موجود عبر `_dashboard_allowed()` و decorator حالي داخل `views.py`.
- OTP gating موجود عبر `dashboard_login_required` + session key `SESSION_OTP_VERIFIED_KEY`.
- أغلب القوائم فيها فلترة GET + Pagination + Export (CSV/XLSX/PDF).
- توجد اختبارات جيدة بالفعل لـ RBAC وAccess Profiles وExports وبعض صفحات التشغيل.

## الفجوات قبل التحسين
- لا يوجد اسم decorator الموحّد المطلوب `require_dashboard_access` (الموجود `dashboard_access_required` فقط).
- لا يوجد logging موحّد عام لكل write actions على مستوى الحماية.
- تصدير CSV لا يطبّق حماية CSV Injection مركزيًا.
- `dashboard_home` لا يحتوي فلتر تاريخ واضح للمؤشرات.
- سلوك OTP dashboard يسمح بأي 4 أرقام (مطلوب تطويريًا)، لكنه يحتاج توثيق واضح وتحذير Logging عند تفعيله مع `DEBUG=False`.
- تغطية الاختبارات كانت ناقصة لبعض السيناريوهات (QA readonly POST / OTP gating / CSV injection).

## خطة التنفيذ (Milestones)
1. **Cleanup + RBAC**
   - إضافة `require_dashboard_access(dashboard_key, write=False)`.
   - إبقاء `dashboard_access_required` كـ alias (متوافق خلفيًا).
   - إضافة logging موحّد لطلبات الكتابة داخل decorator.

2. **Exports & Filters Hardening**
   - حماية CSV Injection مركزيًا داخل `_csv_response()`.
   - الحفاظ على الفلاتر الحالية ومراجعة النواقص دون كسر الروابط/القوالب.

3. **Home Analytics**
   - إضافة فلتر `date_from/date_to` في `dashboard_home`.
   - تطبيق النطاق الزمني على KPIs الطلبات والطلبات الموحّدة والرسوم البيانية.

4. **Tests + Docs**
   - إضافة اختبارات RBAC/OTP/CSV/home.
   - إضافة README + CHANGELOG.

## ملاحظات هيكلية مهمة
- **Client Portal** موجود خارج تطبيق `dashboard` داخل `backend/apps/extras_portal/` (Portal منفصل)، لذلك تم توثيقه فقط ولم يتم دمجه قسرًا.

## ما تم إنجازه (بعد التنفيذ)
- إضافة alias decorator + logging write access.
- حماية CSV Injection مركزيًا.
- إضافة فلتر تاريخ لـ Home Analytics مع متغيرات جاهزة للقالب.
- توثيق OTP dev-only + تحذير logging عند `DEBUG=False`.
- إضافة اختبارات جديدة للفجوات الأساسية.
