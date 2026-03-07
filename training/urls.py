from django.urls import path
from .views import (
    training_program_categories_view,
    training_programs_list_view,
    create_registration,
    apply_renewal,
)

app_name = 'training'

urlpatterns = [
    path(
        'categories/',
        training_program_categories_view,
        name='program_categories',
    ),
    path(
        '',
        training_programs_list_view,
        name='programs_list',
    ),
    path(
        'register/<int:program_id>/',
        create_registration,
        name='create_registration',
    ),
    path(
        'renew/<int:certificate_id>/',
        apply_renewal,
        name='apply_renewal',
    ),
]
