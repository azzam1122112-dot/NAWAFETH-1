from __future__ import annotations

from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.messaging.models import Message, Thread

from ...models import ExtrasPortalScheduledMessage, ScheduledMessageStatus


def _get_or_create_direct_thread(user_a, user_b) -> Thread:
    if user_a.id == user_b.id:
        raise ValueError("cannot chat self")
    thread = (
        Thread.objects.filter(is_direct=True)
        .filter(
            Q(participant_1=user_a, participant_2=user_b)
            | Q(participant_1=user_b, participant_2=user_a)
        )
        .first()
    )
    if thread:
        return thread
    return Thread.objects.create(is_direct=True, participant_1=user_a, participant_2=user_b)


class Command(BaseCommand):
    help = "Send due scheduled extras portal messages (bulk messaging)."

    def handle(self, *args, **options):
        now = timezone.now()
        qs = (
            ExtrasPortalScheduledMessage.objects.select_related("provider", "provider__user")
            .prefetch_related("recipients", "recipients__user")
            .filter(status=ScheduledMessageStatus.PENDING, send_at__isnull=False, send_at__lte=now)
            .order_by("id")
        )
        count = qs.count()
        if count == 0:
            self.stdout.write("No due messages")
            return

        self.stdout.write(f"Sending {count} due message(s)...")

        for scheduled in qs:
            provider_user = scheduled.provider.user
            recipients = [r.user for r in scheduled.recipients.all()]
            if not recipients:
                scheduled.status = ScheduledMessageStatus.CANCELLED
                scheduled.error = "no recipients"
                scheduled.save(update_fields=["status", "error"])
                continue

            try:
                with transaction.atomic():
                    for u in recipients:
                        thread = _get_or_create_direct_thread(provider_user, u)
                        Message.objects.create(
                            thread=thread,
                            sender=provider_user,
                            body=scheduled.body,
                            attachment=scheduled.attachment,
                            attachment_type="",
                            attachment_name="",
                            created_at=now,
                        )
                    scheduled.status = ScheduledMessageStatus.SENT
                    scheduled.sent_at = now
                    scheduled.error = ""
                    scheduled.save(update_fields=["status", "sent_at", "error"])
            except Exception as e:
                scheduled.status = ScheduledMessageStatus.FAILED
                scheduled.error = str(e)[:255]
                scheduled.save(update_fields=["status", "error"])

        self.stdout.write("Done")
