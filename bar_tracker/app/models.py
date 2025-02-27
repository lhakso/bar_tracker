from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.timezone import now
from django.db import models
from django.contrib.auth.models import User


class Bar(models.Model):
    name = models.CharField(max_length=100)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    users_nearby = models.IntegerField(default=0)
    displayed_current_occupancy = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(10)],
        null=True,
        blank=True,
    )
    is_active = models.BooleanField(default=True)
    displayed_current_line = models.IntegerField(null=True, blank=True)

    def __str__(self):
        return self.name


class OccupancyReport(models.Model):
    bar = models.ForeignKey(Bar, on_delete=models.CASCADE, related_name="reports")
    # user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reports")
    user = models.CharField(max_length=255)
    timestamp = models.DateTimeField(auto_now_add=True)
    flagged = models.BooleanField(default=False)
    occupancy_level = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(10)]
    )
    line_wait = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(10)],
        null=True,
        blank=True,
    )

    def __str__(self):
        return f"{self.bar.name} - Level {self.occupancy_level} at {self.timestamp}"


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    email = models.EmailField(unique=True, null=True, blank=True)
    submissions = models.IntegerField(default=0)
    strikes = models.IntegerField(default=0)
    is_near_bar = models.BooleanField(blank=True, default=False)
    last_updated_location = models.DateTimeField(null=True, blank=True)

    def increment_strikes(self):
        """increment the strike count for the user"""
        self.strikes += 1
        self.save()

    def reset_strikes(self):
        self.strikes = 0
        self.save()

    def __str__(self):
        return f"{self.user.username} profile"
