from __future__ import annotations

from django.conf import settings
from django.db import models
from django.utils import timezone

from apps.providers.models import ProviderProfile


class ExtrasPortalSubscriptionStatus(models.TextChoices):
    ACTIVE = "active", "نشط"
    INACTIVE = "inactive", "غير نشط"


class ExtrasPortalSubscription(models.Model):
    provider = models.OneToOneField(
        ProviderProfile,
        on_delete=models.CASCADE,
        related_name="extras_portal_subscription",
    )
    status = models.CharField(
        max_length=20,
        choices=ExtrasPortalSubscriptionStatus.choices,
        default=ExtrasPortalSubscriptionStatus.ACTIVE,
    )
    plan_title = models.CharField(max_length=120, blank=True, default="")
    started_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    notes = models.CharField(max_length=255, blank=True, default="")
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"ExtrasPortalSubscription provider={self.provider_id} status={self.status}"


class ExtrasPortalFinanceSettings(models.Model):
    provider = models.OneToOneField(
        ProviderProfile,
        on_delete=models.CASCADE,
        related_name="extras_portal_finance_settings",
    )
    bank_name = models.CharField(max_length=120, blank=True, default="")
    account_name = models.CharField(max_length=120, blank=True, default="")
    iban = models.CharField(max_length=34, blank=True, default="")
    qr_image = models.FileField(upload_to="extras_portal/finance/%Y/%m/", null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)


class ScheduledMessageStatus(models.TextChoices):
    PENDING = "pending", "معلق"
    SENT = "sent", "تم الإرسال"
    FAILED = "failed", "فشل"
    CANCELLED = "cancelled", "ملغي"


class ExtrasPortalScheduledMessage(models.Model):
    provider = models.ForeignKey(
        ProviderProfile,
        on_delete=models.CASCADE,
        related_name="scheduled_messages",
    )
    body = models.TextField(max_length=2000)
    attachment = models.FileField(upload_to="extras_portal/messages/%Y/%m/%d/", null=True, blank=True)
    send_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=ScheduledMessageStatus.choices,
        default=ScheduledMessageStatus.PENDING,
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="extras_portal_created_messages",
    )
    created_at = models.DateTimeField(default=timezone.now)
    sent_at = models.DateTimeField(null=True, blank=True)
    error = models.CharField(max_length=255, blank=True, default="")


class ExtrasPortalScheduledMessageRecipient(models.Model):
    scheduled_message = models.ForeignKey(
        ExtrasPortalScheduledMessage,
        on_delete=models.CASCADE,
        related_name="recipients",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="extras_portal_message_recipients",
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["scheduled_message", "user"],
                name="uniq_extras_portal_scheduled_message_user",
            )
        ]
