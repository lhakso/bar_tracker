from app.models import OccupancyReport
import logging

logger = logging.getLogger(__name__)


def clear_reports():
    deleted_count, _ = OccupancyReport.objects.all().delete()
    message = f"Deleted {deleted_count} reports."
    logger.info(message)
    return message
