from django.urls import path

from . import views

app_name = "mobile_web"

urlpatterns = [
    path("", views.home_page, name="home"),
    path("auth/login/", views.login_page, name="login"),
    path("auth/otp/", views.otp_page, name="otp"),
    path("auth/signup/", views.signup_page, name="signup"),
    path("orders/", views.orders_page, name="orders"),
    path("interactive/", views.interactive_page, name="interactive"),
    path("profile/", views.profile_page, name="profile"),
    path("provider/dashboard/", views.provider_dashboard_page, name="provider_dashboard"),
    # ── New pages ──
    path("notifications/", views.notifications_page, name="notifications"),
    path("chats/", views.chats_page, name="chats"),
    path("chats/<int:thread_id>/", views.chat_detail_page, name="chat_detail"),
    path("search/", views.search_page, name="search"),
    path("providers/<int:provider_id>/", views.provider_profile_page, name="provider_profile"),
    path("settings/", views.settings_page, name="settings"),
    path("plans/", views.plans_page, name="plans"),
    path("about/", views.about_page, name="about"),
    path("terms/", views.terms_page, name="terms"),
    path("contact/", views.contact_page, name="contact"),
    # ── Session 3 — Remaining pages ──
    path("orders/client/", views.client_orders_page, name="client_orders"),
    path("orders/provider/", views.provider_orders_page, name="provider_orders"),
    path("services/<int:service_id>/", views.service_detail_page, name="service_detail"),
    path("services/request/", views.service_request_page, name="service_request"),
    path("services/add/", views.add_service_page, name="add_service"),
    path("search/providers/", views.search_providers_page, name="search_providers"),
    path("provider/services/", views.provider_services_page, name="provider_services"),
    path("provider/reviews/", views.provider_reviews_page, name="provider_reviews"),
    path("provider/profile-edit/", views.provider_profile_edit_page, name="provider_profile_edit"),
    path("provider/promotions/", views.promotions_page, name="promotions"),
    path("verification/", views.verification_page, name="verification"),
    path("settings/notifications/", views.notification_settings_page, name="notification_settings"),
    path("register-provider/", views.register_provider_page, name="register_provider"),
    path("extras/", views.extras_page, name="extras"),
]
