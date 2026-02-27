from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),

    # Home / Landing (main screen)
    path('', include('tenancy.urls')),

    # LMS SaaS apps
    path('learning/', include('learning.urls')),
    path('progress/', include('progress.urls')),
]