"""
Final RBAC & Horizontal Access Audit Tests
===========================================
Tests that prove:
1. Team-scoped staff cannot access other teams' dashboards via direct URL.
2. QA users can read but never POST (write).
3. Object-level (IDOR) checks prevent accessing objects assigned to others.
4. Backoffice API enforces QA read-only.

OTP is NOT modified — tests use the existing dev-mode accept-any-4-digits flow.
"""
from __future__ import annotations

import pytest
from django.test import Client
from django.urls import reverse
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.backoffice.models import AccessLevel, Dashboard, UserAccessProfile
from apps.billing.models import Invoice
from apps.dashboard.auth import SESSION_OTP_VERIFIED_KEY
from apps.marketplace.models import RequestStatus, ServiceRequest
from apps.promo.models import PromoAdType, PromoRequest, PromoRequestStatus
from apps.providers.models import Category, ProviderProfile, SubCategory
from apps.support.models import (
    SupportPriority,
    SupportTeam,
    SupportTicket,
    SupportTicketStatus,
    SupportTicketType,
)
from apps.subscriptions.models import Subscription, SubscriptionPlan, SubscriptionStatus
from apps.extras.models import ExtraPurchase, ExtraPurchaseStatus
from apps.unified_requests.models import UnifiedRequest, UnifiedRequestStatus

pytestmark = pytest.mark.django_db

# ─── Helpers ────────────────────────────────────────────────────

PHONE_SEQ = iter(range(5550000000, 5559999999))


def _next_phone() -> str:
    return f"0{next(PHONE_SEQ)}"


def _ensure_dashboards(*codes: str) -> dict[str, Dashboard]:
    out = {}
    for i, code in enumerate(codes, start=1):
        d, _ = Dashboard.objects.get_or_create(
            code=code, defaults={"name_ar": code, "sort_order": i}
        )
        out[code] = d
    return out


def _make_staff(
    level: str,
    dashboards: list[str],
) -> tuple[User, Client]:
    """Create a staff user with given level & dashboard list, return (user, logged-in Client)."""
    phone = _next_phone()
    user = User.objects.create_user(phone=phone, password="Pass12345!", is_staff=True)
    dbs = _ensure_dashboards(*dashboards)
    ap = UserAccessProfile.objects.create(user=user, level=level)
    ap.allowed_dashboards.set(dbs.values())
    c = Client()
    assert c.login(phone=phone, password="Pass12345!")
    s = c.session
    s[SESSION_OTP_VERIFIED_KEY] = True
    s.save()
    return user, c


def _make_service_request() -> ServiceRequest:
    cat, _ = Category.objects.get_or_create(name="تصميم", defaults={"is_active": True})
    sub, _ = SubCategory.objects.get_or_create(
        name="شعارات", category=cat, defaults={"is_active": True}
    )
    client_user = User.objects.create_user(phone=_next_phone())
    return ServiceRequest.objects.create(
        client=client_user,
        subcategory=sub,
        title="طلب",
        description="وصف",
        request_type="competitive",
        status=RequestStatus.NEW,
        city="الرياض",
    )


def _make_support_ticket(ticket_type: str = SupportTicketType.TECH, assigned_to=None) -> SupportTicket:
    requester = User.objects.create_user(phone=_next_phone())
    team, _ = SupportTeam.objects.get_or_create(
        code="support", defaults={"name_ar": "الدعم", "is_active": True, "sort_order": 1}
    )
    return SupportTicket.objects.create(
        requester=requester,
        ticket_type=ticket_type,
        status=SupportTicketStatus.NEW,
        priority=SupportPriority.NORMAL,
        description="تذكرة اختبار",
        assigned_team=team,
        assigned_to=assigned_to,
    )


def _make_promo_ticket(assigned_to=None) -> SupportTicket:
    return _make_support_ticket(ticket_type=SupportTicketType.ADS, assigned_to=assigned_to)


def _make_verification_ticket(assigned_to=None) -> SupportTicket:
    return _make_support_ticket(ticket_type=SupportTicketType.VERIFY, assigned_to=assigned_to)


def _make_subs_ticket(assigned_to=None) -> SupportTicket:
    return _make_support_ticket(ticket_type=SupportTicketType.SUBS, assigned_to=assigned_to)


