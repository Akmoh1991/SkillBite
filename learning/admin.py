# learning/admin.py
from __future__ import annotations

from django.contrib import admin

from .models import (
    Course,
    LearningPath,
    LearningPathCourse,
    Module,
    Lesson,
    Resource,
    SOP,
    SOPVersion,
    ChecklistTemplate,
    ChecklistItem,
    Quiz,
    Question,
    Choice,
)


class LearningPathCourseInline(admin.TabularInline):
    model = LearningPathCourse
    extra = 1
    autocomplete_fields = ("course",)
    ordering = ("order",)


@admin.register(LearningPath)
class LearningPathAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "status", "available_to_all_branches", "created_at", "updated_at")
    list_filter = ("tenant", "status", "available_to_all_branches")
    search_fields = ("title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    inlines = [LearningPathCourseInline]


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "status", "estimated_minutes", "available_to_all_branches", "created_at", "updated_at")
    list_filter = ("tenant", "status", "available_to_all_branches")
    search_fields = ("title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    filter_horizontal = ("branches",)


class LessonInline(admin.TabularInline):
    model = Lesson
    extra = 0
    ordering = ("order",)
    fields = ("order", "title", "kind", "video_url", "sop", "checklist_template", "quiz")
    show_change_link = True


@admin.register(Module)
class ModuleAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "course", "order", "created_at", "updated_at")
    list_filter = ("tenant", "course")
    search_fields = ("title", "course__title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("course__title", "order")
    inlines = [LessonInline]


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "module", "order", "kind", "created_at", "updated_at")
    list_filter = ("tenant", "kind", "module__course")
    search_fields = ("title", "module__title", "module__course__title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("module__course__title", "module__order", "order")


@admin.register(Resource)
class ResourceAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "created_at", "updated_at")
    list_filter = ("tenant",)
    search_fields = ("title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")


class SOPVersionInline(admin.TabularInline):
    model = SOPVersion
    extra = 1
    ordering = ("-version",)
    fields = ("version", "published_at", "content")
    show_change_link = True


@admin.register(SOP)
class SOPAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "is_active", "created_at", "updated_at")
    list_filter = ("tenant", "is_active")
    search_fields = ("title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    inlines = [SOPVersionInline]


@admin.register(SOPVersion)
class SOPVersionAdmin(admin.ModelAdmin):
    list_display = ("sop", "version", "published_at", "created_at", "updated_at")
    list_filter = ("sop__tenant", "published_at")
    search_fields = ("sop__title", "sop__tenant__name", "sop__tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("-published_at", "-version")


class ChecklistItemInline(admin.TabularInline):
    model = ChecklistItem
    extra = 1
    ordering = ("order",)
    fields = ("order", "text", "is_required")


@admin.register(ChecklistTemplate)
class ChecklistTemplateAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "is_active", "created_at", "updated_at")
    list_filter = ("tenant", "is_active")
    search_fields = ("title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    inlines = [ChecklistItemInline]


@admin.register(ChecklistItem)
class ChecklistItemAdmin(admin.ModelAdmin):
    list_display = ("template", "order", "text", "is_required", "created_at", "updated_at")
    list_filter = ("template__tenant", "is_required")
    search_fields = ("text", "template__title", "template__tenant__name", "template__tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("template__title", "order")


class ChoiceInline(admin.TabularInline):
    model = Choice
    extra = 2
    fields = ("text", "is_correct")


class QuestionInline(admin.TabularInline):
    model = Question
    extra = 1
    ordering = ("order",)
    fields = ("order", "text")
    show_change_link = True


@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    list_display = ("title", "tenant", "passing_score", "max_attempts", "created_at", "updated_at")
    list_filter = ("tenant",)
    search_fields = ("title", "tenant__name", "tenant__slug")
    readonly_fields = ("created_at", "updated_at")
    inlines = [QuestionInline]


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ("quiz", "order", "created_at", "updated_at")
    list_filter = ("quiz__tenant",)
    search_fields = ("quiz__title", "quiz__tenant__name", "quiz__tenant__slug", "text")
    readonly_fields = ("created_at", "updated_at")
    ordering = ("quiz__title", "order")
    inlines = [ChoiceInline]


@admin.register(Choice)
class ChoiceAdmin(admin.ModelAdmin):
    list_display = ("question", "is_correct", "created_at", "updated_at")
    list_filter = ("question__quiz__tenant", "is_correct")
    search_fields = ("question__quiz__title", "question__text", "text")
    readonly_fields = ("created_at", "updated_at")