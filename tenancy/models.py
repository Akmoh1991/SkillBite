from __future__ import annotations

from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone


class TimeStampedModel(models.Model):
    """Reusable created/updated timestamps."""
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class Tenant(TimeStampedModel):
    class Status(models.TextChoices):
        ACTIVE = "active", "Active"
        SUSPENDED = "suspended", "Suspended"
        TRIAL = "trial", "Trial"
        ARCHIVED = "archived", "Archived"

    name = models.CharField(max_length=200)
    slug = models.SlugField(max_length=80, unique=True)  # for subdomain / tenant identifier
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.TRIAL)

    # Optional branding/settings (kept JSON to avoid over-modeling early)
    settings = models.JSONField(default=dict, blank=True)

    # Optional: plan / billing metadata (kept simple in MVP)
    plan_name = models.CharField(max_length=50, blank=True, default="")
    seats_limit = models.PositiveIntegerField(default=0)  # 0 = unlimited in MVP

    class Meta:
        indexes = [
            models.Index(fields=["slug"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self) -> str:
        return self.name


class Branch(TimeStampedModel):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="branches")
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=50, blank=True, default="")  # internal code
    city = models.CharField(max_length=120, blank=True, default="")
    is_active = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "name"], name="uq_branch_tenant_name"),
        ]
        indexes = [
            models.Index(fields=["tenant", "is_active"]),
        ]

    def __str__(self) -> str:
        return f"{self.tenant.slug} / {self.name}"


class User(AbstractUser):
    """
    Multi-tenant user:
    - Most users belong to a Tenant.
    - Superusers can be global (tenant=None) if desired.
    """
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="users",
        null=True,
        blank=True,
    )

    # Optional profile fields useful for F&B
    phone = models.CharField(max_length=30, blank=True, default="")
    employee_id = models.CharField(max_length=60, blank=True, default="")
    is_tenant_admin = models.BooleanField(default=False)

    branches = models.ManyToManyField(
        Branch,
        through="UserBranch",
        related_name="users",
        blank=True,
    )

    class Meta:
        indexes = [
            models.Index(fields=["tenant", "username"]),
            models.Index(fields=["tenant", "email"]),
        ]

    def clean(self):
        super().clean()
        # If user is not a superuser, tenant should exist
        if not self.is_superuser and self.tenant is None:
            raise ValidationError("Non-superuser accounts must belong to a tenant.")

    def __str__(self) -> str:
        return f"{self.username} ({self.tenant.slug if self.tenant else 'global'})"


class UserBranch(TimeStampedModel):
    """Membership of a user in a branch (supports multi-branch assignment)."""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE)

    # Useful for HR: primary branch
    is_primary = models.BooleanField(default=False)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "branch"], name="uq_user_branch"),
        ]
        indexes = [
            models.Index(fields=["branch", "is_primary"]),
        ]

    def clean(self):
        super().clean()
        # Ensure user & branch belong to same tenant
        if self.user.tenant_id and self.branch.tenant_id and self.user.tenant_id != self.branch.tenant_id:
            raise ValidationError("User and Branch must belong to the same tenant.")


class Role(TimeStampedModel):
    """
    Roles are tenant-scoped (e.g., Cashier, Barista, Kitchen, Manager).
    Keep as data table to allow custom roles per tenant.
    """
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE, related_name="roles")
    name = models.CharField(max_length=80)

    # optional: permissions flags later
    is_manager_role = models.BooleanField(default=False)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "name"], name="uq_role_tenant_name"),
        ]
        indexes = [
            models.Index(fields=["tenant", "is_manager_role"]),
        ]

    def __str__(self) -> str:
        return f"{self.tenant.slug} / {self.name}"


class UserRole(TimeStampedModel):
    """Assign role(s) to user within the same tenant."""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="role_links")
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name="user_links")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "role"], name="uq_user_role"),
        ]
        indexes = [
            models.Index(fields=["role"]),
        ]

    def clean(self):
        super().clean()
        # Ensure same tenant
        if self.user.tenant_id and self.role.tenant_id and self.user.tenant_id != self.role.tenant_id:
            raise ValidationError("User and Role must belong to the same tenant.")