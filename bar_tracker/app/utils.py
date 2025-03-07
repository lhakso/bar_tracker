from datetime import timedelta
from django.utils.timezone import now
from app.models import UserProfile, OccupancyReport, Bar
from geopy.distance import geodesic
import math
from django.shortcuts import get_object_or_404
from typing import Tuple
from django.contrib.auth.models import User
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Count


def calculate_displayed_values(bar: Bar) -> Tuple[int, int]:
    """
    Calculate and return displayed values for occupancy and line.
    Displayed values use a half life formula.  Weight = 0.5^(Minutes Elapsed / Half-Life in Minutes)
    """
    half_life = 15 # mins
    current_time = now()
    one_hour_ago = current_time - timedelta(hours=1)
    reports_weighted = []
    all_weights = []
    
    reports = bar.reports.filter(timestamp__gte=one_hour_ago).order_by(
        "-timestamp"
    )
    if reports.exists():
        for report in reports:
            minutes_elapsed = (current_time - report.timestamp).total_seconds() / 60
            weight = 0.5**(minutes_elapsed / half_life)
            reports_weighted.append((report.occupancy_level * weight, report.line_wait * weight))
            all_weights.append(weight)

        total_weight = sum(weight for weight in all_weights)

        displayed_occupancy = round(
            sum(r[0] for r in reports_weighted) / total_weight
        )
        displayed_line = round(sum(r[1] for r in reports_weighted) / total_weight)
    else:
        displayed_occupancy = None
        displayed_line = None

    return displayed_occupancy, displayed_line


def flag_fraudulent_entries(report, displayed_occupancy, displayed_line):
    """
    Check if a report is fraudulent based on thresholds.
    Args:
        report (OccupancyReport): The report being submitted.
        displayed_occupancy (int): The current average occupancy displayed to users.
        displayed_line (int): The current average line wait displayed to users.
    Returns:
        bool: True if the report is flagged as fraudulent, False otherwise.
    """
    # Thresholds for flagging
    occupancy_threshold = 3
    line_threshold = 3

    # Determine if report deviates beyond thresholds
    fraudulent_occupancy = (
        abs(report.occupancy_level - displayed_occupancy) > occupancy_threshold
    )
    fraudulent_line = abs(report.line_wait - displayed_line) > line_threshold

    # Flag the report if either condition is met
    report.flagged = fraudulent_occupancy or fraudulent_line
    report.save()
    return report.flagged


def handle_user_strikes(user):
    """
    Increment strikes for a user and disable their reports if over limit.
    Args:
        user (User): The user associated with the flagged report.
    """
    profile, created = UserProfile.objects.get_or_create(user=user)
    profile.increment_strikes()
    profile.save()

    if profile.strikes > 3:
        OccupancyReport.objects.filter(user=user).update(flagged=True)


def verify_cooldown(user, bar, cooldown_minutes=10):
    """
    Verifies that user has not submitted a report within the specified amount of time.
    Prevents spamming.
    """
    cooldown_time = now() - timedelta(minutes=cooldown_minutes)
    recent_reports = OccupancyReport.objects.filter(
        user=user, bar=bar, timestamp__gte=cooldown_time
    )
    return not recent_reports.exists()


def calculate_distance(
    user_coords: Tuple[float, float], bar_coords: Tuple[float, float]
) -> float:
    return geodesic(user_coords, bar_coords).miles


def get_user_from_request(request):
    """need this because using anon tokens caused django to treat user class diff, so need to idenitfy by username"""
    auth_header = request.headers.get("Authorization")
    if not auth_header:
        return None, Response(
            {"error": "Missing token"}, status=status.HTTP_400_BAD_REQUEST
        )

    token = auth_header
    if token.startswith("Token "):
        token = token[6:]

    try:
        user = User.objects.get(username=token)
        return user, None
    except User.DoesNotExist:
        return None, Response(
            {"error": "User not found for this token"}, status=status.HTTP_404_NOT_FOUND
        )