"""
WSGI config for Skillbite project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/6.0/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Skillbite.settings')

application = get_wsgi_application()

# Safety net: ensure static files are served via WhiteNoise under Gunicorn.
# (Django middleware should handle this too, but this makes production more robust.)
try:
	from django.conf import settings
	from whitenoise import WhiteNoise

	application = WhiteNoise(
		application,
		root=str(settings.STATIC_ROOT),
		prefix=settings.STATIC_URL,
		autorefresh=settings.DEBUG,
		use_finders=getattr(settings, "WHITENOISE_USE_FINDERS", False),
	)
except Exception:
	# If WhiteNoise isn't available for any reason, fall back to the Django app.
	pass
