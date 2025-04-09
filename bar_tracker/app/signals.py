from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.contrib.auth.models import User
from .models import UserProfile, SiteStatistics
from django.conf import settings
from rest_framework.authtoken.models import Token
from django.db import transaction


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)
        # Update total user count when a new user is created
        update_user_count()


@receiver(post_delete, sender=User)
def handle_user_deletion(sender, instance, **kwargs):
    # Note: UserProfile should be automatically deleted due to OneToOneField with CASCADE
    # Check if there are any UserProfiles without users and delete them
    UserProfile.objects.filter(user__isnull=True).delete()
    # Update total user count
    update_user_count()


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_auth_token(sender, instance=None, created=False, **kwargs):
    if created:
        Token.objects.create(user=instance)


def update_user_count():
    """Update the total user count in SiteStatistics"""
    with transaction.atomic():
        stats = SiteStatistics.get_instance()
        stats.total_users = User.objects.count()
        stats.save()
