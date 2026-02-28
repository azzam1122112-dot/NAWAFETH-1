# 📱 دليل ربط شاشة "نافذتي" بالباكند — مرجع التنفيذ

> **تاريخ الإنشاء:** 2026-02-28  
> **الحالة:** مرجع قبل التنفيذ  
> **الهدف:** ربط شاشة "نافذتي" (العميل + المزود) بالـ Backend APIs وإزالة جميع البيانات الوهمية

---

## 🏗️ البنية الحالية

### التنقل
- الشريط السفلي يحتوي على 4 أزرار: الرئيسية → الطلبات → التفاعلي → **نافذتي**
- الضغط على "نافذتي" يفتح `/profile` → `MyProfileScreen`
- `MyProfileScreen` تتحقق من `SharedPreferences('isProvider')`:
  - **إذا `false`** (عميل) → تعرض واجهة بروفايل العميل
  - **إذا `true`** (مزود) → تعرض `ProviderHomeScreen`

---

## 📋 جدول الشاشات والبيانات الوهمية

### 1. شاشة العميل (`my_profile_screen.dart`)

| العنصر | البيانات الوهمية الحالية | الـ API المطلوب | الحقل في الاستجابة |
|--------|-------------------------|----------------|-------------------|
| اسم المستخدم | `"@xxyyy"` | `GET /api/accounts/me/` | `username` |
| عدد المتابعين | `"245"` | `GET /api/accounts/me/` | `following_count` (من يتابعهم العميل) |
| عدد المتابَعين | `"178"` | `GET /api/accounts/me/` | `following_count` |
| عدد الإعجابات | `"21"` | `GET /api/accounts/me/` | `likes_count` |
| عدد المحفوظات | `"79"` | `GET /api/accounts/me/` | `favorites_media_count` |
| عدد العملاء | `"33"` | غير متاح حالياً (خاص بالمزود) | — |
| صورة البروفايل | صورة افتراضية محلية | `GET /api/accounts/me/` | لا يوجد حقل صورة حالياً (يحتاج إضافة) |
| صورة الغلاف | صورة افتراضية محلية | — | لا يوجد حقل غلاف حالياً (يحتاج إضافة) |
| هل مزود مسجل | `SharedPreferences` | `GET /api/accounts/me/` | `has_provider_profile` |
| هل مزود نشط | `SharedPreferences` | `GET /api/accounts/me/` | `is_provider` |

### 2. شاشة المزود (`provider_dashboard/provider_home_screen.dart`)

| العنصر | البيانات الوهمية الحالية | الـ API المطلوب | الحقل في الاستجابة |
|--------|-------------------------|----------------|-------------------|
| اسم العرض | غير معروض (ثابت) | `GET /api/providers/me/profile/` | `display_name` |
| صورة البروفايل | صورة افتراضية محلية | `GET /api/providers/me/profile/` | `profile_image` |
| صورة الغلاف | صورة افتراضية محلية | `GET /api/providers/me/profile/` | `cover_image` |
| عدد المتابعين | `"542"` | `GET /api/providers/me/followers/` → count أو `/me/profile/` + annotation | `followers_count` |
| عدد المتابَعين (يتابع) | `"98"` | `GET /api/accounts/me/` | `following_count` |
| عدد الإعجابات | `"21"` | `GET /api/accounts/me/` | `likes_count` / `provider_likes_received_count` |
| عدد العملاء | `"33"` | يحتاج endpoint جديد أو حساب من الطلبات | — |
| عدد المحفوظات | `"79"` | `GET /api/accounts/me/` | `favorites_media_count` |
| اسم الباقة | `"الباقة المجانية"` | `GET /api/subscriptions/...` | يحتاج فحص |
| نسبة إكمال الملف | محسوبة محلياً | `GET /api/providers/me/profile/` | يحتاج حساب من الحقول |
| إدارة الطلبات (2 عاجلة / 5 جديدة) | بيانات ثابتة | يحتاج endpoint طلبات المزود | — |

---

## 🔌 الـ Backend APIs المتاحة

### 1. `GET /api/accounts/me/` (مصادقة مطلوبة)
**الاستجابة:**
```json
{
  "id": 1,
  "phone": "0512345678",
  "email": "user@example.com",
  "username": "ahmad123",
  "first_name": "أحمد",
  "last_name": "محمد",
  "role_state": "client",
  "has_provider_profile": true,
  "is_provider": false,
  "following_count": 12,
  "likes_count": 5,
  "favorites_media_count": 8,
  "provider_profile_id": 3,
  "provider_display_name": "أحمد للتصميم",
  "provider_city": "الرياض",
  "provider_followers_count": 25,
  "provider_likes_received_count": 15,
  "provider_rating_avg": "4.50",
  "provider_rating_count": 10
}
```

