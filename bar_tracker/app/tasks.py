from models import OccupancyReport
import logging
import os
import django

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'bar_tracker.settings')  # Adjust to your project's settings module
django.setup()

logger = logging.getLogger(__name__)


def clear_reports():
    deleted_count, _ = OccupancyReport.objects.all().delete()
    message = f"Deleted {deleted_count} reports."
    logger.info(message)
    return message

if __name__ == "__main__":
    clear_reports()