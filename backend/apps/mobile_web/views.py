from django.shortcuts import render


def home_page(request):
    return render(request, "mobile_web/home/index.html")


def login_page(request):
    return render(request, "mobile_web/auth/login.html")


def otp_page(request):
    return render(request, "mobile_web/auth/otp.html")


def signup_page(request):
    return render(request, "mobile_web/auth/signup.html")


def orders_page(request):
    return render(request, "mobile_web/orders/hub.html")


def interactive_page(request):
    return render(request, "mobile_web/interactive/index.html")


def profile_page(request):
    return render(request, "mobile_web/profile/index.html")


def provider_dashboard_page(request):
    return render(request, "mobile_web/provider/dashboard.html")


# ── New pages ──

def notifications_page(request):
    return render(request, "mobile_web/notifications/index.html")


def chats_page(request):
    return render(request, "mobile_web/chats/index.html")


def chat_detail_page(request, thread_id):
    return render(request, "mobile_web/chats/detail.html")


def search_page(request):
    return render(request, "mobile_web/search/index.html")


def provider_profile_page(request, provider_id):
    return render(request, "mobile_web/providers/profile.html")


def settings_page(request):
    return render(request, "mobile_web/settings/index.html")


def plans_page(request):
    return render(request, "mobile_web/plans/index.html")


def about_page(request):
    return render(request, "mobile_web/about/index.html")


def terms_page(request):
    return render(request, "mobile_web/terms/index.html")


def contact_page(request):
    return render(request, "mobile_web/contact/index.html")


# ── Session 3 — Remaining pages ──

def client_orders_page(request):
    return render(request, "mobile_web/orders/client.html")


def provider_orders_page(request):
    return render(request, "mobile_web/orders/provider.html")


def service_detail_page(request, service_id):
    return render(request, "mobile_web/services/detail.html")


def service_request_page(request):
    return render(request, "mobile_web/services/request.html")


def add_service_page(request):
    return render(request, "mobile_web/services/add.html")


def search_providers_page(request):
    return render(request, "mobile_web/search/providers.html")


def provider_services_page(request):
    return render(request, "mobile_web/provider/services.html")


def provider_reviews_page(request):
    return render(request, "mobile_web/provider/reviews.html")


def provider_profile_edit_page(request):
    return render(request, "mobile_web/provider/profile-edit.html")


def promotions_page(request):
    return render(request, "mobile_web/provider/promotions.html")


def verification_page(request):
    return render(request, "mobile_web/verification/index.html")


def notification_settings_page(request):
    return render(request, "mobile_web/settings/notifications.html")


def register_provider_page(request):
    return render(request, "mobile_web/registration/provider.html")


def extras_page(request):
    return render(request, "mobile_web/extras/index.html")


# ── Session 4 — Final 5 pages ──

def client_order_detail_page(request, order_id):
    return render(request, "mobile_web/orders/client-detail.html")


def provider_order_detail_page(request, order_id):
    return render(request, "mobile_web/orders/provider-detail.html")


def request_quote_page(request):
    return render(request, "mobile_web/services/quote.html")


def urgent_request_page(request):
    return render(request, "mobile_web/services/urgent.html")


def complete_profile_page(request):
    return render(request, "mobile_web/provider/complete-profile.html")