### 2. `GET /api/providers/me/profile/` (مصادقة مطلوبة — مزود فقط)
**الاستجابة:**
```json
{
  "id": 3,
  "provider_type": "individual",
  "display_name": "أحمد للتصميم",
  "profile_image": "/media/providers/profile/2026/02/photo.jpg",
  "cover_image": "/media/providers/cover/2026/02/cover.jpg",
  "bio": "مصمم محترف",
  "about_details": "...",
  "years_experience": 5,
  "whatsapp": "0512345678",
  "website": "https://example.com",
  "social_links": [],
  "languages": ["ar", "en"],
  "city": "الرياض",
  "lat": "24.774265",
  "lng": "46.738586",
  "coverage_radius_km": 10,
  "qualifications": [],
  "experiences": [],
  "content_sections": [],
  "seo_keywords": "",
  "accepts_urgent": false,
  "is_verified_blue": false,
  "is_verified_green": false,
  "rating_avg": "4.50",
  "rating_count": 10,
  "created_at": "2026-01-15T10:00:00Z"
}
```

### 3. `PATCH /api/accounts/me/` (تحديث بيانات العميل)
### 4. `PATCH /api/providers/me/profile/` (تحديث بيانات المزود)

---

## 🧩 ما ينقص في الموبايل (يجب إنشاؤه)

### طبقة الخدمات (Services Layer)
لا يوجد حالياً أي طبقة خدمات أو HTTP client في التطبيق. يجب إنشاء:

1. **`lib/services/api_client.dart`** — HTTP Client أساسي مع:
   - Base URL قابل للتكوين
   - إضافة `Authorization: Bearer <token>` تلقائياً
   - معالجة الأخطاء
   - تجديد التوكن تلقائياً

2. **`lib/services/auth_service.dart`** — إدارة المصادقة:
   - تخزين/استرجاع التوكنات (`access` + `refresh`)
   - تسجيل الدخول/الخروج
   - التحقق من حالة المصادقة

3. **`lib/services/profile_service.dart`** — خدمات البروفايل:
   - جلب بيانات المستخدم (`/api/accounts/me/`)
   - جلب بيانات المزود (`/api/providers/me/profile/`)
   - تحديث البيانات

4. **`lib/models/user_profile.dart`** — نموذج بيانات المستخدم

5. **`lib/models/provider_profile.dart`** — نموذج بيانات المزود

---

## 📐 خطة التنفيذ التفصيلية

### المرحلة 1: البنية التحتية (Infrastructure)

#### الخطوة 1.1 — إضافة مكتبة `http` للـ `pubspec.yaml`
```yaml
dependencies:
  http: ^1.2.0
```

#### الخطوة 1.2 — إنشاء `lib/services/api_client.dart`
```
ApiClient:
  - baseUrl: String (من env أو ثابت)
  - _getToken(): يقرأ access_token من SharedPreferences
  - get(path): GET مع headers المصادقة
  - post(path, body): POST مع headers المصادقة
  - patch(path, body): PATCH مع headers المصادقة
  - _refreshToken(): يجدد التوكن عبر /api/accounts/token/refresh/
```

#### الخطوة 1.3 — إنشاء `lib/services/auth_service.dart`
```
AuthService:
  - saveTokens(access, refresh): حفظ في SharedPreferences
  - getAccessToken(): استرجاع access token
  - getRefreshToken(): استرجاع refresh token
  - isLoggedIn(): هل يوجد توكن صالح
  - logout(): مسح التوكنات
  - getUserData(): استرجاع /me/ المخزنة محلياً
```

### المرحلة 2: النماذج (Models)

#### الخطوة 2.1 — إنشاء `lib/models/user_profile.dart`
```dart
class UserProfile {
  final int id;
  final String phone;
  final String? email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String roleState;
  final bool hasProviderProfile;
  final bool isProvider;
  final int followingCount;
  final int likesCount;
  final int favoritesMediaCount;
  final int? providerProfileId;
  final String? providerDisplayName;
  final String? providerCity;
  final int providerFollowersCount;
  final int providerLikesReceivedCount;
  final double? providerRatingAvg;
  final int providerRatingCount;
}
```

#### الخطوة 2.2 — إنشاء `lib/models/provider_profile.dart`
```dart
class ProviderProfileModel {
  final int id;
  final String providerType;
  final String displayName;
  final String? profileImage;
  final String? coverImage;
  final String bio;
  final String? aboutDetails;
  final int yearsExperience;
  final String? whatsapp;
  final String? website;
  final List<dynamic> socialLinks;
  final List<dynamic> languages;
  final String city;
  final double? lat;
  final double? lng;
  final int coverageRadiusKm;
  final bool acceptsUrgent;
  final bool isVerifiedBlue;
  final bool isVerifiedGreen;
  final double ratingAvg;
  final int ratingCount;
  final String createdAt;
  // حقول إكمال الملف
  final List<dynamic> qualifications;
  final List<dynamic> experiences;
  final List<dynamic> contentSections;
  final String seoKeywords;
  final String? seoMetaDescription;
  final String? seoSlug;
}
```

