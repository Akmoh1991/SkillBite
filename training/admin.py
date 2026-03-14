from django.contrib import admin

from .models import (
    Course,
    CourseAssignment,
    CourseAssignmentRule,
    CourseContentItem,
    SOPChecklist,
    SOPChecklistAssignmentRule,
    SOPChecklistCompletion,
    SOPChecklistItem,
    SOPChecklistItemCompletion,
)


class CourseContentItemInline(admin.TabularInline):
    model = CourseContentItem
    extra = 0


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('title', 'business', 'estimated_minutes', 'is_active', 'created_by')
    search_fields = ('title', 'business__name')
    list_filter = ('business', 'is_active')
    inlines = [CourseContentItemInline]


@admin.register(CourseContentItem)
class CourseContentItemAdmin(admin.ModelAdmin):
    list_display = ('title', 'course', 'content_type', 'order', 'updated_at')
    search_fields = ('title', 'course__title', 'course__business__name')
    list_filter = ('content_type', 'course__business')


@admin.register(CourseAssignmentRule)
class CourseAssignmentRuleAdmin(admin.ModelAdmin):
    list_display = ('business', 'job_title', 'course', 'assigned_by', 'created_at')
    search_fields = ('business__name', 'job_title__name', 'course__title')
    list_filter = ('business', 'job_title')


@admin.register(CourseAssignment)
class CourseAssignmentAdmin(admin.ModelAdmin):
    list_display = ('employee', 'business', 'course', 'status', 'assigned_via_job_title', 'assigned_at', 'completed_at')
    search_fields = ('employee__username', 'business__name', 'course__title')
    list_filter = ('business', 'status', 'assigned_via_job_title')


class SOPChecklistItemInline(admin.TabularInline):
    model = SOPChecklistItem
    extra = 0


@admin.register(SOPChecklist)
class SOPChecklistAdmin(admin.ModelAdmin):
    list_display = ('title', 'business', 'frequency', 'is_active', 'created_by')
    search_fields = ('title', 'business__name')
    list_filter = ('business', 'frequency', 'is_active')
    inlines = [SOPChecklistItemInline]


@admin.register(SOPChecklistAssignmentRule)
class SOPChecklistAssignmentRuleAdmin(admin.ModelAdmin):
    list_display = ('business', 'job_title', 'checklist', 'assigned_by', 'created_at')
    search_fields = ('business__name', 'job_title__name', 'checklist__title')
    list_filter = ('business', 'job_title')


@admin.register(SOPChecklistCompletion)
class SOPChecklistCompletionAdmin(admin.ModelAdmin):
    list_display = ('employee', 'business', 'checklist', 'completed_for', 'completed_at')
    search_fields = ('employee__username', 'business__name', 'checklist__title')
    list_filter = ('business', 'completed_for')


@admin.register(SOPChecklistItemCompletion)
class SOPChecklistItemCompletionAdmin(admin.ModelAdmin):
    list_display = ('completion', 'item', 'is_checked', 'checked_at')
    search_fields = ('completion__employee__username', 'item__title')
    list_filter = ('is_checked',)
