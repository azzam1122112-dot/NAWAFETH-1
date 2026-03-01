from django.urls import path
from .views import (
    MobileWebHomeView,
    MobileWebLoginView,
    MobileWebSearchView,
    MobileWebOrdersView,
    MobileWebInteractiveView,
    MobileWebProfileView,
    MobileWebProviderDetailView,
    MobileWebNotificationsView,
    MobileWebChatsView,
    MobileWebChatDetailView,
    MobileWebAddServiceView,
    MobileWebUrgentRequestView,
    MobileWebRequestQuoteView,
    MobileWebSettingsView,
)

app_name = "mobile_web"

urlpatterns = [
    path("", MobileWebHomeView.as_view(), name="home"),
    path("login/", MobileWebLoginView.as_view(), name="login"),
    path("search/", MobileWebSearchView.as_view(), name="search"),
    path("orders/", MobileWebOrdersView.as_view(), name="orders"),
    path("interactive/", MobileWebInteractiveView.as_view(), name="interactive"),
    path("profile/", MobileWebProfileView.as_view(), name="profile"),
    path("provider/<int:provider_id>/", MobileWebProviderDetailView.as_view(), name="provider_detail"),
    path("notifications/", MobileWebNotificationsView.as_view(), name="notifications"),
    path("chats/", MobileWebChatsView.as_view(), name="chats"),
    path("chat/<int:thread_id>/", MobileWebChatDetailView.as_view(), name="chat_detail"),
    path("add-service/", MobileWebAddServiceView.as_view(), name="add_service"),
    path("urgent-request/", MobileWebUrgentRequestView.as_view(), name="urgent_request"),
    path("request-quote/", MobileWebRequestQuoteView.as_view(), name="request_quote"),
    path("settings/", MobileWebSettingsView.as_view(), name="settings"),
]
