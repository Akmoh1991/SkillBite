from django.contrib import admin

from .models import BusinessTenant, EmployeeProfile, JobTitle


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
