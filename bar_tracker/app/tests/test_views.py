from django.test import TestCase
from app.apis import update_location
from django.urls import reverse
from app.models import Bar, OccupancyReport, UserProfile
from django.contrib.auth.models import User


class SubmitOccupancyTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="password")
        self.bar = Bar.objects.create(name="Test Bar")

    def test_submit_occupancy_success(self):
        self.client.login(username="testuser", password="password")
        response = self.client.post(
            reverse("submit_occupancy"),
            {
                "bar_id": self.bar.id,
                "occupancy_level": 5,
                "line_wait": 10,
                "within_proximity": True,
            },
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("Report submitted successfully.", response.content.decode())


class UpdateLocationTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="password")
        self.client.login(username="testuser", password="password")

    def test_update_location_success(self):
        """Test successful location update."""
        response = self.client.post(
            reverse("update_location"), {"latitude": 38.0336, "longitude": -78.5080}
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("Location updated successfully.", response.content.decode())

        profile = UserProfile.objects.get(user=self.user)
        self.assertEqual(profile.latitude, 38.0336)
        self.assertEqual(profile.longitude, -78.5080)

    def test_missing_data(self):
        """Test missing latitude or longitude."""
        response = self.client.post(reverse("update_location"), {"latitude": 38.0336})
        self.assertEqual(response.status_code, 400)
        self.assertIn("Missing location data.", response.content.decode())

    def test_invalid_method(self):
        """Test invalid request method."""
        response = self.client.get(reverse("update_location"))
        self.assertEqual(response.status_code, 405)
        self.assertIn("Invalid request method.", response.content.decode())
