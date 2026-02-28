# Mobile Web Templates

هذه البنية مصممة لمطابقة تدفق تطبيق الموبايل وربطه بنفس نقاط الـ API:

- `auth/login.html` → `/api/accounts/otp/send/`
- `auth/otp.html` → `/api/accounts/otp/verify/`
- `auth/signup.html` → `/api/accounts/complete/` + `/api/accounts/username-availability/`
- `home/index.html` → `/api/providers/categories/` + `/api/providers/list/` + `/api/promo/banners/home/`
- `provider/dashboard.html` → `accounts/providers/reviews/promo/marketplace/subscriptions` APIs

## Static Assets

- CSS: `backend/static/mobile_web/css/`
- JS: `backend/static/mobile_web/js/`
- API Core: `backend/static/mobile_web/js/core/api-client.js`

## Routing

المسارات معرفة في:

- `apps/mobile_web/urls.py`
- ومربوطة في `config/urls.py` تحت `/web/`

