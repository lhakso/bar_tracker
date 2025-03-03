from rest_framework.permissions import BasePermission
import uuid


class ValidTokenPermission(BasePermission):
    """
    Allows access only if the request contains a valid token in the Authorization header.
    """
    def has_permission(self, request, view):
        print("Checking token permission")
        token = request.headers.get("Authorization")
        
        if not token:
            print("AUTH ERROR: No Authorization header present")
            return False
            
        print(f"Raw Authorization header: {token[:15]}...")
        
        # Remove the "Token " prefix if present.
        if token.startswith("Token "):
            token = token[6:]
            print(f"Token prefix removed, now: {token[:15]}...")
        else:
            print(f"No 'Token ' prefix found in header")
            
        try:
            print(f"Attempting to validate token as UUID: {token[:15]}...")
            uuid.UUID(token)
            print("Token successfully validated as UUID format")
            return True
        except (ValueError, AttributeError) as e:
            print(f"AUTH ERROR: Invalid token format: {str(e)}")
            return False
