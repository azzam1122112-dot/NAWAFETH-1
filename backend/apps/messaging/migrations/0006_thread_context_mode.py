from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("messaging", "0005_threaduserstate_client_label_favorite_label"),
    ]

    operations = [
        migrations.AddField(
            model_name="thread",
            name="context_mode",
            field=models.CharField(
                choices=[("client", "عميل"), ("provider", "مزود"), ("shared", "مشترك")],
                db_index=True,
                default="shared",
                max_length=20,
            ),
        ),
    ]

