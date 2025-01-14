from django.shortcuts import get_object_or_404
from app.models import Bar, OccupancyReport, UserProfile
from django.http import JsonResponse
from django.utils.timezone import now
from app.utils import (
    flag_fraudulent_entries,
    handle_user_strikes,
    verify_cooldown,
    calculate_displayed_values,
    calculate_distance,
)
import logging

logger = logging.getLogger(__name__)


def get_bars(request):
    """Retrieve a list of all active bars."""
    bars = Bar.objects.filter(is_active=True)

    bar_data = []
    for bar in bars:
        bar_info = {
            "id": bar.id,
            "name": bar.name,
            "current_occupancy": bar.displayed_current_occupancy,
            "current_line_wait": bar.displayed_current_line,
            "is_active": bar.is_active,
        }

        bar_data.append(bar_info)

    return JsonResponse(bar_data, safe=False)


def submit_occupancy(request):
    if request.method == "POST":
        try:
            bar_id = request.POST.get("bar_id")
            occupancy_level = request.POST.get("occupancy_level")
            line_wait = request.POST.get("line_wait")
            bar = get_object_or_404(Bar, id=bar_id)
            user = request.user
            if not verify_cooldown(user, bar):
                return JsonResponse(
                    {
                        "success": False,
                        "message": "You can only submit a report every 10 minutes for the same bar.",
                    },
                    status=400,
                )
            # Create a new OccupancyReport
            report = OccupancyReport.objects.create(
                bar=bar,
                user=user,
                occupancy_level=int(occupancy_level) if occupancy_level else None,
                line_wait=int(line_wait) if line_wait else None,
            )
            # Calculate new displayed values using utils.py logic
            displayed_occupancy, displayed_line = calculate_displayed_values(bar)
            bar.displayed_current_occupancy = displayed_occupancy
            bar.displayed_current_line = displayed_line

            if flag_fraudulent_entries(report, displayed_occupancy, displayed_line):
                handle_user_strikes(user)
            bar.save()

            return JsonResponse(
                {"success": True, "message": "Report submitted successfully."}
            )

        except Exception as e:
            logger.error(f"Error in submit_occupancy: {e}")
            return JsonResponse({"success": False, "error": str(e)}, status=500)

    return JsonResponse({"success": False, "error": "Invalid request"}, status=405)


def update_location(request):
    if request.method == "POST":
        try:
            user = request.user
            latitude = request.POST.get("latitude")
            longitude = request.POST.get("longitude")

            if not all([latitude, longitude]):
                return JsonResponse(
                    {"success": False, "message": "Missing location data."}, status=400
                )
            profile, created = UserProfile.objects.get_or_create(user=user)
            # Update user's location in UserProfile
            if profile.latitude != float(latitude) or profile.longitude != float(
                longitude
            ):
                profile, created = UserProfile.objects.get_or_create(user=user)
                profile.latitude = float(latitude)
                profile.longitude = float(longitude)
                profile.last_updated = now()
                profile.save()

            return JsonResponse(
                {"success": True, "message": "Location updated successfully."}
            )
        except Exception as e:
            return JsonResponse(
                {"success": False, "message": f"An error occurred: {e}"}, status=400
            )

    return JsonResponse(
        {"success": False, "message": "Invalid request method."}, status=405
    )
