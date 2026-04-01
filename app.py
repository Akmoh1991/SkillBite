"""Render/Gunicorn compatibility entrypoint for the Django app."""

import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "Skillbite.settings")

from Skillbite.wsgi import application

# Render is currently configured to start Gunicorn with `app:app`.
app = application