def _make_subscription() -> Subscription:
    requester = User.objects.create_user(phone=_next_phone())
    plan, _ = SubscriptionPlan.objects.get_or_create(
        code="TEST_PLAN",
        defaults={"title": "اختبار", "period": "year", "price": "100.00", "is_active": True},
    )
    invoice = Invoice.objects.create(
        user=requester, title="فاتورة", subtotal="100.00",
        reference_type="subscription", reference_id="0",
    )
    return Subscription.objects.create(
        user=requester, plan=plan,
        status=SubscriptionStatus.PENDING_PAYMENT,
        invoice=invoice,
    )


def _make_promo_request() -> PromoRequest:
    from django.utils import timezone
    requester = User.objects.create_user(phone=_next_phone())
    now = timezone.now()
    return PromoRequest.objects.create(
        requester=requester,
        title="إعلان اختبار",
        ad_type=PromoAdType.BANNER_HOME,
        start_at=now,
        end_at=now + timezone.timedelta(days=30),
        status=PromoRequestStatus.NEW,
    )


def _make_extras_purchase() -> ExtraPurchase:
    requester = User.objects.create_user(phone=_next_phone())
    return ExtraPurchase.objects.create(
        user=requester,
        sku="test_extra",
        title="إضافة اختبار",
        extra_type="time_based",
        subtotal="50.00",
        status=ExtraPurchaseStatus.PENDING_PAYMENT,
    )


# ═══════════════════════════════════════════════════════════════
# 1) Horizontal Privilege Escalation — team cannot reach other teams
# ═══════════════════════════════════════════════════════════════

# Each row: (actor_dashboards, forbidden_url_name, url_kwargs)
_HORIZONTAL_MATRIX = [
    # support → cannot reach promo, billing, verify, subs, extras, access, content pages
    (["support"], "promo_requests_list", {}),
    (["support"], "promo_inquiries_list", {}),
    (["support"], "billing_invoices_list", {}),
    (["support"], "verification_requests_list", {}),
    (["support"], "subscriptions_list", {}),
    (["support"], "extras_list", {}),
    (["support"], "access_profiles_list", {}),
    (["support"], "content_management", {}),
    # promo → cannot reach support, billing, verify, subs, extras, access
    (["promo"], "support_tickets_list", {}),
    (["promo"], "billing_invoices_list", {}),
    (["promo"], "verification_requests_list", {}),
    (["promo"], "subscriptions_list", {}),
    (["promo"], "extras_list", {}),
    (["promo"], "access_profiles_list", {}),
    # content → cannot reach support, promo, billing, verify, subs, extras, access
    (["content"], "support_tickets_list", {}),
    (["content"], "promo_requests_list", {}),
    (["content"], "billing_invoices_list", {}),
    (["content"], "verification_requests_list", {}),
    (["content"], "subscriptions_list", {}),
    (["content"], "extras_list", {}),
    (["content"], "access_profiles_list", {}),
    # billing → cannot reach support, promo, verify, subs, extras, access, content
    (["billing"], "support_tickets_list", {}),
    (["billing"], "promo_requests_list", {}),
    (["billing"], "verification_requests_list", {}),
    (["billing"], "subscriptions_list", {}),
    (["billing"], "extras_list", {}),
    (["billing"], "access_profiles_list", {}),
    (["billing"], "content_management", {}),
    # verify → cannot reach support, promo, billing, subs, extras, access
    (["verify"], "support_tickets_list", {}),
    (["verify"], "promo_requests_list", {}),
    (["verify"], "billing_invoices_list", {}),
    (["verify"], "subscriptions_list", {}),
    (["verify"], "extras_list", {}),
    (["verify"], "access_profiles_list", {}),
    # subs → cannot reach support, promo, billing, verify, extras, access
    (["subs"], "support_tickets_list", {}),
    (["subs"], "promo_requests_list", {}),
    (["subs"], "billing_invoices_list", {}),
    (["subs"], "verification_requests_list", {}),
    (["subs"], "extras_list", {}),
    (["subs"], "access_profiles_list", {}),
    # extras → cannot reach support, promo, billing, verify, subs, access
    (["extras"], "support_tickets_list", {}),
    (["extras"], "promo_requests_list", {}),
    (["extras"], "billing_invoices_list", {}),
    (["extras"], "verification_requests_list", {}),
    (["extras"], "subscriptions_list", {}),
    (["extras"], "access_profiles_list", {}),
]


