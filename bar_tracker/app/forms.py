from django import forms
from .models import OccupancyReport


class OccupancyReportForm(forms.ModelForm):
    class Meta:
        model = OccupancyReport
        fields = ["occupancy_level"]

    def clean_occupancy_level(self):
        occupancy_level = self.cleaned_data.get("occupancy_level")
        if occupancy_level < 1 or occupancy_level > 10:
            raise forms.ValidationError("Occupancy level must be between 1 and 10.")
        return occupancy_level
