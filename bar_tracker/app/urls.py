from django.urls import path
from . import views
from .apis.views import submit_occupancy, get_bars, update_location

urlpatterns = [
    path("", views.bar_list, name="bar_list"),  # Home page with bar list
    path("bar/<int:bar_id>/", views.bar_detail, name="bar_detail"),  # Bar details
    path("submit_occupancy/", submit_occupancy, name="submit_occupancy"),
    path("update_location/", update_location, name="update_location"),
    path("bars/", get_bars, name="get_bars"),
]