@pytest.mark.parametrize(
    "actor_dashboards,forbidden_url,kwargs",
    _HORIZONTAL_MATRIX,
    ids=[
        f"{'_'.join(d)}_denied_{u}" for d, u, _ in _HORIZONTAL_MATRIX
    ],
)
def test_horizontal_access_denied(actor_dashboards, forbidden_url, kwargs):
    """Each team user must be denied (302 redirect or 403) when accessing another team's page."""
    _user, client = _make_staff(AccessLevel.USER, actor_dashboards)
    url = reverse(f"dashboard:{forbidden_url}", kwargs=kwargs)
    res = client.get(url)
    # The decorator either redirects to an allowed dashboard or returns 403
    assert res.status_code in (302, 403), (
        f"Expected 302/403, got {res.status_code} for {actor_dashboards} → {forbidden_url}"
    )
    if res.status_code == 302:
        # Must NOT redirect back to the same forbidden URL
        assert url not in res["Location"]


# ═══════════════════════════════════════════════════════════════
# 2) QA Read-Only Enforcement
# ═══════════════════════════════════════════════════════════════

class TestQAReadOnly:
    """QA can GET list/detail pages but never POST write actions."""

    def _qa(self, dashboards: list[str]) -> tuple[User, Client]:
        return _make_staff(AccessLevel.QA, dashboards)

    def test_qa_can_read_support_list(self):
        _user, c = self._qa(["support"])
        res = c.get(reverse("dashboard:support_tickets_list"))
        assert res.status_code == 200

    def test_qa_denied_support_assign_post(self):
        _user, c = self._qa(["support"])
        ticket = _make_support_ticket()
        res = c.post(
            reverse("dashboard:support_ticket_assign_action", args=[ticket.id]),
            data={"assigned_to": "1"},
        )
        assert res.status_code in (302, 403)
        ticket.refresh_from_db()
        assert ticket.assigned_to_id is None

    def test_qa_denied_support_status_post(self):
        _user, c = self._qa(["support"])
        ticket = _make_support_ticket()
        res = c.post(
            reverse("dashboard:support_ticket_status_action", args=[ticket.id]),
            data={"status": SupportTicketStatus.IN_PROGRESS},
        )
        assert res.status_code in (302, 403)
        ticket.refresh_from_db()
        assert ticket.status == SupportTicketStatus.NEW

    def test_qa_can_read_promo_list(self):
        _user, c = self._qa(["promo"])
        res = c.get(reverse("dashboard:promo_requests_list"))
        assert res.status_code == 200

    def test_qa_denied_promo_reject_post(self):
        _user, c = self._qa(["promo"])
        pr = _make_promo_request()
        res = c.post(reverse("dashboard:promo_reject_action", args=[pr.id]))
        assert res.status_code in (302, 403)
        pr.refresh_from_db()
        assert pr.status == PromoRequestStatus.NEW

    def test_qa_can_read_billing_list(self):
        _user, c = self._qa(["billing"])
        res = c.get(reverse("dashboard:billing_invoices_list"))
        assert res.status_code == 200

    def test_qa_denied_billing_set_status_post(self):
        _user, c = self._qa(["billing"])
        requester = User.objects.create_user(phone=_next_phone())
        invoice = Invoice.objects.create(
            user=requester, title="Test", subtotal="10.00",
            reference_type="test", reference_id="1",
        )
        res = c.post(
            reverse("dashboard:billing_invoice_set_status_action", args=[invoice.id]),
            data={"status": "paid"},
        )
        assert res.status_code in (302, 403)
        invoice.refresh_from_db()
        assert invoice.status != "paid"

    def test_qa_can_read_subs_list(self):
        _user, c = self._qa(["subs"])
        res = c.get(reverse("dashboard:subscriptions_list"))
        assert res.status_code == 200

    def test_qa_denied_subs_refresh_post(self):
        _user, c = self._qa(["subs"])
        sub = _make_subscription()
        res = c.post(reverse("dashboard:subscription_refresh_action", args=[sub.id]))
        assert res.status_code in (302, 403)

    def test_qa_can_read_content_management(self):
        _user, c = self._qa(["content"])
        res = c.get(reverse("dashboard:content_management"))
        assert res.status_code == 200

    def test_qa_denied_content_links_update(self):
        _user, c = self._qa(["content"])
        from apps.content.models import SiteLinks
        res = c.post(
            reverse("dashboard:content_links_update_action"),
            data={"x_url": "https://test.com"},
        )
        assert res.status_code in (302, 403)
        assert SiteLinks.objects.count() == 0

    def test_qa_can_read_reviews_list(self):
        _user, c = self._qa(["content"])
        res = c.get(reverse("dashboard:reviews_dashboard_list"))
        assert res.status_code == 200

    def test_qa_can_read_extras_list(self):
        _user, c = self._qa(["extras"])
        res = c.get(reverse("dashboard:extras_list"))
        assert res.status_code == 200

    def test_qa_denied_extras_activate_post(self):
        _user, c = self._qa(["extras"])
        purchase = _make_extras_purchase()
        res = c.post(reverse("dashboard:extra_activate_action", args=[purchase.id]))
        assert res.status_code in (302, 403)

    def test_qa_can_read_verification_list(self):
        _user, c = self._qa(["verify"])
        res = c.get(reverse("dashboard:verification_requests_list"))
        assert res.status_code == 200


