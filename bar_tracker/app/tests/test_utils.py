from django.test import TestCase
from datetime import timedelta
from django.utils.timezone import now
from app.models import Bar, OccupancyReport
from django.contrib.auth.models import User
from app.utils import verify_cooldown


class VerifyCooldownTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="password")
        self.bar = Bar.objects.create(name="Test Bar")

    def test_no_recent_reports(self):
        """Test cooldown when no recent reports exist."""
        self.assertTrue(verify_cooldown(self.user, self.bar))

    def test_within_cooldown_period(self):
        """Test cooldown fails if a report was recently submitted."""
        OccupancyReport.objects.create(
            user=self.user,
            bar=self.bar,
            occupancy_level=5,  # Provide required field
            line_wait=5,  # Provide required field
            timestamp=now(),
        )
        self.assertFalse(verify_cooldown(self.user, self.bar))

    def test_outside_cooldown_period(self):
        """Test cooldown passes if the last report is outside the cooldown period."""
        report = OccupancyReport.objects.create(
            user=self.user,
            bar=self.bar,
            occupancy_level=5,
            line_wait=5,
            # timestamp auto set to now() by parent model
        )
        report.timestamp -= timedelta(minutes=15)
        report.save()
        self.assertTrue(verify_cooldown(self.user, self.bar))
