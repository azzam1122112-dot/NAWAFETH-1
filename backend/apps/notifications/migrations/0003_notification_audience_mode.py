from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("notifications", "0002_notification_preferences_and_flags"),
    ]

    operations = [
        migrations.AddField(
            model_name="notification",
            name="audience_mode",
            field=models.CharField(
                choices=[("client", "عميل"), ("provider", "مزود"), ("shared", "مشترك")],
                db_index=True,
                default="shared",
                max_length=20,
            ),
        ),
    ]

