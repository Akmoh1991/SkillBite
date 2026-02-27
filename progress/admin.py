# progress/admin.py
from __future__ import annotations

from django.contrib import admin

from .models import (
    Enrollment,
    Assignment,
    LessonProgress,
    QuizAttempt,
    QuizAnswer,
    ChecklistRun,
    ChecklistItemResult,
    Certificate,
)


@admin.register(Enrollment)
class EnrollmentAdmin(admin.ModelAdmin):
    list_display = ("user", "tenant", "course", "path", "enrolled_at", "completed_at")
    list_filter = ("tenant", "completed_at")
    search_fields = ("user__username", "user__email", "tenant__name", "tenant__slug", "course__title", "path__title")
    readonly_fields = ("created_at", "updated_at")


@admin.register(Assignment)
class AssignmentAdmin(admin.ModelAdmin):
    list_display = (
        "tenant",
        "kind",
        "course",
        "path",
        "target_user",
        "target_branch",
        "target_role",
        "due_at",
        "is_active",
        "created_at",
    )
    list_filter = ("tenant", "kind", "is_active", "due_at")
    search_fields = (
        "tenant__name",
        "tenant__slug",
        "course__title",
        "path__title",
        "target_user__username",
        "target_branch__name",
        "target_role__name",
    )
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("course", "path", "target_user", "target_branch", "target_role", "created_by")


@admin.register(LessonProgress)
class LessonProgressAdmin(admin.ModelAdmin):
    list_display = ("user", "tenant", "lesson", "percent", "last_activity_at", "completed_at")
    list_filter = ("tenant", "completed_at")
    search_fields = ("user__username", "tenant__name", "tenant__slug", "lesson__title")
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("user", "lesson")


@admin.register(QuizAttempt)
class QuizAttemptAdmin(admin.ModelAdmin):
    list_display = ("user", "tenant", "quiz", "score_percent", "passed", "started_at", "submitted_at")
    list_filter = ("tenant", "passed", "submitted_at")
    search_fields = ("user__username", "tenant__name", "tenant__slug", "quiz__title")
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("user", "quiz")


@admin.register(QuizAnswer)
class QuizAnswerAdmin(admin.ModelAdmin):
    list_display = ("attempt", "question_id", "choice_id", "created_at", "updated_at")
    list_filter = ("attempt__tenant",)
    search_fields = ("attempt__user__username", "attempt__quiz__title")
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("attempt",)


class ChecklistItemResultInline(admin.TabularInline):
    model = ChecklistItemResult
    extra = 0
    fields = ("item", "is_done", "comment")
    autocomplete_fields = ("item",)


@admin.register(ChecklistRun)
class ChecklistRunAdmin(admin.ModelAdmin):
    list_display = ("tenant", "template", "branch", "performed_by", "performed_at", "approved_by", "approved_at")
    list_filter = ("tenant", "performed_at", "approved_at")
    search_fields = (
        "tenant__name",
        "tenant__slug",
        "template__title",
        "branch__name",
        "performed_by__username",
        "approved_by__username",
    )
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("template", "branch", "performed_by", "approved_by")
    inlines = [ChecklistItemResultInline]


@admin.register(ChecklistItemResult)
class ChecklistItemResultAdmin(admin.ModelAdmin):
    list_display = ("run", "item", "is_done", "created_at", "updated_at")
    list_filter = ("run__tenant", "is_done")
    search_fields = ("run__template__title", "item__text")
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("run", "item")


@admin.register(Certificate)
class CertificateAdmin(admin.ModelAdmin):
    list_display = ("user", "tenant", "course", "path", "code", "issued_at")
    list_filter = ("tenant", "issued_at")
    search_fields = ("user__username", "tenant__name", "tenant__slug", "course__title", "path__title", "code")
    readonly_fields = ("created_at", "updated_at")
    autocomplete_fields = ("user", "course", "path")