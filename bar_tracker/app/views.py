from django.shortcuts import render
from django.shortcuts import redirect
from .forms import OccupancyReportForm
from django.shortcuts import render, get_object_or_404
from .models import Bar, OccupancyReport, UserProfile
from django.http import JsonResponse
from .utils import calculate_displayed_values
from app.utils import flag_fraudulent_entries, handle_user_strikes, verify_cooldown
import logging

logger = logging.getLogger(__name__)


def bar_list(request):
    bars = Bar.objects.filter(is_active=True)
    for bar in bars:
        bar.displayed_current_occupancy, bar.displayed_current_line = (
            calculate_displayed_values(bar)
        )
    return render(request, "bar_list.html", {"bars": bars})


def bar_detail(request, bar_id):
    bar = get_object_or_404(Bar, id=bar_id)
    reports = OccupancyReport.objects.filter(bar=bar).order_by("-timestamp")

    if request.method == "POST":
        form = OccupancyReportForm(request.POST)
        if form.is_valid():
            report = form.save(commit=False)
            report.bar = bar
            report.user = request.user
            report.save()

            # Calculate new displayed values using utils.py logic
            bar.displayed_current_occupancy, bar.displayed_current_line = (
                calculate_displayed_values(bar)
            )
            bar.save()

            return redirect("bar_detail", bar_id=bar.id)
    else:
        form = OccupancyReportForm()

    return render(
        request, "bar_detail.html", {"bar": bar, "reports": reports, "form": form}
    )


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
