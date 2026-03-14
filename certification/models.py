import calendar
from datetime import datetime

from django.conf import settings
from django.db import models


User = settings.AUTH_USER_MODEL


class ScormCertificate(models.Model):
    owner = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='scorm_certificates',
        verbose_name='Beneficiary',
    )
    course_name = models.CharField(
        max_length=255,
        verbose_name='Course name',
    )
    scorm_filename = models.CharField(
        max_length=255,
        verbose_name='SCORM package',
    )
    issued_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Issued at',
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        db_index=True,
        verbose_name='Expires at',
    )
    pdf_file = models.FileField(
        upload_to='certificates/',
        blank=True,
        null=True,
        verbose_name='Certificate file',
    )
    verification_code = models.CharField(
        max_length=100,
        unique=True,
        verbose_name='Verification code',
    )

    class Meta:
        verbose_name = 'SCORM certificate'
        verbose_name_plural = 'SCORM certificates'
        constraints = [
            models.UniqueConstraint(
                fields=['owner', 'scorm_filename'],
                name='unique_scorm_certificate_per_user_file',
            )
        ]

    def __str__(self):
        return f'{self.owner} - {self.course_name}'

    @staticmethod
    def _add_years(dt: datetime, years: int) -> datetime:
        try:
            return dt.replace(year=dt.year + years)
        except ValueError:
            if dt.month == 2 and dt.day == 29:
                return dt.replace(year=dt.year + years, day=28)
            month_days = calendar.monthrange(dt.year + years, dt.month)[1]
            return dt.replace(year=dt.year + years, day=min(dt.day, month_days))

    def _compute_expires_at(self) -> datetime | None:
        issued = getattr(self, 'issued_at', None)
        if not issued:
            return None
        return self._add_years(issued, 3)

    def save(self, *args, **kwargs):
        if self.pk is None and not getattr(self, 'issued_at', None):
            super().save(*args, **kwargs)
            if not self.expires_at:
                self.expires_at = self._compute_expires_at()
                if self.expires_at:
                    super().save(update_fields=['expires_at'])
            return

        if not self.expires_at:
            self.expires_at = self._compute_expires_at()
        super().save(*args, **kwargs)
