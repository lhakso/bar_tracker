from django.urls import path
from . import views
from .apis.views import (
    submit_occupancy,
    get_bars,
    register_user,
    update_user_email,
    get_user_email,
    is_user_near_bar,
)
from rest_framework.authtoken.views import obtain_auth_token

urlpatterns = [
    path("", views.bar_list, name="bar_list"),  # Home page with bar list
    path("bar/<int:bar_id>/", views.bar_detail, name="bar_detail"),  # Bar details
    path("submit_occupancy/", submit_occupancy, name="submit_occupancy"),
    path("is_near_bar/", is_user_near_bar, name="is_user_near_bar"),
    path("bars/", get_bars, name="get_bars"),
    path("api-token-auth/", obtain_auth_token, name="api_token_auth"),
    path("register/", register_user, name="register_user"),
    path("update_email/", update_user_email, name="update_email"),
    path("get_email/", get_user_email, name="get_user_email"),
]
