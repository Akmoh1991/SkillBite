from pathlib import Path
import os

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# SECURITY WARNING: keep the secret key used in production secret!
# الأفضل تخليه في متغير بيئة في الإنتاج
SECRET_KEY = os.getenv(
    "DJANGO_SECRET_KEY",
    "django-insecure-txia_$t+gjfid$gz&93$@n+f2xlqaifih5uctd18*td36p9fs!"
)

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv("DJANGO_DEBUG", "True").lower() in ("true", "1", "yes")

# ضع الدومينات/الآيبيات المسموحة هنا (في الإنتاج لا تتركها فاضية)
# ملاحظة: split قد ينتج [''] لو كان المتغير فاضي، لذلك ننظّفه
_raw_hosts = os.getenv("DJANGO_ALLOWED_HOSTS", "")
ALLOWED_HOSTS = [] if DEBUG else [h.strip() for h in _raw_hosts.split(",") if h.strip()]


# Application definition

INSTALLED_APPS = [
    # Django contrib
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Local apps (LMS SaaS)
    'tenancy',
    'learning',
    'progress',
]

# Custom user model (must be set before first migrate)
AUTH_USER_MODEL = "tenancy.User"


MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    # مهم جدًا إذا ستستخدم HTTPS خلف بروكسي (Nginx/Cloudflare) لاحقًا
    'django.middleware.common.CommonMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'SkillBite.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',

        # ✅ تعريف مجلد templates الرئيسي في جذر المشروع
        'DIRS': [BASE_DIR / "templates"],

        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'SkillBite.wsgi.application'


# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}


# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]


# Internationalization
LANGUAGE_CODE = 'ar'
USE_I18N = True

TIME_ZONE = 'Asia/Riyadh'
USE_TZ = True

FIRST_DAY_OF_WEEK = 6  # 6 = Saturday

DATE_FORMAT = "d/m/Y"
DATETIME_FORMAT = "d/m/Y H:i"
TIME_FORMAT = "H:i"


# Static files (CSS, JavaScript, Images)
STATIC_URL = "/static/"
STATICFILES_DIRS = [
    BASE_DIR / "static",
]
# للإنتاج لاحقًا: python manage.py collectstatic
STATIC_ROOT = BASE_DIR / "staticfiles"

# Media uploads
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"


# Security defaults (مفيدة حتى في التطوير، وضرورية في الإنتاج)
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
CSRF_COOKIE_HTTPONLY = True
SESSION_COOKIE_HTTPONLY = True

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'