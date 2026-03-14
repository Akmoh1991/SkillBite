from pathlib import Path
import os
import mimetypes
from dotenv import load_dotenv

# تحميل متغيرات البيئة من ملف .env (إن وجد)
load_dotenv()


def env_bool(key: str, default: bool = False) -> bool:
    """
    Convert environment variable to boolean safely.
    Accepts: true/false, 1/0, yes/no, on/off (case-insensitive).
    """
    return os.getenv(key, str(default)).strip().lower() in ("true", "1", "yes", "on")


def env_csv(key: str, default: str = "") -> list[str]:
    """
    Read comma-separated env var into a list, trimming spaces and removing empties.
    """
    value = os.getenv(key, default) or ""
    return [x.strip() for x in value.split(",") if x.strip()]


# ==================================================
# ✅ حل نهائي لمشاكل تشغيل الفيديو (MIME types)
# ==================================================
# بعض البيئات قد ترجع Content-Type غلط للـ mp4 مما يسبب فشل تشغيل الفيديو.
# نثبت تعريفات الـ MIME للامتدادات المطلوبة:
mimetypes.add_type("video/mp4", ".mp4", strict=True)
mimetypes.add_type("video/webm", ".webm", strict=True)
mimetypes.add_type("image/jpeg", ".jpg", strict=True)
mimetypes.add_type("image/jpeg", ".jpeg", strict=True)
mimetypes.add_type("image/png", ".png", strict=True)


# ==================================================
# المسارات
# ==================================================
BASE_DIR = Path(__file__).resolve().parent.parent


# ==================================================
# الإعدادات الأساسية
# ==================================================
SECRET_KEY = os.getenv("DJANGO_SECRET_KEY", "").strip()

DEBUG = env_bool("DJANGO_DEBUG", False)

# بيئة التشغيل: development / production
DJANGO_ENV = os.getenv("DJANGO_ENV", "development").strip().lower()

if DJANGO_ENV == "development" and not SECRET_KEY:
    SECRET_KEY = "django-insecure-development-only"
elif not SECRET_KEY:
    raise RuntimeError("DJANGO_SECRET_KEY must be set outside development.")

ALLOWED_HOSTS = env_csv("DJANGO_ALLOWED_HOSTS", "")

if DJANGO_ENV == "production" and not ALLOWED_HOSTS:
    ALLOWED_HOSTS = ["skillbite.onrender.com"]


# ==================================================
# التطبيقات
# ==================================================
INSTALLED_APPS = [
    # تطبيقات المشروع
    "accounts.apps.AccountsConfig",
    "training.apps.TrainingConfig",
    "certification.apps.CertificationConfig",

    # تطبيقات Django الافتراضية
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
]


# ==================================================
# الوسطاء (Middleware)
# ==================================================
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",

    # WhiteNoise لازم يكون بعد SecurityMiddleware مباشرة
    "whitenoise.middleware.WhiteNoiseMiddleware",

    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

X_FRAME_OPTIONS = "SAMEORIGIN"


# ==================================================
# إعدادات الروابط والقوالب
# ==================================================
ROOT_URLCONF = "Skillbite.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "Skillbite.wsgi.application"


# ==================================================
# قاعدة البيانات
# ==================================================
if DJANGO_ENV == "production":
    DB_ENGINE = os.getenv("DB_ENGINE", "django.db.backends.postgresql")
    DB_NAME = os.getenv("DB_NAME")
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_HOST = os.getenv("DB_HOST")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_SSLMODE = os.getenv("DB_SSLMODE", "require")

    if not all([DB_NAME, DB_USER, DB_PASSWORD, DB_HOST]):
        raise RuntimeError("Production DB is not configured correctly. Please check .env values.")

    DATABASES = {
        "default": {
            "ENGINE": DB_ENGINE,
            "NAME": DB_NAME,
            "USER": DB_USER,
            "PASSWORD": DB_PASSWORD,
            "HOST": DB_HOST,
            "PORT": DB_PORT,
            "OPTIONS": {"sslmode": DB_SSLMODE},
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }


# ==================================================
# التحقق من كلمات المرور
# ==================================================
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]


# ==================================================
# 🌍 اللغة والمنطقة الزمنية
# ==================================================
LANGUAGE_CODE = "ar"
TIME_ZONE = "Asia/Riyadh"
USE_I18N = True
USE_TZ = True

LOCALE_PATHS = [BASE_DIR / "locale"]


# ==================================================
# الملفات الثابتة (Static)
# ==================================================
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

# هذا يفيد أثناء التطوير المحلي (لو عندك مجلد static في جذر المشروع)
# ✅ منع أي مشاكل إذا مجلد static غير موجود في بعض البيئات
STATIC_DIR = BASE_DIR / "static"
STATICFILES_DIRS = [STATIC_DIR] if STATIC_DIR.exists() else []

# ✅ مهم جدًا مع WhiteNoise + Admin CSS/JS
# في الإنتاج: ملفات مضغوطة + أسماء hashed (أفضل للكاش والاستقرار)
# في التطوير: تخزين عادي لتفادي أخطاء manifest أثناء التطوير
if DJANGO_ENV == "production" and not DEBUG:
    STORAGES = {
        "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
        "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"},
    }
else:
    STORAGES = {
        "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
        "staticfiles": {"BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"},
    }

# ✅ WhiteNoise: في الإنتاج الأفضل عدم الاعتماد على finders
WHITENOISE_USE_FINDERS = False if (DJANGO_ENV == "production" and not DEBUG) else True

# ✅ كاش أفضل للـ static
WHITENOISE_MAX_AGE = 31536000  # سنة


# ==================================================
# ملفات الرفع (Media)
# ==================================================
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"


# ==================================================
# الإعدادات الافتراضية
# ==================================================
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

LOGIN_URL = "/login/"
LOGIN_REDIRECT_URL = "/"


# ==================================================
# ✅ CSRF Trusted Origins (مهم مع HTTPS على Render)
# ==================================================
CSRF_TRUSTED_ORIGINS = env_csv("DJANGO_CSRF_TRUSTED_ORIGINS", "")

if DJANGO_ENV == "production" and not CSRF_TRUSTED_ORIGINS:
    CSRF_TRUSTED_ORIGINS = ["https://skillbite.onrender.com"]


# ==================================================
# إعدادات أمان إضافية في الإنتاج
# ==================================================
if DJANGO_ENV == "production":
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

    SECURE_HSTS_SECONDS = int(os.getenv("SECURE_HSTS_SECONDS", "31536000"))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = env_bool("SECURE_HSTS_INCLUDE_SUBDOMAINS", True)
    SECURE_HSTS_PRELOAD = env_bool("SECURE_HSTS_PRELOAD", True)
