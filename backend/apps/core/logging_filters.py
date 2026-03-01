import logging


class ExcludeHealthCheckAccessFilter(logging.Filter):
    """Drop noisy access logs for health endpoints to reduce log/IO overhead."""

    def filter(self, record: logging.LogRecord) -> bool:
        message = record.getMessage()
        return '"GET /health' not in message and '"HEAD /health' not in message


class ExcludeCommonBotScan404Filter(logging.Filter):
    """Drop noisy 404 probes from common internet scanners."""

    _blocked_markers = (
        "Not Found: /wp-admin/",
        "Not Found: /wordpress/wp-admin/",
        "Not Found: /wp-login.php",
        "Not Found: /xmlrpc.php",
        "Not Found: /.env",
    )

    def filter(self, record: logging.LogRecord) -> bool:
        message = record.getMessage()
        return not any(marker in message for marker in self._blocked_markers)
