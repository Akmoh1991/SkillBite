from django.conf import settings
from django.db import models
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
