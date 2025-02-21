from django.shortcuts import get_object_or_404
from app.models import Bar, OccupancyReport, UserProfile
from django.http import JsonResponse
from django.utils.timezone import now
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from rest_framework import permissions
from app.serializers import UpdateEmailSerializer
from rest_framework.permissions import AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from app.permissions import ValidTokenPermission
from django.contrib.auth.models import User
from django.contrib.auth.hashers import make_password
from app.utils import (
    flag_fraudulent_entries,
    handle_user_strikes,
    verify_cooldown,
    calculate_displayed_values,
)
import logging

logger = logging.getLogger(__name__)


@api_view(["POST"])
@permission_classes([AllowAny])
def register_user(request):
    """
    Public endpoint for user registration.
    """
    username = request.data.get("username")
    password = request.data.get("password")
    email = request.data.get("email", "")

    # validate inputs
    if not username or not password:
        return Response(
            {"error": "Username and password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if User.objects.filter(username=username).exists():
        return Response(
            {"error": "A user with this username already exists."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Create the user
    user = User.objects.create(
        username=username,
        email=email,
        password=make_password(password),  # Hash the password
    )
    user.save()

    return Response(
        {"success": True, "message": "User registered successfully."},
        status=status.HTTP_201_CREATED,
    )


@api_view(["GET"])
@permission_classes([ValidTokenPermission])
def get_user_email(request):
    try:
        # Use the authenticated user
        user = request.user
        # Fetch the user's profile
        profile = UserProfile.objects.get(user=user)
        # Check if email exists
        if profile.email:
            return JsonResponse({"email": profile.email}, status=200)
        else:
            return JsonResponse({"error": "Email not found"}, status=404)
    except UserProfile.DoesNotExist:
        return JsonResponse({"error": "UserProfile not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@api_view(["GET"])
@permission_classes([ValidTokenPermission])
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
            "latitude": bar.latitude,
            "longitude": bar.longitude,
        }

        bar_data.append(bar_info)

    return JsonResponse(bar_data, safe=False)


@api_view(["POST"])
@permission_classes([ValidTokenPermission])
def submit_occupancy(request):
    """
    DRF-based version of your submit_occupancy endpoint.
    Expects JSON with bar_id, occupancy_level, and line_wait.
    """
    try:
        # 1) Extract data from request.data
        bar_id = request.data.get("bar_id")
        occupancy_level = request.data.get("occupancy_level")
        line_wait = request.data.get("line_wait")
        if not bar_id:
            return Response(
                {"success": False, "error": "bar_id is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 2) Fetch the bar using the provided ID
        bar = get_object_or_404(Bar, id=bar_id)

        # 3) Get the user from request (assuming session or token auth)
        user = request.user

        # 4) Check cooldown logic
        """if not verify_cooldown(user, bar):
            return Response(
                {
                    "success": False,
                    "message": "You can only submit a report every 10 minutes for the same bar.",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )"""

        # 5) Create the OccupancyReport
        report = OccupancyReport.objects.create(
            bar=bar,
            user=request.headers.get("Authorization"),
            occupancy_level=int(occupancy_level) if occupancy_level else 0,
            line_wait=int(line_wait) if line_wait else 0,
        )
        # 6) Recalculate displayed values
        displayed_occupancy, displayed_line = calculate_displayed_values(bar)
        bar.displayed_current_occupancy = displayed_occupancy
        bar.displayed_current_line = displayed_line

        # 7) Fraud check
        if flag_fraudulent_entries(report, displayed_occupancy, displayed_line):
            handle_user_strikes(user)

        bar.save()

        # Track user submissions
        profile, created = UserProfile.objects.get_or_create(user=user)
        profile.submissions += 1
        profile.save()

        return Response(
            {"success": True, "message": "Report submitted successfully."},
            status=status.HTTP_200_OK,
        )

    except Exception as e:
        logger.error(f"Error in submit_occupancy: {e}", exc_info=True)
        return Response(
            {"success": False, "error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["PATCH"])
@permission_classes([ValidTokenPermission])
def update_user_email(request):
    user = request.user

    # Ensure the user has a profile
    profile, created = UserProfile.objects.get_or_create(user=user)

    # Use a serializer specifically for the UserProfile model
    serializer = UpdateEmailSerializer(profile, data=request.data, partial=True)

    if serializer.is_valid():
        serializer.save()
        return Response(
            {"message": "Email updated successfully"}, status=status.HTTP_200_OK
        )
    else:
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["POST"])
@permission_classes([ValidTokenPermission])
def is_user_near_bar(request):
    profile, created = UserProfile.objects.get_or_create(user=request.user)
    profile.is_near_bar = bool(request.data.get("is_near_bar"))
    profile.save()
    return Response(
        {"message": "is_near_bar updated successfully"}, status=status.HTTP_200_OK
    )
