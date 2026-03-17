from django.conf import settings
from django.db import models
from django.utils import timezone


User = settings.AUTH_USER_MODEL


class Course(models.Model):
    business = models.ForeignKey(
        'accounts.BusinessTenant',
        on_delete=models.CASCADE,
        related_name='courses',
        verbose_name='Business',
    )
    title = models.CharField(
        max_length=255,
        verbose_name='Course title',
    )
    description = models.TextField(
        blank=True,
        default='',
        verbose_name='Description',
    )
    estimated_minutes = models.PositiveIntegerField(
        default=15,
        verbose_name='Estimated duration (minutes)',
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active',
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_lms_courses',
        verbose_name='Created by',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )
    exam_template = models.ForeignKey(
        'ExamTemplate',
        on_delete=models.SET_NULL,
        related_name='courses',
        null=True,
        blank=True,
        verbose_name='Exam template',
    )

    class Meta:
        verbose_name = 'Course'
        verbose_name_plural = 'Courses'
        ordering = ['title', 'id']

    def __str__(self):
        return self.title


class CourseContentItem(models.Model):
    class ContentType(models.TextChoices):
        LESSON = 'LESSON', 'Lesson'
        TEXT = 'TEXT', 'Text'
        MATERIAL = 'MATERIAL', 'Material'

    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='content_items',
        verbose_name='Course',
    )
    content_type = models.CharField(
        max_length=20,
        choices=ContentType.choices,
        default=ContentType.LESSON,
        verbose_name='Content type',
    )
    title = models.CharField(
        max_length=255,
        verbose_name='Title',
    )
    body = models.TextField(
        blank=True,
        default='',
        verbose_name='Body',
    )
    material_url = models.URLField(
        blank=True,
        default='',
        verbose_name='Material URL',
    )
    video_file = models.FileField(
        upload_to='course_content_videos/',
        blank=True,
        default='',
        verbose_name='Video file',
    )
    pdf_file = models.FileField(
        upload_to='course_content_pdfs/',
        blank=True,
        default='',
        verbose_name='PDF file',
    )
    order = models.PositiveIntegerField(
        default=1,
        verbose_name='Display order',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Updated at',
    )

    class Meta:
        verbose_name = 'Course content item'
        verbose_name_plural = 'Course content items'
        ordering = ['order', 'id']

    def __str__(self):
        return f'{self.course.title} - {self.title}'


class CourseAssignment(models.Model):
    class Status(models.TextChoices):
        ASSIGNED = 'ASSIGNED', 'Assigned'
        IN_PROGRESS = 'IN_PROGRESS', 'In progress'
        COMPLETED = 'COMPLETED', 'Completed'

    business = models.ForeignKey(
        'accounts.BusinessTenant',
        on_delete=models.CASCADE,
        related_name='course_assignments',
        verbose_name='Business',
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='assignments',
        verbose_name='Course',
    )
    employee = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='course_assignments',
        verbose_name='Employee',
    )
    assigned_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_courses',
        verbose_name='Assigned by',
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.ASSIGNED,
        verbose_name='Status',
    )
    assigned_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Assigned at',
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Completed at',
    )

    class Meta:
        verbose_name = 'Course assignment'
        verbose_name_plural = 'Course assignments'
        ordering = ['-assigned_at', '-id']
        constraints = [
            models.UniqueConstraint(fields=['course', 'employee'], name='unique_course_assignment_per_employee'),
        ]

    def __str__(self):
        return f'{self.employee} - {self.course}'


class ExamTemplate(models.Model):
    business = models.ForeignKey(
        'accounts.BusinessTenant',
        on_delete=models.CASCADE,
        related_name='exam_templates',
        null=True,
        blank=True,
        verbose_name='Business',
    )
    name = models.CharField(
        max_length=255,
        verbose_name='Exam template name',
    )
    duration_minutes = models.PositiveIntegerField(
        verbose_name='Exam duration (minutes)',
    )
    total_questions = models.PositiveIntegerField(
        default=0,
        verbose_name='Total questions',
    )
    instructions = models.TextField(
        blank=True,
        default='',
        verbose_name='Instructions',
    )
    passing_score_percent = models.PositiveSmallIntegerField(
        default=60,
        verbose_name='Passing score %',
    )
    show_result_after_submit = models.BooleanField(
        default=True,
        verbose_name='Show result after submit',
    )
    shuffle_questions = models.BooleanField(
        default=True,
        verbose_name='Shuffle questions',
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='exam_templates',
        verbose_name='Created by',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Updated at',
    )

    class Meta:
        verbose_name = 'Exam template'
        verbose_name_plural = 'Exam templates'
        ordering = ['-created_at', '-id']

    def __str__(self):
        return self.name


