import pytest
from rest_framework.test import APIClient

from apps.accounts.models import OTP, User


def _login_via_otp(client: APIClient, phone: str) -> dict:
    send = client.post("/api/accounts/otp/send/", {"phone": phone}, format="json")
    assert send.status_code == 200
    payload = send.json()
    code = payload.get("dev_code") or OTP.objects.filter(phone=phone).order_by("-id").values_list("code", flat=True).first()
    assert code

    verify = client.post("/api/accounts/otp/verify/", {"phone": phone, "code": code}, format="json")
    assert verify.status_code == 200
    return verify.json()


@pytest.mark.django_db
def test_delete_account_allows_fresh_registration_with_same_phone(settings):
    settings.OTP_COOLDOWN_SECONDS = 0

    client = APIClient()
    phone = "0500000911"

    first_login = _login_via_otp(client, phone)
    first_user_id = first_login["user_id"]
    first_access = first_login["access"]

    user_before_delete = User.objects.get(id=first_user_id)
    assert user_before_delete.phone == phone
    assert user_before_delete.is_active is True

    client.credentials(HTTP_AUTHORIZATION=f"Bearer {first_access}")
    delete_res = client.delete("/api/accounts/delete/")
    assert delete_res.status_code == 200

    assert not User.objects.filter(id=first_user_id).exists()

    client.credentials()
    second_login = _login_via_otp(client, phone)
    second_user_id = second_login["user_id"]

    assert second_user_id != first_user_id
    assert User.objects.filter(id=second_user_id, phone=phone, is_active=True).exists()