### المرحلة 3: ربط شاشة العميل

#### الخطوة 3.1 — تعديل `my_profile_screen.dart`:
1. استدعاء `GET /api/accounts/me/` عند `initState`
2. استبدال `"@xxyyy"` بـ `userProfile.username`
3. استبدال `"245"` بـ `userProfile.followingCount`
4. استبدال `"178"` بـ البيانات الحقيقية
5. استبدال `"33"`, `"21"`, `"79"` بالبيانات الحقيقية
6. استبدال `SharedPreferences('isProvider')` بـ `userProfile.isProvider`
7. استبدال `SharedPreferences('isProviderRegistered')` بـ `userProfile.hasProviderProfile`
8. إضافة مؤشر تحميل (loading state)
9. إضافة معالجة الأخطاء (error state)

#### الخطوة 3.2 — تعديل التبديل بين العميل/المزود:
- حالياً: `SharedPreferences.setBool('isProvider', true/false)`
- الجديد: اعتمادًا على `userProfile.is_provider` و `userProfile.has_provider_profile` من API

### المرحلة 4: ربط شاشة المزود

#### الخطوة 4.1 — تعديل `provider_home_screen.dart`:
1. استدعاء `GET /api/accounts/me/` + `GET /api/providers/me/profile/` عند `initState`
2. استبدال `"542"` (متابعين) بـ `providerProfile.followers_count` أو `meData.provider_followers_count`
3. استبدال `"98"` (يتابع) بـ `meData.following_count`
4. استبدال `"21"` (إعجابات) بـ `meData.provider_likes_received_count`
5. استبدال `"33"` (عملاء) بـ حساب حقيقي أو 0 مؤقتاً
6. استبدال `"79"` (محفوظات) بـ `meData.favorites_media_count`
7. ربط صورة البروفايل والغلاف بـ URLs من الـ API
8. ربط نسبة إكمال الملف بالحقول الحقيقية من الـ API
9. إضافة مؤشر تحميل ومعالجة أخطاء

---

## 🔄 تدفق البيانات (Data Flow)

```
المستخدم يفتح "نافذتي"
       ↓
MyProfileScreen.initState()
       ↓
[1] GET /api/accounts/me/ (مع Bearer token)
       ↓
[2] فحص الاستجابة:
    ├── is_provider == true → عرض ProviderHomeScreen
    │         ↓
    │   [3] GET /api/providers/me/profile/
    │         ↓
    │   [4] عرض بيانات المزود الحقيقية
    │
    └── is_provider == false → عرض واجهة العميل
              ↓
        [3] عرض بيانات العميل الحقيقية
```

---

## ⚠️ ملاحظات مهمة

1. **لا يوجد HTTP Client حالياً** — التطبيق لا يستخدم أي مكتبة HTTP. يجب إضافة `http` في `pubspec.yaml`
2. **التوكنات غير مخزنة** — شاشة الـ Login الحالية وهمية ولا تخزن أي tokens. يجب ربطها بـ OTP flow الحقيقي
3. **بعض البيانات غير متاحة من الـ API** مثل:
   - عدد "العملاء" للمزود (يحتاج endpoint أو aggregation)
   - بيانات الباقة (يحتاج فحص subscriptions API)
   - عدد الطلبات العاجلة/الجديدة (يحتاج unified_requests API)
4. **صور العميل** — حالياً لا يوجد حقل صورة في نموذج `User`. الصور متاحة فقط للمزود في `ProviderProfile`

---

## 📁 الملفات المتأثرة

### ملفات جديدة (تُنشأ):
```
mobile/lib/services/api_client.dart
mobile/lib/services/auth_service.dart
mobile/lib/services/profile_service.dart
mobile/lib/models/user_profile.dart
mobile/lib/models/provider_profile_model.dart
```

### ملفات تُعدّل:
```
mobile/pubspec.yaml                                    — إضافة http dependency
mobile/lib/screens/my_profile_screen.dart              — ربط بيانات العميل
mobile/lib/screens/provider_dashboard/provider_home_screen.dart — ربط بيانات المزود
```

---

## ✅ معايير النجاح

- [ ] لا توجد بيانات وهمية في شاشة نافذتي (عميل + مزود)
- [ ] جميع البيانات تُجلب من الـ API عبر Bearer token
- [ ] مؤشر تحميل يظهر أثناء جلب البيانات
- [ ] رسالة خطأ مناسبة عند فشل الاتصال
- [ ] التبديل بين العميل/المزود يعمل بناءً على بيانات الـ API
- [ ] الصور تُحمّل من URLs الـ API (للمزود)
- [ ] نسبة إكمال الملف تُحسب من الحقول الحقيقية
