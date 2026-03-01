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


class MobileWebNotificationsView(TemplateView):
    template_name = "mobile_web/notifications.html"


class MobileWebChatsView(TemplateView):
    template_name = "mobile_web/chats.html"


class MobileWebChatDetailView(TemplateView):
    template_name = "mobile_web/chat_detail.html"


class MobileWebAddServiceView(TemplateView):
    template_name = "mobile_web/add_service.html"


class MobileWebUrgentRequestView(TemplateView):
    template_name = "mobile_web/urgent_request.html"


class MobileWebRequestQuoteView(TemplateView):
    template_name = "mobile_web/request_quote.html"


class MobileWebSettingsView(TemplateView):
    template_name = "mobile_web/settings.html"
