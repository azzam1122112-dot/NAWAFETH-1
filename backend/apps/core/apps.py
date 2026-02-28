from django.apps import AppConfig


class CoreConfig(AppConfig):
    name = "apps.core"
    verbose_name = "النواة المشتركة"

    _admin_arabic_ready = False

    def ready(self):
        # Avoid duplicate initialization during dev autoreload.
        if self.__class__._admin_arabic_ready:
            return
        from .admin_localization import apply_admin_arabic_localization

        apply_admin_arabic_localization()
        self.__class__._admin_arabic_ready = True
