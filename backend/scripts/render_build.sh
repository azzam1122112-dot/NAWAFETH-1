#!/usr/bin/env bash
set -euo pipefail

python -m pip install --upgrade pip
pip install -r requirements/prod.txt

# حذف مجلد staticfiles القديم لتجنب manifest غير متسق بين عمليات النشر
echo "[build] Removing old staticfiles..."
rm -rf staticfiles

echo "[build] Running collectstatic..."
python manage.py collectstatic --noinput

echo "[build] staticfiles dir contents:"
ls -la staticfiles/ 2>/dev/null | head -20 || echo "[build] WARNING: staticfiles/ not found after collectstatic!"
echo "[build] Build script complete."
