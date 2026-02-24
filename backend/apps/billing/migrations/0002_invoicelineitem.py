from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("billing", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="InvoiceLineItem",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("item_code", models.CharField(blank=True, default="", max_length=20)),
                ("title", models.CharField(max_length=160)),
                ("amount", models.DecimalField(decimal_places=2, default="0.00", max_digits=12)),
                ("sort_order", models.PositiveIntegerField(default=0)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "invoice",
                    models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="lines", to="billing.invoice"),
                ),
            ],
            options={
                "ordering": ["sort_order", "id"],
            },
        ),
    ]
