# Generated by Django 5.1.4 on 2025-01-22 21:43

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0013_alter_userprofile_user'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='submissions',
            field=models.IntegerField(default=0),
        ),
    ]
