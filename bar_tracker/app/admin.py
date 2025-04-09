from django.contrib import admin
from .models import Bar, OccupancyReport, UserProfile, SiteStatistics

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


@admin.register(SiteStatistics)
class SiteStatisticsAdmin(admin.ModelAdmin):
    list_display = ("total_users", "last_updated", "bar_statistics")
    readonly_fields = ("last_updated", "bar_statistics")

    def has_add_permission(self, request):
        # Prevent creating multiple statistics instances
        return SiteStatistics.objects.count() == 0

    def has_delete_permission(self, request, obj=None):
        # Prevent deleting the statistics instance
        return False

    def bar_statistics(self, obj):
        """Display formatted bar statistics in the admin detail view"""
        return obj.get_formatted_bar_stats()

    bar_statistics.short_description = "Users at each bar"
