from __future__ import annotations

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from tenancy.models import Tenant, Branch, Role, TimeStampedModel
from learning.models import Course, LearningPath, Lesson, Quiz, ChecklistTemplate, ChecklistItem


class TenantOwnedModel(TimeStampedModel):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)

    class Meta:
        abstract = True
        indexes = [models.Index(fields=["tenant"])]


class Enrollment(TenantOwnedModel):
    """
    A user enrolled in a course OR a path.
    Only one of course/path should be set.
    """
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="enrollments")
    course = models.ForeignKey(Course, on_delete=models.CASCADE, null=True, blank=True, related_name="enrollments")
    path = models.ForeignKey(LearningPath, on_delete=models.CASCADE, null=True, blank=True, related_name="enrollments")

    enrolled_at = models.DateTimeField(default=timezone.now)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "course"], name="uq_enroll_user_course"),
            models.UniqueConstraint(fields=["user", "path"], name="uq_enroll_user_path"),
        ]
        indexes = [
            models.Index(fields=["tenant", "completed_at"]),
            models.Index(fields=["user", "completed_at"]),
        ]

    def clean(self):
        super().clean()
        if (self.course is None and self.path is None) or (self.course is not None and self.path is not None):
            raise ValidationError("Enrollment must have exactly one of course or path.")
        if self.user.tenant_id and self.tenant_id and self.user.tenant_id != self.tenant_id:
            raise ValidationError("Enrollment tenant must match user tenant.")
        if self.course and self.course.tenant_id != self.tenant_id:
            raise ValidationError("Enrollment tenant must match course tenant.")
        if self.path and self.path.tenant_id != self.tenant_id:
            raise ValidationError("Enrollment tenant must match path tenant.")

    @property
    def is_completed(self) -> bool:
        return self.completed_at is not None


class Assignment(TenantOwnedModel):
    """
    Assign training to:
    - target_user OR target_branch OR target_role
    Keep it explicit (no GenericForeignKey) for maintainability.
    """
    class Kind(models.TextChoices):
        COURSE = "course", "Course"
        PATH = "path", "Path"

    kind = models.CharField(max_length=10, choices=Kind.choices)
    course = models.ForeignKey(Course, on_delete=models.CASCADE, null=True, blank=True)
    path = models.ForeignKey(LearningPath, on_delete=models.CASCADE, null=True, blank=True)

    # Targets (exactly one)
    target_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="assignments",
    )
    target_branch = models.ForeignKey(Branch, on_delete=models.CASCADE, null=True, blank=True)
    target_role = models.ForeignKey(Role, on_delete=models.CASCADE, null=True, blank=True)

    due_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_assignments",
    )

    is_active = models.BooleanField(default=True)

    class Meta:
        indexes = [
            models.Index(fields=["tenant", "is_active"]),
            models.Index(fields=["due_at"]),
        ]

    def clean(self):
        super().clean()

        # Validate kind content linkage
        if self.kind == self.Kind.COURSE:
            if self.course is None or self.path is not None:
                raise ValidationError("Course assignment must have course set and path empty.")
        if self.kind == self.Kind.PATH:
            if self.path is None or self.course is not None:
                raise ValidationError("Path assignment must have path set and course empty.")

        # Validate target: exactly one
        targets = [self.target_user_id, self.target_branch_id, self.target_role_id]
        if sum(1 for t in targets if t is not None) != 1:
            raise ValidationError("Assignment must target exactly one of user, branch, or role.")

        # Tenant consistency checks
        if self.course and self.course.tenant_id != self.tenant_id:
            raise ValidationError("Assignment tenant must match course tenant.")
        if self.path and self.path.tenant_id != self.tenant_id:
            raise ValidationError("Assignment tenant must match path tenant.")
        if self.target_user and self.target_user.tenant_id != self.tenant_id:
            raise ValidationError("Assignment tenant must match user tenant.")
        if self.target_branch and self.target_branch.tenant_id != self.tenant_id:
            raise ValidationError("Assignment tenant must match branch tenant.")
        if self.target_role and self.target_role.tenant_id != self.tenant_id:
            raise ValidationError("Assignment tenant must match role tenant.")


class LessonProgress(TenantOwnedModel):
    """
    Track progress per lesson.
    """
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="lesson_progress")
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name="progress_records")

    started_at = models.DateTimeField(null=True, blank=True)
    last_activity_at = models.DateTimeField(default=timezone.now)
    completed_at = models.DateTimeField(null=True, blank=True)

    # For video/text progress
    percent = models.PositiveIntegerField(default=0)  # 0..100
    last_position_seconds = models.PositiveIntegerField(default=0)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "lesson"], name="uq_user_lesson_progress"),
        ]
        indexes = [
            models.Index(fields=["tenant", "completed_at"]),
            models.Index(fields=["user", "completed_at"]),
        ]

    def clean(self):
        super().clean()
        if self.user.tenant_id != self.tenant_id:
            raise ValidationError("LessonProgress tenant must match user tenant.")
        if self.lesson.tenant_id != self.tenant_id:
            raise ValidationError("LessonProgress tenant must match lesson tenant.")
        if self.percent > 100:
            raise ValidationError("percent must be between 0 and 100.")


