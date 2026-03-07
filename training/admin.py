from django.contrib import admin
from .models import (
    Course,
    CourseAssignment,
    CourseAssignmentRule,
    EnrollmentRequest,
    ExamAttempt,
    ExamTemplate,
    Program,
    SOPChecklist,
    SOPChecklistAssignmentRule,
    SOPChecklistCompletion,
    SOPChecklistItem,
    SOPChecklistItemCompletion,
)


@admin.register(Program)
class ProgramAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'program_type',
        'program_subcategory',
        'outcome_type',
        'requires_approval',
        'requires_payment',
        'is_active',
    )
    list_filter = (
        'program_type',
        'program_subcategory',
        'outcome_type',
        'requires_approval',
        'requires_payment',
        'is_active',
    )
    search_fields = ('title', 'title_ar', 'title_en', 'program_subcategory')


@admin.register(ExamTemplate)
class ExamTemplateAdmin(admin.ModelAdmin):
    list_display = (
        'name',
        'duration_minutes',
        'total_questions',
        'created_by',
    )
    search_fields = ('name', 'created_by__username')


@admin.register(EnrollmentRequest)
class EnrollmentRequestAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'contractor',
        'program',
        'status',
        'trainer',
        'created_at',
    )
    list_filter = (
        'status',
        'program__program_type',
    )
    search_fields = (
        'contractor__username',
        'program__title',
        'invoice_number',
    )
    readonly_fields = ('created_at',)


@admin.register(ExamAttempt)
class ExamAttemptAdmin(admin.ModelAdmin):
    list_display = (
        'enrollment',
        'started_at',
        'completed_at',
        'score',
        'passed',
    )
    list_filter = ('passed',)
    readonly_fields = ('started_at',)


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('title', 'business', 'estimated_minutes', 'is_active', 'created_by')
    search_fields = ('title', 'business__name')
    list_filter = ('business', 'is_active')


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
