import hashlib
import secrets

from django.conf import settings
from django.db import models
from django.utils import timezone
from django.utils.text import slugify


User = settings.AUTH_USER_MODEL


class BusinessTenant(models.Model):
    owner = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='owned_business',
        verbose_name='Business owner',
    )
    name = models.CharField(
        max_length=255,
        verbose_name='Business name',
    )
    slug = models.SlugField(
        max_length=255,
        unique=True,
        verbose_name='Slug',
    )
    industry = models.CharField(
        max_length=100,
        default='Food & Beverage',
        verbose_name='Industry',
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'Business tenant'
        verbose_name_plural = 'Business tenants'
        ordering = ['name', 'id']

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            base_slug = slugify(self.name) or f'business-{self.owner_id or "tenant"}'
            candidate = base_slug
            suffix = 2
            while BusinessTenant.objects.exclude(pk=self.pk).filter(slug=candidate).exists():
                candidate = f'{base_slug}-{suffix}'
                suffix += 1
            self.slug = candidate
        super().save(*args, **kwargs)


class JobTitle(models.Model):
    business = models.ForeignKey(
        BusinessTenant,
        on_delete=models.CASCADE,
        related_name='job_titles',
        verbose_name='Business',
    )
    name = models.CharField(
        max_length=150,
        verbose_name='Job title',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'Job title'
        verbose_name_plural = 'Job titles'
        ordering = ['name', 'id']
        constraints = [
            models.UniqueConstraint(fields=['business', 'name'], name='unique_job_title_per_business'),
        ]

    def __str__(self):
        return f'{self.business.name} - {self.name}'


class EmployeeProfile(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='employee_profile',
        verbose_name='Employee user',
    )
    business = models.ForeignKey(
        BusinessTenant,
        on_delete=models.CASCADE,
        related_name='employees',
        verbose_name='Business',
    )
    job_title = models.ForeignKey(
        JobTitle,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='employees',
        verbose_name='Job title',
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_employee_profiles',
        verbose_name='Created by',
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'Employee profile'
        verbose_name_plural = 'Employee profiles'
        ordering = ['business__name', 'user__username']

    def __str__(self):
        return f'{self.user} - {self.business.name}'


class MobileAuthToken(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='mobile_auth_tokens',
        verbose_name='User',
    )
    label = models.CharField(
        max_length=120,
        default='flutter-mobile',
        verbose_name='Label',
    )
    token_hash = models.CharField(
        max_length=64,
        unique=True,
        verbose_name='Token hash',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )
    last_used_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Last used at',
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Expires at',
    )
    revoked_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Revoked at',
    )

    class Meta:
        verbose_name = 'Mobile auth token'
        verbose_name_plural = 'Mobile auth tokens'
        ordering = ['-created_at', '-id']

    def __str__(self):
        return f'{self.user} [{self.label}]'

    @staticmethod
    def _hash_token(raw_token: str) -> str:
        return hashlib.sha256((raw_token or '').encode('utf-8')).hexdigest()

    @classmethod
    def issue(cls, *, user, label: str = 'flutter-mobile', expires_at=None) -> tuple['MobileAuthToken', str]:
        raw_token = f'skbm_{secrets.token_urlsafe(32)}'
        token = cls.objects.create(
            user=user,
            label=(label or 'flutter-mobile').strip()[:120] or 'flutter-mobile',
            token_hash=cls._hash_token(raw_token),
            expires_at=expires_at,
            last_used_at=timezone.now(),
        )
        return token, raw_token

    @classmethod
    def find_active(cls, raw_token: str):
        token_hash = cls._hash_token(raw_token)
        now = timezone.now()
        return (
            cls.objects.select_related('user')
            .filter(token_hash=token_hash, revoked_at__isnull=True, user__is_active=True)
            .filter(models.Q(expires_at__isnull=True) | models.Q(expires_at__gt=now))
            .first()
        )

    def touch(self) -> None:
        self.last_used_at = timezone.now()
        self.save(update_fields=['last_used_at'])

    def revoke(self) -> None:
        if self.revoked_at is None:
            self.revoked_at = timezone.now()
            self.save(update_fields=['revoked_at'])
