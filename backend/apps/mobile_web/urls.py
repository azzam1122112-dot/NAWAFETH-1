from django.urls import path
from .views import (
    MobileWebHomeView,
    MobileWebLoginView,
    MobileWebSearchView,
    MobileWebOrdersView,
    MobileWebInteractiveView,
    MobileWebProfileView,
    MobileWebProviderDetailView,
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
]
