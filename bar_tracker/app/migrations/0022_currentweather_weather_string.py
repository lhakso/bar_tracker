# Generated by Django 5.1.4 on 2025-03-19 00:19

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0021_currentweather_occupancyreport_closed_event_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='currentweather',
            name='weather_string',
            field=models.CharField(blank=True, null=True),
        ),
    ]
