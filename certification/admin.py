from django.contrib import admin

from .models import ScormCertificate


@admin.register(ScormCertificate)
class ScormCertificateAdmin(admin.ModelAdmin):
    list_display = ('owner', 'course_name', 'issued_at', 'expires_at', 'verification_code')
    search_fields = ('course_name', 'scorm_filename', 'verification_code')
