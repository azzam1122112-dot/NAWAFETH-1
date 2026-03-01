#!/usr/bin/env bash
set -euo pipefail

python -m pip install --upgrade pip
pip install -r requirements/prod.txt

# حذف مجلد staticfiles القديم لتجنب manifest غير متسق بين عمليات النشر
rm -rf staticfiles

python manage.py collectstatic --noinput