class QuizAttempt(TenantOwnedModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="quiz_attempts")
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name="attempts")

    started_at = models.DateTimeField(default=timezone.now)
    submitted_at = models.DateTimeField(null=True, blank=True)

    score_percent = models.PositiveIntegerField(default=0)
    passed = models.BooleanField(default=False)

    class Meta:
        indexes = [
            models.Index(fields=["tenant", "submitted_at"]),
            models.Index(fields=["user", "submitted_at"]),
        ]

    def clean(self):
        super().clean()
        if self.user.tenant_id != self.tenant_id:
            raise ValidationError("QuizAttempt tenant must match user tenant.")
        if self.quiz.tenant_id != self.tenant_id:
            raise ValidationError("QuizAttempt tenant must match quiz tenant.")
        if self.score_percent > 100:
            raise ValidationError("score_percent must be between 0 and 100.")


class QuizAnswer(TimeStampedModel):
    attempt = models.ForeignKey(QuizAttempt, on_delete=models.CASCADE, related_name="answers")
    question_id = models.PositiveIntegerField()  # store question ID without FK to avoid cross-app circular deps in migrations
    choice_id = models.PositiveIntegerField(null=True, blank=True)  # selected choice id
    text_answer = models.TextField(blank=True, default="")

    class Meta:
        indexes = [
            models.Index(fields=["attempt", "question_id"]),
        ]


class ChecklistRun(TenantOwnedModel):
    """
    Executing a checklist by a user (often per shift).
    """
    template = models.ForeignKey(ChecklistTemplate, on_delete=models.CASCADE, related_name="runs")
    branch = models.ForeignKey(Branch, on_delete=models.SET_NULL, null=True, blank=True)

    performed_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="checklist_runs")
    performed_at = models.DateTimeField(default=timezone.now)

    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_checklist_runs",
    )
    approved_at = models.DateTimeField(null=True, blank=True)

    notes = models.TextField(blank=True, default="")

    class Meta:
        indexes = [
            models.Index(fields=["tenant", "performed_at"]),
            models.Index(fields=["branch", "performed_at"]),
        ]

    def clean(self):
        super().clean()
        if self.template.tenant_id != self.tenant_id:
            raise ValidationError("ChecklistRun tenant must match template tenant.")
        if self.performed_by.tenant_id != self.tenant_id:
            raise ValidationError("ChecklistRun tenant must match performer tenant.")
        if self.branch and self.branch.tenant_id != self.tenant_id:
            raise ValidationError("ChecklistRun tenant must match branch tenant.")
        if self.approved_by and self.approved_by.tenant_id != self.tenant_id:
            raise ValidationError("ChecklistRun tenant must match approver tenant.")


class ChecklistItemResult(TimeStampedModel):
    run = models.ForeignKey(ChecklistRun, on_delete=models.CASCADE, related_name="item_results")
    item = models.ForeignKey(ChecklistItem, on_delete=models.CASCADE)

    is_done = models.BooleanField(default=False)
    comment = models.CharField(max_length=300, blank=True, default="")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["run", "item"], name="uq_run_item"),
        ]
        indexes = [
            models.Index(fields=["run"]),
        ]

    def clean(self):
        super().clean()
        if self.item.template_id != self.run.template_id:
            raise ValidationError("ChecklistItemResult item must belong to the same template as the run.")


class Certificate(TenantOwnedModel):
    """
    Simple completion proof.
    Can be issued for course or path.
    """
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="certificates")
    course = models.ForeignKey(Course, on_delete=models.SET_NULL, null=True, blank=True)
    path = models.ForeignKey(LearningPath, on_delete=models.SET_NULL, null=True, blank=True)

    issued_at = models.DateTimeField(default=timezone.now)
    code = models.CharField(max_length=32)  # printable/verify code (generate in service layer later)

    class Meta:
        indexes = [
            models.Index(fields=["tenant", "issued_at"]),
            models.Index(fields=["code"]),
        ]

    def clean(self):
        super().clean()
        if (self.course is None and self.path is None) or (self.course is not None and self.path is not None):
            raise ValidationError("Certificate must have exactly one of course or path.")
        if self.user.tenant_id != self.tenant_id:
            raise ValidationError("Certificate tenant must match user tenant.")
        if self.course and self.course.tenant_id != self.tenant_id:
            raise ValidationError("Certificate tenant must match course tenant.")
        if self.path and self.path.tenant_id != self.tenant_id:
            raise ValidationError("Certificate tenant must match path tenant.")