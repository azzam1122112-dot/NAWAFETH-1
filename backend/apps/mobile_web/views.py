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
