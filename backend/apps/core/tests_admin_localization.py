from django.http import HttpResponse
from django.test import RequestFactory, SimpleTestCase
from django.utils import translation

from apps.accounts.models import User
from apps.core.admin_localization import apply_admin_arabic_localization
from apps.core.admin_middleware import AdminArabicLocaleMiddleware
from apps.providers.models import ProviderProfile


class AdminArabicLocaleMiddlewareTests(SimpleTestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.middleware = AdminArabicLocaleMiddleware(
            lambda request: HttpResponse(getattr(request, "LANGUAGE_CODE", ""))
        )

    def tearDown(self):
        translation.deactivate_all()

    def test_admin_path_forces_arabic(self):
        translation.activate("en")
        response = self.middleware(self.factory.get("/admin-panel/"))
        self.assertEqual(response.content.decode("utf-8"), "ar")
        self.assertTrue((translation.get_language() or "").startswith("en"))

    def test_non_admin_path_keeps_language(self):
        translation.activate("en")
        response = self.middleware(self.factory.get("/api/accounts/me/"))
        self.assertEqual(response.content.decode("utf-8"), "")
        self.assertTrue((translation.get_language() or "").startswith("en"))


class AdminLocalizationTests(SimpleTestCase):
    def test_model_and_field_labels_are_arabized(self):
        apply_admin_arabic_localization()

        self.assertEqual(str(ProviderProfile._meta.verbose_name), "ملف مقدم الخدمة")
        self.assertEqual(str(ProviderProfile._meta.get_field("display_name").verbose_name), "اسم العرض")
        self.assertEqual(str(User._meta.get_field("created_at").verbose_name), "تاريخ الإنشاء")