# ═══════════════════════════════════════════════════════════════
# 3) QA Read-Only on Backoffice API
# ═══════════════════════════════════════════════════════════════

class TestQABackofficeAPI:
    """QA level on backoffice API can GET but not POST/PUT/PATCH/DELETE."""

    def _qa_api(self, dashboards: list[str]) -> tuple[User, APIClient]:
        phone = _next_phone()
        user = User.objects.create_user(phone=phone, password="Pass12345!", is_staff=True)
        dbs = _ensure_dashboards(*dashboards)
        ap = UserAccessProfile.objects.create(user=user, level=AccessLevel.QA)
        ap.allowed_dashboards.set(dbs.values())
        api = APIClient()
        api.force_authenticate(user=user)
        return user, api

    def test_qa_can_get_dashboards_list(self):
        _ensure_dashboards("support")
        _user, api = self._qa_api(["support"])
        res = api.get("/api/backoffice/dashboards/")
        assert res.status_code == 200

    def test_qa_can_get_my_access(self):
        _user, api = self._qa_api(["support"])
        res = api.get("/api/backoffice/me/access/")
        assert res.status_code == 200
        assert res.data["readonly"] is True

    def test_qa_denied_post_on_backoffice(self):
        _user, api = self._qa_api(["support"])
        res = api.post("/api/backoffice/dashboards/", data={})
        # POST not allowed — either 403 (QA) or 405 (method not allowed)
        assert res.status_code in (403, 405)


# ═══════════════════════════════════════════════════════════════
# 4) IDOR — Object-Level Authorization (user-level cannot see others' assigned objects)
# ═══════════════════════════════════════════════════════════════

class TestIDORSupportTicket:
    """user-level support agent cannot view/action a ticket assigned to a different agent."""

    def test_support_detail_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_support_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["support"])
        res = c.get(reverse("dashboard:support_ticket_detail", args=[ticket.id]))
        assert res.status_code == 403

    def test_support_assign_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_support_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["support"])
        res = c.post(
            reverse("dashboard:support_ticket_assign_action", args=[ticket.id]),
            data={"assigned_to": str(_user.id)},
        )
        assert res.status_code == 403

    def test_support_status_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_support_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["support"])
        res = c.post(
            reverse("dashboard:support_ticket_status_action", args=[ticket.id]),
            data={"status": SupportTicketStatus.IN_PROGRESS},
        )
        assert res.status_code == 403

    def test_support_unassigned_ticket_visible(self):
        """Unassigned tickets should be visible to any user-level agent with support access."""
        ticket = _make_support_ticket(assigned_to=None)
        _user, c = _make_staff(AccessLevel.USER, ["support"])
        res = c.get(reverse("dashboard:support_ticket_detail", args=[ticket.id]))
        assert res.status_code == 200


class TestIDORPromoInquiry:
    """user-level promo operator cannot view/action a promo inquiry assigned to someone else."""

    def test_promo_inquiry_detail_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_promo_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["promo"])
        res = c.get(reverse("dashboard:promo_inquiry_detail", args=[ticket.id]))
        assert res.status_code == 403

    def test_promo_assign_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_promo_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["promo"])
        res = c.post(
            reverse("dashboard:promo_assign_action", args=[ticket.id]),
            data={"assigned_to": str(_user.id)},
        )
        assert res.status_code == 403

    def test_promo_inquiry_status_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_promo_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["promo"])
        res = c.post(
            reverse("dashboard:promo_inquiry_status_action", args=[ticket.id]),
            data={"status": SupportTicketStatus.IN_PROGRESS},
        )
        assert res.status_code == 403

    def test_promo_assign_cannot_assign_to_other_user(self):
        """user-level promo operator cannot assign ticket to someone else."""
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_promo_ticket(assigned_to=None)
        _user, c = _make_staff(AccessLevel.USER, ["promo"])
        res = c.post(
            reverse("dashboard:promo_assign_action", args=[ticket.id]),
            data={"assigned_to": str(other_agent.id)},
        )
        assert res.status_code == 403


