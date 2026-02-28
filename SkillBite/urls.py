from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from tenancy import views as tenancy_views

urlpatterns = [
    # Admin
    path("admin/", admin.site.urls),

    # Django Auth (login / logout / password reset)
    path("accounts/", include("django.contrib.auth.urls")),

    # Home / Landing (main screen)
    path("", tenancy_views.home, name="home"),

    # Tenancy app routes (other tenancy pages)
    path("", include("tenancy.urls")),

    # LMS SaaS apps
    path("learning/", include("learning.urls")),
    path("progress/", include("progress.urls")),
]

# ✅ Serve MEDIA files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)