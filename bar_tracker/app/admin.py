from django.contrib import admin
from .models import Bar, OccupancyReport
from .models import UserProfile

admin.site.register(OccupancyReport)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "email",
        "is_near_bar",
        "strikes",
        "submissions",
        "last_updated_location",
    )
    search_fields = ("user__username",)

@admin.register(Bar)
class BarAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "is_active",
        "users_nearby",
    )  # Show name and active status in the admin panel
    list_filter = ("is_active",)  # Filter bars by active/inactive status
    actions = ["activate_bars", "deactivate_bars"]  # Add bulk actions

    @admin.action(description="Activate selected bars")
    def activate_bars(self, request, queryset):
        queryset.update(is_active=True)

    @admin.action(description="Deactivate selected bars")
    def deactivate_bars(self, request, queryset):
        queryset.update(is_active=False)
