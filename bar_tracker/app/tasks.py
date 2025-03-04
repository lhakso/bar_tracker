import os
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app_config.settings")
django.setup()
import logging
from app.models import OccupancyReport
logger = logging.getLogger(__name__)

def clear_reports():
    deleted_count, _ = OccupancyReport.objects.all().delete()
    message = f"Deleted {deleted_count} reports."
    logger.info(message)
    return message

if __name__ == "__main__":
    clear_reports()