# Generated by Django 5.1.4 on 2025-04-09 19:20

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('app', '0023_rename_is_clear_currentweather_clear_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='SiteStatistics',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('total_users', models.IntegerField(default=0)),
                ('last_updated', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'Site Statistics',
                'verbose_name_plural': 'Site Statistics',
            },
        ),
        migrations.RemoveField(
            model_name='occupancyreport',
            name='sunrise',
        ),
    ]
