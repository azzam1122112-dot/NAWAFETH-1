import pytest
from rest_framework.test import APIClient

from apps.accounts.models import OTP


def _login_via_otp(client: APIClient, phone: str) -> str:
    send = client.post("/api/accounts/otp/send/", {"phone": phone}, format="json")
    assert send.status_code == 200
    payload = send.json()
    code = payload.get("dev_code") or OTP.objects.filter(phone=phone).order_by("-id").values_list("code", flat=True).first()
    assert code

    verify = client.post("/api/accounts/otp/verify/", {"phone": phone, "code": code}, format="json")
    assert verify.status_code == 200
    return verify.json()["access"]


def _complete_registration(client: APIClient, username: str, email_seed: str) -> None:
    res = client.post(
        "/api/accounts/complete/",
        {
            "first_name": "Test",
            "last_name": "User",
            "username": username,
            "email": f"{email_seed}@example.com",
            "password": "StrongPass123!",
            "password_confirm": "StrongPass123!",
            "accept_terms": True,
            "city": "الرياض",
        },
        format="json",
    )
    assert res.status_code == 200


@pytest.mark.django_db
def test_username_availability_endpoint_reports_available():
    client = APIClient()
    res = client.get("/api/accounts/username-availability/?username=modern_user_2026")
    assert res.status_code == 200
    body = res.json()
    assert body["available"] is True


@pytest.mark.django_db
def test_username_availability_reports_reserved_and_complete_rejects_duplicate():
    owner_client = APIClient()
    owner_access = _login_via_otp(owner_client, "0500000911")
    owner_client.credentials(HTTP_AUTHORIZATION=f"Bearer {owner_access}")
    _complete_registration(owner_client, "reserved_name", "owner")

    public_client = APIClient()
    check = public_client.get("/api/accounts/username-availability/?username=reserved_name")
    assert check.status_code == 200
    assert check.json()["available"] is False

    other_client = APIClient()
    other_access = _login_via_otp(other_client, "0500000912")
    other_client.credentials(HTTP_AUTHORIZATION=f"Bearer {other_access}")
    fail = other_client.post(
        "/api/accounts/complete/",
        {
            "first_name": "Another",
            "last_name": "User",
            "username": "reserved_name",
            "email": "other@example.com",
            "password": "StrongPass123!",
            "password_confirm": "StrongPass123!",
            "accept_terms": True,
            "city": "جدة",
        },
        format="json",
    )
    assert fail.status_code == 400
    assert "username" in fail.json()