class ExamQuestion(models.Model):
    class QuestionType(models.TextChoices):
        MCQ_SINGLE = 'MCQ_SINGLE', 'Single choice'
        MCQ_MULTI = 'MCQ_MULTI', 'Multiple choice'
        TRUE_FALSE = 'TRUE_FALSE', 'True / False'
        SHORT_ANSWER = 'SHORT_ANSWER', 'Short answer'
        ESSAY = 'ESSAY', 'Essay'

    template = models.ForeignKey(
        ExamTemplate,
        on_delete=models.CASCADE,
        related_name='questions',
        verbose_name='Exam template',
    )
    order = models.PositiveIntegerField(
        default=1,
        verbose_name='Order',
    )
    question_text = models.TextField(
        verbose_name='Question text',
    )
    question_type = models.CharField(
        max_length=20,
        choices=QuestionType.choices,
        default=QuestionType.MCQ_SINGLE,
        verbose_name='Question type',
    )
    points = models.PositiveSmallIntegerField(
        default=1,
        verbose_name='Points',
    )
    is_required = models.BooleanField(
        default=True,
        verbose_name='Required',
    )
    shuffle_options = models.BooleanField(
        default=True,
        verbose_name='Shuffle options',
    )
    explanation = models.TextField(
        blank=True,
        default='',
        verbose_name='Explanation',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'Exam question'
        verbose_name_plural = 'Exam questions'
        ordering = ['order', 'id']
        constraints = [
            models.UniqueConstraint(fields=['template', 'order'], name='unique_question_order_per_template'),
        ]

    def __str__(self):
        return f'{self.template} - Q{self.order}'


class ExamOption(models.Model):
    question = models.ForeignKey(
        ExamQuestion,
        on_delete=models.CASCADE,
        related_name='options',
        verbose_name='Question',
    )
    order = models.PositiveIntegerField(
        default=1,
        verbose_name='Order',
    )
    option_text = models.CharField(
        max_length=500,
        verbose_name='Option text',
    )
    is_correct = models.BooleanField(
        default=False,
        verbose_name='Correct answer',
    )

    class Meta:
        verbose_name = 'Exam option'
        verbose_name_plural = 'Exam options'
        ordering = ['order', 'id']
        constraints = [
            models.UniqueConstraint(fields=['question', 'order'], name='unique_option_order_per_question'),
        ]

    def __str__(self):
        return f'{self.question} - {self.order}'


class CourseExamSession(models.Model):
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='exam_sessions',
        verbose_name='Course',
    )
    exam_template = models.ForeignKey(
        ExamTemplate,
        on_delete=models.SET_NULL,
        related_name='course_sessions',
        null=True,
        blank=True,
        verbose_name='Exam template',
    )
    exam_date = models.DateTimeField(
        verbose_name='Exam date',
    )
    access_code = models.CharField(
        max_length=32,
        blank=True,
        default='',
        verbose_name='Access code',
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active',
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_course_exam_sessions',
        verbose_name='Created by',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'Course exam session'
        verbose_name_plural = 'Course exam sessions'
        ordering = ['-exam_date', '-id']

    def __str__(self):
        return f'{self.course} - {self.exam_date:%Y-%m-%d %H:%M}'


class SOPChecklist(models.Model):
    class Frequency(models.TextChoices):
        DAILY = 'DAILY', 'Daily'
        WEEKLY = 'WEEKLY', 'Weekly'
        ON_DEMAND = 'ON_DEMAND', 'On demand'

    business = models.ForeignKey(
        'accounts.BusinessTenant',
        on_delete=models.CASCADE,
        related_name='sop_checklists',
        verbose_name='Business',
    )
    title = models.CharField(
        max_length=255,
        verbose_name='Checklist title',
    )
    description = models.TextField(
        blank=True,
        default='',
        verbose_name='Description',
    )
    frequency = models.CharField(
        max_length=20,
        choices=Frequency.choices,
        default=Frequency.DAILY,
        verbose_name='Frequency',
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Active',
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_sop_checklists',
        verbose_name='Created by',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'SOP checklist'
        verbose_name_plural = 'SOP checklists'
        ordering = ['title', 'id']

    def __str__(self):
        return self.title


class SOPChecklistItem(models.Model):
    checklist = models.ForeignKey(
        SOPChecklist,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name='Checklist',
    )
    title = models.CharField(
        max_length=255,
        verbose_name='Checklist item',
    )
    order = models.PositiveIntegerField(
        default=1,
        verbose_name='Order',
    )

    class Meta:
        verbose_name = 'SOP checklist item'
        verbose_name_plural = 'SOP checklist items'
        ordering = ['order', 'id']
        constraints = [
            models.UniqueConstraint(fields=['checklist', 'order'], name='unique_sop_item_order_per_checklist'),
        ]

    def __str__(self):
        return f'{self.checklist} - {self.title}'


class SOPChecklistAssignmentRule(models.Model):
    business = models.ForeignKey(
        'accounts.BusinessTenant',
        on_delete=models.CASCADE,
        related_name='sop_assignment_rules',
        verbose_name='Business',
    )
    job_title = models.ForeignKey(
        'accounts.JobTitle',
        on_delete=models.CASCADE,
        related_name='sop_assignment_rules',
        verbose_name='Job title',
    )
    checklist = models.ForeignKey(
        SOPChecklist,
        on_delete=models.CASCADE,
        related_name='assignment_rules',
        verbose_name='Checklist',
    )
    assigned_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_sop_assignment_rules',
        verbose_name='Assigned by',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'SOP checklist assignment rule'
        verbose_name_plural = 'SOP checklist assignment rules'
        ordering = ['job_title__name', 'checklist__title', 'id']
        constraints = [
            models.UniqueConstraint(fields=['job_title', 'checklist'], name='unique_sop_rule_per_job_title'),
        ]

    def __str__(self):
        return f'{self.job_title} -> {self.checklist}'


class SOPChecklistCompletion(models.Model):
    business = models.ForeignKey(
        'accounts.BusinessTenant',
        on_delete=models.CASCADE,
        related_name='sop_completions',
        verbose_name='Business',
    )
    checklist = models.ForeignKey(
        SOPChecklist,
        on_delete=models.CASCADE,
        related_name='completions',
        verbose_name='Checklist',
    )
    employee = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sop_completions',
        verbose_name='Employee',
    )
    completed_for = models.DateField(
        default=timezone.localdate,
        verbose_name='Completion date',
    )
    notes = models.TextField(
        blank=True,
        default='',
        verbose_name='Notes',
    )
    completed_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Completed at',
    )

    class Meta:
        verbose_name = 'SOP checklist completion'
        verbose_name_plural = 'SOP checklist completions'
        ordering = ['-completed_for', '-completed_at', '-id']
        constraints = [
            models.UniqueConstraint(fields=['checklist', 'employee', 'completed_for'], name='unique_daily_sop_completion'),
        ]

    def __str__(self):
        return f'{self.employee} - {self.checklist} - {self.completed_for}'


class SOPChecklistItemCompletion(models.Model):
    completion = models.ForeignKey(
        SOPChecklistCompletion,
        on_delete=models.CASCADE,
        related_name='item_completions',
        verbose_name='Completion',
    )
    item = models.ForeignKey(
        SOPChecklistItem,
        on_delete=models.CASCADE,
        related_name='completions',
        verbose_name='Checklist item',
    )
    is_checked = models.BooleanField(
        default=False,
        verbose_name='Checked',
    )
    checked_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Checked at',
    )

    class Meta:
        verbose_name = 'SOP checklist item completion'
        verbose_name_plural = 'SOP checklist item completions'
        ordering = ['item__order', 'id']
        constraints = [
            models.UniqueConstraint(fields=['completion', 'item'], name='unique_item_completion_per_checklist_run'),
        ]

    def __str__(self):
        return f'{self.completion} - {self.item}'
