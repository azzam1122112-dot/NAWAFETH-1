#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

export DJANGO_ENV="${DJANGO_ENV:-prod}"

# ── Migrations (run in background to avoid blocking startup) ────────
# On Render free plan, cold starts must be fast to avoid Cloudflare 524.
# Run migrations with a timeout to prevent hanging on DB connection issues.
if [ "${RUN_MIGRATIONS_ON_START:-1}" = "1" ]; then
	echo "[start] Running migrations (timeout 30s)..."
	timeout 30 python manage.py migrate --noinput 2>&1 || echo "[start] WARNING: migrate timed out or failed, continuing anyway."
fi

# ── Static files ────────────────────────────────────────────
# On Render free plan build artifacts may not persist to runtime.
# If the manifest is missing we regenerate it before starting gunicorn.
# WHITENOISE_MANIFEST_STRICT=False (in settings) prevents 500 errors
# even if something goes wrong here.
if [ ! -f "staticfiles/staticfiles.json" ]; then
	echo "[start] Static manifest missing — running collectstatic (timeout 30s)..."
	timeout 30 python manage.py collectstatic --noinput 2>&1 || echo "[start] WARNING: collectstatic failed, continuing anyway."
else
	echo "[start] Static manifest OK."
fi

# ── Gunicorn ────────────────────────────────────────────────
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
