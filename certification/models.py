import calendar
from datetime import datetime

from django.conf import settings
from django.db import models
from django.utils import timezone
from training.models import Program, EnrollmentRequest


User = settings.AUTH_USER_MODEL



class Certificate(models.Model):
    """
    شهادة أو بطاقة اجتياز
    """

    class CertificateType(models.TextChoices):
        CERTIFICATE = 'CERTIFICATE', 'شهادة'
        PASS_CARD = 'PASS_CARD', 'بطاقة اجتياز'

    owner = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='certificates',
        verbose_name='المستفيد'
    )

    program = models.ForeignKey(
        Program,
        on_delete=models.CASCADE,
        verbose_name='البرنامج التدريبي'
    )

    enrollment = models.OneToOneField(
        EnrollmentRequest,
        on_delete=models.CASCADE,
        verbose_name='طلب التسجيل'
    )

    certificate_type = models.CharField(
        max_length=20,
        choices=CertificateType.choices,
        verbose_name='نوع الاعتماد'
    )

    issued_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='تاريخ الإصدار'
    )

    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        db_index=True,
        verbose_name='تاريخ انتهاء الصلاحية'
    )

    pdf_file = models.FileField(
        upload_to='certificates/',
        blank=True,
        null=True,
        verbose_name='ملف الشهادة'
    )

    verification_code = models.CharField(
        max_length=100,
        unique=True,
        verbose_name='رمز التحقق'
    )

    class Meta:
        verbose_name = 'شهادة / بطاقة اجتياز'
        verbose_name_plural = 'الشهادات وبطاقات الاجتياز'

    def __str__(self):
        return f"{self.owner} - {self.program}"

    @staticmethod
    def _add_months(dt: datetime, months: int) -> datetime:
        if dt is None:
            return dt
        month0 = dt.month - 1 + months
        year = dt.year + month0 // 12
        month = month0 % 12 + 1
        last_day = calendar.monthrange(year, month)[1]
        day = min(dt.day, last_day)
        return dt.replace(year=year, month=month, day=day)

    @staticmethod
    def _add_years(dt: datetime, years: int) -> datetime:
        if dt is None:
            return dt
        try:
            return dt.replace(year=dt.year + years)
        except ValueError:
            # Feb 29 -> Feb 28 on non-leap years
            if dt.month == 2 and dt.day == 29:
                return dt.replace(year=dt.year + years, day=28)
            raise

    def _compute_expires_at(self) -> datetime | None:
        issued = getattr(self, 'issued_at', None)
        if not issued:
            return None
        return self._add_years(issued, 3)

    def ensure_expires_at(self) -> None:
        if self.expires_at:
            return
        computed = self._compute_expires_at()
        if computed:
            self.expires_at = computed

    @property
    def renewal_window_starts_at(self):
        if not self.expires_at:
            return None
        months_before_expiry = 6
        program = getattr(self, 'program', None)
        if program is not None:
            try:
                configured = int(getattr(program, 'renewal_window_months', 6) or 6)
                if configured > 0:
                    months_before_expiry = configured
            except Exception:
                months_before_expiry = 6
        return self._add_months(self.expires_at, -months_before_expiry)

    @property
    def is_expired(self) -> bool:
        if not self.expires_at:
            return False
        return timezone.now() >= self.expires_at

    @property
    def is_within_renewal_window(self) -> bool:
        if not self.expires_at:
            return False
        now = timezone.now()
        start = self.renewal_window_starts_at
        if not start:
            return False
        return start <= now < self.expires_at

    def save(self, *args, **kwargs):
        # issued_at is auto_now_add and may not exist until the first insert.
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


class ScormCertificate(models.Model):
    """PDF certificate for completing a SCORM package (course-level completion)."""

    owner = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='scorm_certificates',
        verbose_name='المستفيد'
    )

    course_name = models.CharField(max_length=255, verbose_name='اسم الدورة')
    scorm_filename = models.CharField(max_length=255, verbose_name='ملف SCORM')

    issued_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='تاريخ الإصدار'
    )

    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        db_index=True,
        verbose_name='تاريخ انتهاء الصلاحية'
    )

    pdf_file = models.FileField(
        upload_to='certificates/',
        blank=True,
        null=True,
        verbose_name='ملف الشهادة'
    )

    verification_code = models.CharField(
        max_length=100,
        unique=True,
        verbose_name='رمز التحقق'
    )

    class Meta:
        verbose_name = 'شهادة SCORM'
        verbose_name_plural = 'شهادات SCORM'
        constraints = [
            models.UniqueConstraint(
                fields=['owner', 'scorm_filename'],
                name='unique_scorm_certificate_per_user_file'
            )
        ]

    def __str__(self):
        return f"{self.owner} - {self.course_name}"

    def _compute_expires_at(self) -> datetime | None:
        issued = getattr(self, 'issued_at', None)
        if not issued:
            return None
        return Certificate._add_years(issued, 3)

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
