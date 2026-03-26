from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from accounts.views import scorm_zip_download_view


urlpatterns = [
    # Protect SCORM ZIP downloads (contractors must not download)
    path('media/scorm/<path:filename>', scorm_zip_download_view, name='scorm_zip_download'),
    path('api/mobile/v1/', include('accounts.api_urls')),

    # الشاشة الرئيسية (accounts هو المسؤول)
    path('', include('accounts.urls')),

    # لوحة تحكم الأدمن
    path('admin/', admin.site.urls),
]


# ==================================================
# خدمة ملفات Media أثناء التطوير فقط
# ==================================================
if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL,
        document_root=settings.MEDIA_ROOT
    )