class TestIDORVerificationInquiry:
    """user-level verification officer cannot view inquiry assigned to another officer."""

    def test_verification_inquiry_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_verification_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["verify"])
        res = c.get(reverse("dashboard:verification_inquiry_detail", args=[ticket.id]))
        assert res.status_code == 403

    def test_verification_inquiry_assign_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_verification_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["verify"])
        res = c.post(
            reverse("dashboard:verification_inquiry_assign_action", args=[ticket.id]),
            data={"assigned_to": str(_user.id)},
        )
        assert res.status_code == 403

    def test_verification_inquiry_status_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        ticket = _make_verification_ticket(assigned_to=other_agent)
        _user, c = _make_staff(AccessLevel.USER, ["verify"])
        res = c.post(
            reverse("dashboard:verification_inquiry_status_action", args=[ticket.id]),
            data={"status": SupportTicketStatus.IN_PROGRESS},
        )
        assert res.status_code == 403


class TestIDORSubscription:
    """user-level subs operator cannot view subscription account of another user."""

    def test_subscription_account_detail_idor_denied(self):
        sub = _make_subscription()
        _user, c = _make_staff(AccessLevel.USER, ["subs"])
        # sub.user != _user, so should be denied
        res = c.get(reverse("dashboard:subscription_account_detail", args=[sub.id]))
        assert res.status_code == 403

    def test_subscription_upgrade_summary_idor_denied(self):
        sub = _make_subscription()
        _user, c = _make_staff(AccessLevel.USER, ["subs"])
        res = c.get(reverse("dashboard:subscription_upgrade_summary", args=[sub.id]))
        assert res.status_code == 403

    def test_subscription_payment_checkout_idor_denied(self):
        sub = _make_subscription()
        _user, c = _make_staff(AccessLevel.USER, ["subs"])
        res = c.get(reverse("dashboard:subscription_payment_checkout", args=[sub.id]))
        assert res.status_code == 403

    def test_subscription_payment_success_idor_denied(self):
        sub = _make_subscription()
        _user, c = _make_staff(AccessLevel.USER, ["subs"])
        res = c.get(reverse("dashboard:subscription_payment_success", args=[sub.id]))
        assert res.status_code == 403


class TestIDORExtrasRequest:
    """user-level extras operator cannot view/action unified request assigned to another user."""

    def test_extras_request_detail_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        requester = User.objects.create_user(phone=_next_phone())
        ur = UnifiedRequest.objects.create(
            request_type="extras",
            requester=requester,
            status=UnifiedRequestStatus.NEW,
            priority="normal",
            source_app="extras",
            source_model="ExtraPurchase",
            source_object_id="999",
            assigned_user=other_agent,
        )
        _user, c = _make_staff(AccessLevel.USER, ["extras"])
        res = c.get(reverse("dashboard:extras_request_detail", args=[ur.id]))
        assert res.status_code == 403

    def test_extras_request_assign_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        requester = User.objects.create_user(phone=_next_phone())
        ur = UnifiedRequest.objects.create(
            request_type="extras",
            requester=requester,
            status=UnifiedRequestStatus.NEW,
            priority="normal",
            source_app="extras",
            source_model="ExtraPurchase",
            source_object_id="998",
            assigned_user=other_agent,
        )
        _user, c = _make_staff(AccessLevel.USER, ["extras"])
        res = c.post(
            reverse("dashboard:extras_request_assign_action", args=[ur.id]),
            data={"assigned_to": str(_user.id)},
        )
        assert res.status_code == 403

    def test_extras_request_status_idor_denied(self):
        other_agent = User.objects.create_user(phone=_next_phone(), is_staff=True)
        requester = User.objects.create_user(phone=_next_phone())
        ur = UnifiedRequest.objects.create(
            request_type="extras",
            requester=requester,
            status=UnifiedRequestStatus.NEW,
            priority="normal",
            source_app="extras",
            source_model="ExtraPurchase",
            source_object_id="997",
            assigned_user=other_agent,
        )
        _user, c = _make_staff(AccessLevel.USER, ["extras"])
        res = c.post(
            reverse("dashboard:extras_request_status_action", args=[ur.id]),
            data={"status": UnifiedRequestStatus.IN_PROGRESS},
        )
        assert res.status_code == 403


