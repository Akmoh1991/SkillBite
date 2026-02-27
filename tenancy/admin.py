# tenancy/admin.py
from __future__ import annotations

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from django.utils.translation import gettext_lazy as _

from .models import Tenant, Branch, User, UserBranch, Role, UserRole


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "status", "plan_name", "seats_limit", "created_at", "updated_at")
    list_filter = ("status", "plan_name")
    search_fields = ("name", "slug")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("name",)


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ("name", "tenant", "city", "is_active", "created_at", "updated_at")
    list_filter = ("tenant", "is_active", "city")
    search_fields = ("name", "code", "city", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("tenant__name", "name")


class UserBranchInline(admin.TabularInline):
    model = UserBranch
    extra = 1
    autocomplete_fields = ("branch",)


class UserRoleInline(admin.TabularInline):
    model = UserRole
    extra = 1
    autocomplete_fields = ("role",)


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    """
    Extends Django's UserAdmin to support tenant fields and relations.
    """
    list_display = ("username", "email", "tenant", "is_tenant_admin", "is_staff", "is_active")
    list_filter = ("tenant", "is_tenant_admin", "is_staff", "is_active", "is_superuser")
    search_fields = ("username", "email", "first_name", "last_name", "tenant__name", "tenant__slug")
    ordering = ("tenant__name", "username")

    fieldsets = (
        (None, {"fields": ("username", "password")}),
        (_("Personal info"), {"fields": ("first_name", "last_name", "email", "phone", "employee_id")}),
        (_("Tenant"), {"fields": ("tenant", "is_tenant_admin")}),
        (_("Permissions"), {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        (_("Important dates"), {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("username", "email", "tenant", "password1", "password2", "is_tenant_admin", "is_staff", "is_active"),
        }),
    )

    inlines = [UserBranchInline, UserRoleInline]


@admin.register(UserBranch)
class UserBranchAdmin(admin.ModelAdmin):
    list_display = ("user", "branch", "is_primary", "created_at", "updated_at")
    list_filter = ("is_primary", "branch__tenant")
    search_fields = ("user__username", "branch__name", "branch__tenant__name", "branch__tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("user", "branch")


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ("name", "tenant", "is_manager_role", "created_at", "updated_at")
    list_filter = ("tenant", "is_manager_role")
    search_fields = ("name", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("tenant__name", "name")


@admin.register(UserRole)
class UserRoleAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "created_at", "updated_at")
    list_filter = ("role__tenant", "role__is_manager_role")
    search_fields = ("user__username", "role__name", "role__tenant__name", "role__tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("user", "role")