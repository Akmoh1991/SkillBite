from __future__ import annotations

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from tenancy.models import Tenant, Branch, TimeStampedModel


class TenantOwnedModel(TimeStampedModel):
    """Base class for tenant-owned data."""
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)

    class Meta:
        abstract = True
        indexes = [models.Index(fields=["tenant"])]


class Course(TenantOwnedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PUBLISHED = "published", "Published"
        ARCHIVED = "archived", "Archived"

    title = models.CharField(max_length=250)
    description = models.TextField(blank=True, default="")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)

    # Optional: branch scoping
    available_to_all_branches = models.BooleanField(default=True)
    branches = models.ManyToManyField(Branch, blank=True, related_name="courses")

    estimated_minutes = models.PositiveIntegerField(default=0)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "title"], name="uq_course_tenant_title"),
        ]
        indexes = [
            models.Index(fields=["tenant", "status"]),
        ]

    def clean(self):
        super().clean()
        if not self.available_to_all_branches and self.pk and self.branches.count() == 0:
            # Not strict for initial creation; strictness can be relaxed if you prefer
            pass

    def __str__(self) -> str:
        return f"{self.tenant.slug} / {self.title}"


class LearningPath(TenantOwnedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PUBLISHED = "published", "Published"
        ARCHIVED = "archived", "Archived"

    title = models.CharField(max_length=250)
    description = models.TextField(blank=True, default="")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)

    available_to_all_branches = models.BooleanField(default=True)
    branches = models.ManyToManyField(Branch, blank=True, related_name="learning_paths")

    courses = models.ManyToManyField(Course, through="LearningPathCourse", related_name="paths")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "title"], name="uq_path_tenant_title"),
        ]
        indexes = [
            models.Index(fields=["tenant", "status"]),
        ]

    def __str__(self) -> str:
        return f"{self.tenant.slug} / {self.title}"


class LearningPathCourse(TimeStampedModel):
    """Ordering of courses within a path."""
    path = models.ForeignKey(LearningPath, on_delete=models.CASCADE)
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    order = models.PositiveIntegerField(default=1)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["path", "course"], name="uq_path_course"),
            models.UniqueConstraint(fields=["path", "order"], name="uq_path_course_order"),
        ]
        indexes = [
            models.Index(fields=["path", "order"]),
        ]

    def clean(self):
        super().clean()
        if self.path.tenant_id != self.course.tenant_id:
            raise ValidationError("Path and Course must belong to the same tenant.")


class Module(TenantOwnedModel):
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name="modules")
    title = models.CharField(max_length=250)
    order = models.PositiveIntegerField(default=1)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["course", "order"], name="uq_module_course_order"),
        ]
        indexes = [
            models.Index(fields=["course", "order"]),
        ]

    def clean(self):
        super().clean()
        if self.tenant_id != self.course.tenant_id:
            raise ValidationError("Module tenant must match course tenant.")


class Lesson(TenantOwnedModel):
    class Kind(models.TextChoices):
        TEXT = "text", "Text"
        VIDEO_URL = "video_url", "Video URL"
        FILE = "file", "File"
        SOP = "sop", "SOP"
        CHECKLIST = "checklist", "Checklist"
        QUIZ = "quiz", "Quiz"

    module = models.ForeignKey(Module, on_delete=models.CASCADE, related_name="lessons")
    title = models.CharField(max_length=250)
    order = models.PositiveIntegerField(default=1)

    kind = models.CharField(max_length=20, choices=Kind.choices, default=Kind.TEXT)

    # Content fields (use what fits the kind)
    text_content = models.TextField(blank=True, default="")
    video_url = models.URLField(blank=True, default="")
    file = models.FileField(upload_to="learning/lessons/", blank=True, null=True)

    # Linking optional objects (kept nullable)
    sop = models.ForeignKey("SOP", on_delete=models.SET_NULL, null=True, blank=True, related_name="lessons")
    checklist_template = models.ForeignKey(
        "ChecklistTemplate",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="lessons",
    )
    quiz = models.ForeignKey("Quiz", on_delete=models.SET_NULL, null=True, blank=True, related_name="lessons")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["module", "order"], name="uq_lesson_module_order"),
        ]
        indexes = [
            models.Index(fields=["module", "order"]),
            models.Index(fields=["tenant", "kind"]),
        ]

    def clean(self):
        super().clean()
        if self.tenant_id != self.module.tenant_id:
            raise ValidationError("Lesson tenant must match module tenant.")

        # Basic validation by kind (lightweight but helpful)
        if self.kind == self.Kind.TEXT and not self.text_content:
            # allow drafts; you can comment this if you want total flexibility
            pass
        if self.kind == self.Kind.VIDEO_URL and not self.video_url:
            pass


class Resource(TenantOwnedModel):
    """Reusable resource files (policies, PDFs, images)."""
    title = models.CharField(max_length=250)
    file = models.FileField(upload_to="learning/resources/")
    description = models.TextField(blank=True, default="")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "title"], name="uq_resource_tenant_title"),
        ]


class SOP(TenantOwnedModel):
    """SOP container. Actual content lives in versions."""
    title = models.CharField(max_length=250)
    is_active = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "title"], name="uq_sop_tenant_title"),
        ]
        indexes = [
            models.Index(fields=["tenant", "is_active"]),
        ]

    def __str__(self) -> str:
        return f"{self.tenant.slug} / {self.title}"


class SOPVersion(TimeStampedModel):
    sop = models.ForeignKey(SOP, on_delete=models.CASCADE, related_name="versions")
    version = models.PositiveIntegerField(default=1)
    content = models.TextField()  # markdown/plain text SOP steps
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["sop", "version"], name="uq_sop_version"),
        ]
        indexes = [
            models.Index(fields=["sop", "published_at"]),
        ]

    def publish(self):
        self.published_at = timezone.now()


class ChecklistTemplate(TenantOwnedModel):
    title = models.CharField(max_length=250)
    description = models.TextField(blank=True, default="")
    is_active = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "title"], name="uq_checklist_tenant_title"),
        ]
        indexes = [
            models.Index(fields=["tenant", "is_active"]),
        ]


class ChecklistItem(TimeStampedModel):
    template = models.ForeignKey(ChecklistTemplate, on_delete=models.CASCADE, related_name="items")
    text = models.CharField(max_length=300)
    order = models.PositiveIntegerField(default=1)
    is_required = models.BooleanField(default=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["template", "order"], name="uq_checklist_item_order"),
        ]
        indexes = [
            models.Index(fields=["template", "order"]),
        ]


class Quiz(TenantOwnedModel):
    title = models.CharField(max_length=250)
    description = models.TextField(blank=True, default="")
    passing_score = models.PositiveIntegerField(default=70)  # percentage
    max_attempts = models.PositiveIntegerField(default=0)  # 0 = unlimited

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["tenant", "title"], name="uq_quiz_tenant_title"),
        ]


class Question(TimeStampedModel):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name="questions")
    text = models.TextField()
    order = models.PositiveIntegerField(default=1)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["quiz", "order"], name="uq_question_quiz_order"),
        ]
        indexes = [
            models.Index(fields=["quiz", "order"]),
        ]


class Choice(TimeStampedModel):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name="choices")
    text = models.CharField(max_length=400)
    is_correct = models.BooleanField(default=False)

    class Meta:
        indexes = [
            models.Index(fields=["question", "is_correct"]),
        ]