# ═══════════════════════════════════════════════════════════════
# 5) Non-staff user denied even with valid session
# ═══════════════════════════════════════════════════════════════

class TestNonStaffDenied:
    """A non-staff authenticated user must never reach the dashboard even with OTP."""

    def test_non_staff_banned_from_home(self):
        phone = _next_phone()
        user = User.objects.create_user(phone=phone, password="Pass12345!", is_staff=False)
        c = Client()
        c.login(phone=phone, password="Pass12345!")
        s = c.session
        s[SESSION_OTP_VERIFIED_KEY] = True
        s.save()
        res = c.get(reverse("dashboard:home"))
        assert res.status_code == 403

    def test_non_staff_banned_from_support(self):
        phone = _next_phone()
        User.objects.create_user(phone=phone, password="Pass12345!", is_staff=False)
        c = Client()
        c.login(phone=phone, password="Pass12345!")
        s = c.session
        s[SESSION_OTP_VERIFIED_KEY] = True
        s.save()
        res = c.get(reverse("dashboard:support_tickets_list"))
        assert res.status_code == 403


# ═══════════════════════════════════════════════════════════════
# 6) Revoked / Expired profile denied
# ═══════════════════════════════════════════════════════════════

class TestRevokedExpiredDenied:
    """Revoked or expired access profiles must be denied."""

    def test_revoked_user_denied(self):
        from django.utils import timezone
        phone = _next_phone()
        user = User.objects.create_user(phone=phone, password="Pass12345!", is_staff=True)
        dbs = _ensure_dashboards("support")
        ap = UserAccessProfile.objects.create(
            user=user, level=AccessLevel.USER,
            revoked_at=timezone.now(),
        )
        ap.allowed_dashboards.set(dbs.values())
        c = Client()
        c.login(phone=phone, password="Pass12345!")
        s = c.session
        s[SESSION_OTP_VERIFIED_KEY] = True
        s.save()
        res = c.get(reverse("dashboard:support_tickets_list"))
        assert res.status_code in (302, 403)

    def test_expired_user_denied(self):
        from datetime import timedelta
        from django.utils import timezone
        phone = _next_phone()
        user = User.objects.create_user(phone=phone, password="Pass12345!", is_staff=True)
        dbs = _ensure_dashboards("support")
        ap = UserAccessProfile.objects.create(
            user=user, level=AccessLevel.USER,
            expires_at=timezone.now() - timedelta(days=1),
        )
        ap.allowed_dashboards.set(dbs.values())
        c = Client()
        c.login(phone=phone, password="Pass12345!")
        s = c.session
        s[SESSION_OTP_VERIFIED_KEY] = True
        s.save()
        res = c.get(reverse("dashboard:support_tickets_list"))
        assert res.status_code in (302, 403)


# ═══════════════════════════════════════════════════════════════
# 7) Superuser / Admin bypass
# ═══════════════════════════════════════════════════════════════

class TestSuperuserBypass:
    """Superuser and ADMIN-level staff can access all dashboards."""

    def test_superuser_access_all(self):
        phone = _next_phone()
        user = User.objects.create_user(
            phone=phone, password="Pass12345!",
            is_staff=True, is_superuser=True,
        )
        c = Client()
        c.login(phone=phone, password="Pass12345!")
        s = c.session
        s[SESSION_OTP_VERIFIED_KEY] = True
        s.save()
        for url_name in [
            "support_tickets_list", "promo_requests_list",
            "billing_invoices_list", "verification_requests_list",
            "subscriptions_list", "extras_list", "content_management",
        ]:
            res = c.get(reverse(f"dashboard:{url_name}"))
            assert res.status_code == 200, f"Superuser denied from {url_name}"

    def test_admin_level_access_all(self):
        _user, c = _make_staff(AccessLevel.ADMIN, ["support"])
        # ADMIN bypasses per-dashboard; should access any dashboard
        for url_name in [
            "support_tickets_list", "promo_requests_list",
            "billing_invoices_list", "verification_requests_list",
            "subscriptions_list", "extras_list", "content_management",
        ]:
            res = c.get(reverse(f"dashboard:{url_name}"))
            assert res.status_code == 200, f"Admin denied from {url_name}"
