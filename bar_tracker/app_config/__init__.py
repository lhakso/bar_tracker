from __future__ import absolute_import, unicode_literals

# Import the Celery app from celery_app.py
from .celery_app import app as celery_app

__all__ = ("celery_app",)
