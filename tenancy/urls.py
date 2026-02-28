from django.urls import path
from . import views

app_name = "tenancy"

urlpatterns = [
    path("", views.home, name="home"),
]