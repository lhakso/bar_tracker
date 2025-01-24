# yourapp/serializers.py

from rest_framework import serializers
from .models import UserProfile


class UpdateEmailSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=False, allow_blank=True)

    class Meta:
        model = UserProfile
        fields = ["email"]

    def validate_email(self, value):
        # Check if the email is already in use
        if (
            UserProfile.objects.filter(email=value)
            .exclude(pk=self.instance.pk)
            .exists()
        ):
            raise serializers.ValidationError("This email is already in use.")
        return value
