# Dashboard App Notes

## Scope
- هذا التطبيق (`backend/apps/dashboard/`) هو لوحة التشغيل الداخلية (staff/backoffice dashboard).
- لوحات التشغيل الرئيسية الموجودة هنا تشمل: Home Analytics, Content, Support, Promo, Verification, Subscriptions, Extras Ops, Access Profiles.
- **Client Portal** الخاص بالخدمات الإضافية موجود كتطبيق منفصل في `backend/apps/extras_portal/` وليس ضمن هذا التطبيق.

## OTP (Dashboard Login) - Dev Behavior Warning
- تسجيل دخول الداشبورد يستخدم OTP gating عبر session key: `SESSION_OTP_VERIFIED_KEY`.
- **سلوك التطوير الحالي (Dev-only):** الداشبورد يقبل **أي 4 أرقام** في صفحة OTP.
- هذا السلوك مقصود حاليًا لتسريع التطوير/الاختبار، ولم يتم تغييره هنا بناءً على المتطلبات.
- تمت إضافة **warning log** إذا كان bypass فعالًا بينما `DEBUG=False` حتى يظهر بوضوح في السجلات.

## RBAC
- الحماية تعتمد على:
  - `dashboard_login_required` (auth + staff + OTP session)
  - `require_dashboard_access(dashboard_key, write=False)` (صلاحية اللوحة + readonly/write)
- تم الإبقاء على `dashboard_access_required` كـ alias متوافق خلفيًا.

## Exports
- تصدير CSV محمي مركزيًا ضد CSV Injection:
  - أي قيمة تبدأ بـ `=`, `+`, `-`, `@` يتم prefix لها بـ `'`.

## Testing
- اختبارات الداشبورد موجودة في `backend/apps/dashboard/tests.py` و`backend/apps/dashboard/tests/`.
- شغّل:
  - `pytest backend/apps/dashboard/tests.py -q`
