# Generated by Django 5.1.4 on 2024-12-14 01:40

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0004_alter_occupancyreport_bar'),
    ]

    operations = [
        migrations.AddField(
            model_name='bar',
            name='is_active',
            field=models.BooleanField(default=True),
        ),
    ]
