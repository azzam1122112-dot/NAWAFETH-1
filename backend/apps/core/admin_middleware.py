from django.utils import translation


class AdminArabicLocaleMiddleware:
    """
    Force Arabic UI for Django admin pages only, without affecting the rest of the app.
    """

    ADMIN_PREFIXES = ("/admin-panel/", "/admin/")

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        path = request.path_info or request.path or ""
        if not path.startswith(self.ADMIN_PREFIXES):
            return self.get_response(request)

        previous_language = translation.get_language()
        translation.activate("ar")
        request.LANGUAGE_CODE = "ar"

        try:
            return self.get_response(request)
        finally:
            if previous_language:
                translation.activate(previous_language)
            else:
                translation.deactivate()
