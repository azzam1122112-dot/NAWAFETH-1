from django.views.generic import TemplateView


class MobileWebHomeView(TemplateView):
    """
    Serves the mobile-web home page shell.
    All data is fetched client-side via API — no server-side data injection.
    """
    template_name = "mobile_web/home.html"


class MobileWebLoginView(TemplateView):
    template_name = "mobile_web/login.html"


class MobileWebSearchView(TemplateView):
    template_name = "mobile_web/search.html"


class MobileWebOrdersView(TemplateView):
    template_name = "mobile_web/orders.html"


class MobileWebInteractiveView(TemplateView):
    template_name = "mobile_web/interactive.html"


class MobileWebProfileView(TemplateView):
    template_name = "mobile_web/profile.html"


class MobileWebProviderDetailView(TemplateView):
    template_name = "mobile_web/provider_detail.html"
