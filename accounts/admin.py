from django.contrib import admin
from .models import (
    BusinessTenant,
    ContractorDocument,
    ContractorProfile,
    EmployeeProfile,
    JobTitle,
    TrainerProfile,
)


@admin.register(ContractorProfile)
class ContractorProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'company_name', 'phone_number', 'is_training_coordinator', 'registered_by')
    search_fields = ('user__username', 'company_name', 'phone_number', 'registered_by__username')
    list_filter = ('is_training_coordinator', 'region')


@admin.register(TrainerProfile)
class TrainerProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'specialization')
    search_fields = ('user__username', 'specialization')


@admin.register(ContractorDocument)
class ContractorDocumentAdmin(admin.ModelAdmin):
    list_display = ('id', 'owner', 'title', 'pdf_file', 'uploaded_at')
    search_fields = ('owner__username', 'title', 'pdf_file')
    list_filter = ('uploaded_at',)


@admin.register(BusinessTenant)
class BusinessTenantAdmin(admin.ModelAdmin):
    list_display = ('name', 'owner', 'industry', 'is_active', 'created_at')
    search_fields = ('name', 'owner__username', 'owner__email', 'slug')
    list_filter = ('is_active', 'industry')


@admin.register(JobTitle)
class JobTitleAdmin(admin.ModelAdmin):
    list_display = ('name', 'business', 'created_at')
    search_fields = ('name', 'business__name')
    list_filter = ('business',)


@admin.register(EmployeeProfile)
class EmployeeProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'business', 'job_title', 'is_active', 'created_by', 'created_at')
    search_fields = ('user__username', 'user__email', 'business__name', 'job_title__name')
    list_filter = ('business', 'job_title', 'is_active')
