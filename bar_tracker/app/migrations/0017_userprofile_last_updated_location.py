# Generated by Django 5.1.4 on 2025-02-27 17:17

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0016_remove_userprofile_last_updated_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='last_updated_location',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
