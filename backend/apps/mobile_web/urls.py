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
]
