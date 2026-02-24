from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):

    dependencies = [
        ("verification", "0002_verificationrequest_assignment"),
    ]

    operations = [
        migrations.AlterField(
            model_name="verificationrequest",
            name="badge_type",
            field=models.CharField(blank=True, choices=[("blue", "شارة زرقاء"), ("green", "شارة خضراء")], max_length=20, null=True),
        ),
        migrations.AddField(
            model_name="verificationrequest",
            name="priority",
            field=models.PositiveSmallIntegerField(default=2),
        ),
        migrations.CreateModel(
            name="VerificationRequirement",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("badge_type", models.CharField(choices=[("blue", "شارة زرقاء"), ("green", "شارة خضراء")], max_length=20)),
                ("code", models.CharField(max_length=10)),
                ("title", models.CharField(max_length=220)),
                ("is_approved", models.BooleanField(blank=True, null=True)),
                ("decision_note", models.CharField(blank=True, max_length=300)),
                ("decided_at", models.DateTimeField(blank=True, null=True)),
                ("sort_order", models.PositiveIntegerField(default=0)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "decided_by",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="verification_requirement_decisions",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
                (
                    "request",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="requirements", to="verification.verificationrequest"),
                ),
            ],
            options={
                "ordering": ["sort_order", "id"],
            },
        ),
        migrations.CreateModel(
            name="VerificationRequirementAttachment",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("file", models.FileField(upload_to="verification/requirements/%Y/%m/")),
                ("uploaded_at", models.DateTimeField(auto_now_add=True)),
                (
                    "requirement",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="attachments", to="verification.verificationrequirement"),
                ),
                (
                    "uploaded_by",
                    models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL),
                ),
            ],
        ),
        migrations.AddField(
            model_name="verifiedbadge",
            name="verification_code",
            field=models.CharField(blank=True, default="", max_length=10),
        ),
        migrations.AddField(
            model_name="verifiedbadge",
            name="verification_title",
            field=models.CharField(blank=True, default="", max_length=220),
        ),
        migrations.AddIndex(
            model_name="verifiedbadge",
            index=models.Index(fields=["user", "verification_code", "is_active"], name="verificatio_user_id_06295a_idx"),
        ),
        migrations.AddIndex(
            model_name="verificationrequirement",
            index=models.Index(fields=["code"], name="verificatio_code_0d4980_idx"),
        ),
        migrations.AddIndex(
            model_name="verificationrequirement",
            index=models.Index(fields=["badge_type"], name="verificatio_badge_t_344f02_idx"),
        ),
    ]
