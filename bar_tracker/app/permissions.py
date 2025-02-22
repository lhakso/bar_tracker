from rest_framework.permissions import BasePermission
import uuid


class ValidTokenPermission(BasePermission):
    """
    Allows access only if the request contains a valid token in the Authorization header.
    """

    def has_permission(self, request, view):
        token = request.headers.get("Authorization")
        if not token:
            return False

        try:
            uuid.UUID(token)
        except (ValueError, AttributeError):
            return False

        return True
