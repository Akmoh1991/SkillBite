from django.contrib import admin
from django.urls import path, include
from tenancy import views as tenancy_views

urlpatterns = [
    # Admin
    path("admin/", admin.site.urls),
    path("accounts/", include("django.contrib.auth.urls")),

    # Home / Landing (main screen)
    path("", tenancy_views.home, name="home"),

    # Tenancy app routes (any other tenancy pages)
    path("", include("tenancy.urls")),

    # LMS SaaS apps
    path("learning/", include("learning.urls")),
    path("progress/", include("progress.urls")),
]
