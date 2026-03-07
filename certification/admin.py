from django.contrib import admin
from .models import Certificate, ScormCertificate


@admin.register(Certificate)
class CertificateAdmin(admin.ModelAdmin):
    list_display = (
        'owner',
        'program',
        'certificate_type',
        'issued_at',
        'expires_at',
        'verification_code',
    )
    list_filter = (
        'certificate_type',
        'issued_at',
        'expires_at',
    )
    search_fields = (
        'owner__username',
        'program__title',
        'verification_code',
    )
    readonly_fields = ('issued_at',)


@admin.register(ScormCertificate)
class ScormCertificateAdmin(admin.ModelAdmin):
    list_display = ('owner', 'course_name', 'issued_at', 'expires_at', 'verification_code')
    search_fields = ('course_name', 'scorm_filename', 'verification_code')
