from django.test import TestCase
from app.models import Bar, OccupancyReport
from django.contrib.auth.models import User
from django.utils.timezone import now
from app.apis.views import get_bars


class GetBarTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="password")
        self.bar = Bar.objects.create(name="Test Bar")

    def test_get_bars(self):
        OccupancyReport.objects.create(
            user=self.user,
            bar=self.bar,
            occupancy_level=5,
            line_wait=5,
            timestamp=now(),
        )
        self.assertTrue(get_bars(self.bar))
