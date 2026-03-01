#!/usr/bin/env bash
set -euo pipefail

python manage.py migrate --noinput

# collectstatic already runs during Render build. Keep startup fast to avoid
# boot-time port scan timeouts; allow opt-in override when needed.
if [ "${RUN_COLLECTSTATIC_ON_START:-0}" = "1" ]; then
	python manage.py collectstatic --noinput
fi

PORT_VALUE="${PORT:-8000}"
WEB_CONCURRENCY_VALUE="${WEB_CONCURRENCY:-2}"
LOG_LEVEL_VALUE="${GUNICORN_LOG_LEVEL:-info}"
TIMEOUT_VALUE="${GUNICORN_TIMEOUT:-60}"

exec gunicorn config.asgi:application \
	-k uvicorn.workers.UvicornWorker \
	--bind "0.0.0.0:${PORT_VALUE}" \
	--workers "${WEB_CONCURRENCY_VALUE}" \
	--log-level "${LOG_LEVEL_VALUE}" \
	--timeout "${TIMEOUT_VALUE}"
