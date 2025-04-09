from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.timezone import now
from app.weather_models import CurrentWeather
from django.contrib.auth.models import User


class SiteStatistics(models.Model):
    total_users = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Site Statistics"
        verbose_name_plural = "Site Statistics"
    
    def __str__(self):
        return f"Site Statistics (Updated: {self.last_updated})"
    
    @classmethod
    def get_instance(cls):
        """Get or create the singleton instance of SiteStatistics"""
        stats, created = cls.objects.get_or_create(pk=1)
        return stats
    
    def get_bars_with_users(self):
        """
        Get a list of all bars with their names and nearby user counts.
        Returns a list of dictionaries with bar name and users_nearby.
        """
        from django.db.models import F
        return list(Bar.objects.filter(is_active=True)
                   .values('name', 'users_nearby')
                   .order_by('-users_nearby', 'name'))
    
    def get_formatted_bar_stats(self):
        """
        Get a formatted string representation of all bars and their nearby users.
        """
        bars = self.get_bars_with_users()
        if not bars:
            return "No active bars found"
        
        result = []
        for bar in bars:
            result.append(f"{bar['name']}: {bar['users_nearby']} users nearby")
        
        return "\n".join(result)


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
    temperature = models.IntegerField(blank=True, null=True)
    weather = models.CharField(blank=True, null=True)
    closed_event = models.BooleanField(blank=True, default=False)

    @property
    def day_of_week(self):
        return self.timestamp.weekday()

    @property
    def is_party_night(self):
        """Returns True if the day is Thursday, Friday, or Saturday"""
        weekday = self.day_of_week
        return weekday in [3, 4, 5]

    def __str__(self):
        return f"{self.bar.name} - Level {self.occupancy_level} at {self.timestamp}"

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    email = models.EmailField(unique=True, null=True, blank=True)
    submissions = models.IntegerField(default=0)
    strikes = models.IntegerField(default=0)
    is_near_bar = models.IntegerField(null=True, default=-1)
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
