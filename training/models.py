import os
import uuid

from django.conf import settings
from django.core.files.base import ContentFile
from django.db import models
from django.utils import timezone

User = settings.AUTH_USER_MODEL


# ============================
# البرامج التدريبية
# ============================

class Program(models.Model):
    """
    برنامج تدريبي (دورة / اختبار / دورة إلكترونية)
    """

    class ProgramType(models.TextChoices):
        COURSE_ATTENDANCE = 'COURSE_ATTENDANCE', 'دورة حضورية'
        EXAM_ONLY = 'EXAM_ONLY', 'اختبار فقط'
        E_LEARNING = 'E_LEARNING', 'دورة إلكترونية'
        TECHNICAL_EXAM = 'TECHNICAL_EXAM', 'اختبار فني'
        SOLAR_POWER_EXAM = 'SOLAR_POWER_EXAM', 'الطاقة الشمسية'

    class OutcomeType(models.TextChoices):
        PASS_CARD = 'PASS_CARD', 'بطاقة اجتياز'
        CERTIFICATE = 'CERTIFICATE', 'شهادة'

    # Backward-compatible: existing UI uses `title`.
    # New requirements store Arabic + English names as separate fields.
    title = models.CharField(max_length=255, verbose_name='اسم البرنامج')
    title_ar = models.CharField(max_length=255, blank=True, default='', verbose_name='اسم البرنامج (عربي)')
    title_en = models.CharField(max_length=255, blank=True, default='', verbose_name='اسم البرنامج (إنجليزي)')
    description = models.TextField(verbose_name='وصف البرنامج')
    requirements = models.TextField(blank=True, default='', verbose_name='المتطلبات')

    overall_passing_grade_percent = models.PositiveSmallIntegerField(
        default=60,
        verbose_name='نسبة النجاح العامة %'
    )

    program_type = models.CharField(
        max_length=30,
        choices=ProgramType.choices,
        verbose_name='نوع البرنامج'
    )

    program_subcategory = models.CharField(
        max_length=100,
        blank=True,
        default='',
        verbose_name='التصنيف الفرعي'
    )

    outcome_type = models.CharField(
        max_length=30,
        choices=OutcomeType.choices,
        verbose_name='نوع المخرج'
    )

    requires_approval = models.BooleanField(default=True, verbose_name='يتطلب موافقة')
    requires_payment = models.BooleanField(default=True, verbose_name='يتطلب سداد')
    renewal_window_months = models.PositiveSmallIntegerField(
        default=6,
        verbose_name='فترة إتاحة التجديد قبل الانتهاء (بالأشهر)'
    )
    is_active = models.BooleanField(default=True, verbose_name='نشط')

    class Meta:
        verbose_name = 'برنامج تدريبي'
        verbose_name_plural = 'البرامج التدريبية'

    def __str__(self):
        return self.title


# ============================
# ✅ Program Exam Parts Configuration
# ============================


class ProgramExamPartConfig(models.Model):
    """Defines which exam parts are required for a program and per-part passing grade."""

    class PartType(models.TextChoices):
        THEORETICAL = 'THEORETICAL', 'نظري'
        PRACTICAL = 'PRACTICAL', 'عملي'
        PROJECT = 'PROJECT', 'مشروع'

    program = models.ForeignKey(
        Program,
        on_delete=models.CASCADE,
        related_name='exam_parts',
        verbose_name='البرنامج'
    )

    part_type = models.CharField(
        max_length=20,
        choices=PartType.choices,
        verbose_name='جزء الاختبار'
    )

    order = models.PositiveSmallIntegerField(default=1, verbose_name='ترتيب الجزء')

    passing_grade_percent = models.PositiveSmallIntegerField(
        default=60,
        verbose_name='نسبة النجاح لهذا الجزء %'
    )

    is_required = models.BooleanField(default=True, verbose_name='إلزامي')

    class Meta:
        verbose_name = 'تهيئة جزء اختبار للبرنامج'
        verbose_name_plural = 'تهيئة أجزاء الاختبارات للبرامج'
        ordering = ['program_id', 'order', 'id']
        constraints = [
            models.UniqueConstraint(fields=['program', 'order'], name='unique_part_order_per_program'),
        ]

    def __str__(self):
        return f"{self.program} - {self.get_part_type_display()}"


# ============================
# قالب الاختبار
# ============================

class ExamTemplate(models.Model):
    """
    قالب اختبار يرفعه المدرب
    """

    name = models.CharField(max_length=255, verbose_name='اسم قالب الاختبار')
    duration_minutes = models.PositiveIntegerField(verbose_name='مدة الاختبار (بالدقائق)')

    # ✅ عدد الأسئلة (نخليه موجود زي ما عندك، لكن الأفضل تحديثه تلقائيًا في الـ views)
    total_questions = models.PositiveIntegerField(default=0, verbose_name='عدد الأسئلة')

    # ✅ إعدادات شائعة في الأنظمة العالمية
    passing_score_percent = models.PositiveSmallIntegerField(
        default=60,
        verbose_name='نسبة النجاح %'
    )
    shuffle_questions = models.BooleanField(default=True, verbose_name='خلط الأسئلة')
    show_result_after_submit = models.BooleanField(default=True, verbose_name='إظهار النتيجة بعد التسليم')
    instructions = models.TextField(blank=True, verbose_name='تعليمات الاختبار')

    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='exam_templates',
        verbose_name='أنشئ بواسطة'
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاريخ الإنشاء')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='آخر تحديث')

    class Meta:
        verbose_name = 'قالب اختبار'
        verbose_name_plural = 'قوالب الاختبارات'

    def __str__(self):
        return self.name


# ============================
# ✅ أسئلة قالب الاختبار (موسع)
# ============================

class ExamQuestion(models.Model):
    """
    سؤال مرتبط بقالب الاختبار
    ✅ الآن يدعم: نوع السؤال + درجة السؤال + شرح الإجابة + إلزامية السؤال
    """

    class QuestionType(models.TextChoices):
        MULTIPLE_CHOICE_SINGLE = 'MCQ_SINGLE', 'اختيار من متعدد (إجابة واحدة)'
        MULTIPLE_CHOICE_MULTI = 'MCQ_MULTI', 'اختيار من متعدد (أكثر من إجابة)'
        TRUE_FALSE = 'TRUE_FALSE', 'صح / خطأ'
        SHORT_ANSWER = 'SHORT_ANSWER', 'إجابة قصيرة'
        ESSAY = 'ESSAY', 'مقالية'

    template = models.ForeignKey(
        ExamTemplate,
        on_delete=models.CASCADE,
        related_name='questions',
        verbose_name='قالب الاختبار'
    )

    order = models.PositiveIntegerField(default=1, verbose_name='الترتيب')

    question_text = models.TextField(verbose_name='نص السؤال')

    question_type = models.CharField(
        max_length=20,
        choices=QuestionType.choices,
        default=QuestionType.MULTIPLE_CHOICE_SINGLE,
        verbose_name='نوع السؤال'
    )

    points = models.PositiveSmallIntegerField(default=1, verbose_name='درجة السؤال')
    is_required = models.BooleanField(default=True, verbose_name='سؤال إلزامي')

    explanation = models.TextField(blank=True, verbose_name='شرح الإجابة (اختياري)')

    # هل نخلط خيارات السؤال؟ مفيد للـ MCQ و TRUE/FALSE
    shuffle_options = models.BooleanField(default=True, verbose_name='خلط الخيارات')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاريخ الإضافة')

    class Meta:
        verbose_name = 'سؤال اختبار'
        verbose_name_plural = 'أسئلة الاختبارات'
        ordering = ['order', 'id']
        constraints = [
            models.UniqueConstraint(
                fields=['template', 'order'],
                name='unique_question_order_per_template'
            )
        ]

    def __str__(self):
        return f"سؤال #{self.order} - {self.template}"


# ============================
# ✅ خيارات السؤال (للـ MCQ و TRUE/FALSE)
# ============================

class ExamOption(models.Model):
    """
    خيارات مرتبطة بسؤال.
    - للـ MCQ: عدة خيارات + تحديد الصحيح/الخطأ
    - للـ TRUE/FALSE: خيارين (صح/خطأ) أو تحفظ كخيارات ثابتة
    """

    question = models.ForeignKey(
        ExamQuestion,
        on_delete=models.CASCADE,
        related_name='options',
        verbose_name='السؤال'
    )

    order = models.PositiveIntegerField(default=1, verbose_name='ترتيب الخيار')
    option_text = models.CharField(max_length=500, verbose_name='نص الخيار')
    is_correct = models.BooleanField(default=False, verbose_name='إجابة صحيحة')

    class Meta:
        verbose_name = 'خيار سؤال'
        verbose_name_plural = 'خيارات الأسئلة'
        ordering = ['order', 'id']
        constraints = [
            models.UniqueConstraint(
                fields=['question', 'order'],
                name='unique_option_order_per_question'
            )
        ]

    def __str__(self):
        return f"خيار #{self.order} - سؤال #{self.question_id}"


# ============================
# طلب التسجيل / الاعتماد
# ============================

class ExamSession(models.Model):
    program = models.ForeignKey(
        Program,
        on_delete=models.CASCADE,
        related_name='exam_sessions',
        verbose_name='البرنامج'
    )

    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_exam_sessions',
        verbose_name='أنشئت بواسطة'
    )

    exam_date = models.DateTimeField(verbose_name='موعد الاختبار')

    exam_template = models.ForeignKey(
        ExamTemplate,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='exam_sessions',
        verbose_name='قالب الاختبار'
    )

    exam_code_hash = models.CharField(
        max_length=128,
        blank=True,
        default='',
        verbose_name='هاش كود دخول الاختبار'
    )
    exam_code_plain = models.CharField(
        max_length=8,
        blank=True,
        default='',
        verbose_name='كود دخول الاختبار'
    )

    is_active = models.BooleanField(default=True, verbose_name='نشطة')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاريخ الإنشاء')

    class Meta:
        verbose_name = 'جلسة اختبار'
        verbose_name_plural = 'جلسات الاختبارات'
        ordering = ['exam_date', 'id']

    def __str__(self):
        return f"{self.program} - {self.exam_date:%Y-%m-%d %H:%M}"


class EnrollmentRequest(models.Model):
    """
    يمثل الطلب من بدايته حتى نهايته (Workflow Driven)
    """

    class Status(models.TextChoices):
        NEW_REQUEST = 'NEW_REQUEST', 'طلب جديد'
        REJECTED = 'REJECTED', 'مرفوض'
        INVOICE_ISSUED = 'INVOICE_ISSUED', 'فاتورة مصدرة'
        PAYMENT_VERIFICATION = 'PAYMENT_VERIFICATION', 'التحقق مع عملية السداد'
        WAITING_EXAM_SCHEDULING = 'WAITING_EXAM_SCHEDULING', 'إنشاء موعد اختبار'
        EXAM_SCHEDULED = 'EXAM_SCHEDULED', 'حجز موعد الاختبار'
        EXAM_CONFIRMED = 'EXAM_CONFIRMED', 'الحضور لأداء الاختبار'
        IN_EXAM = 'IN_EXAM', 'جاري الاختبار'
        FAILED = 'FAILED', 'لم يجتز الاختبار'
        WAITING_PRACTICAL_GRADE = 'WAITING_PRACTICAL_GRADE', 'بانتظار إدخال درجة العملي'
        CERTIFIED = 'CERTIFIED', 'شهادة مصدرة'
        COMPLETED_WITH_PASS_CARD = 'COMPLETED_WITH_PASS_CARD', 'بطاقة اجتياز مصدرة'

    class RequestType(models.TextChoices):
        INITIAL = 'INITIAL', 'تسجيل جديد'
        RENEWAL = 'RENEWAL', 'تجديد'

    contractor = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='enrollments',
        verbose_name='المقاول'
    )

    program = models.ForeignKey(
        Program,
        on_delete=models.CASCADE,
        verbose_name='البرنامج التدريبي'
    )

    trainer = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_requests',
        verbose_name='المدرب'
    )

    supporting_documents = models.ManyToManyField(
        'accounts.ContractorDocument',
        blank=True,
        related_name='enrollments',
        verbose_name='مرفقات المقاول'
    )

    request_type = models.CharField(
        max_length=20,
        choices=RequestType.choices,
        default=RequestType.INITIAL,
        verbose_name='نوع الطلب'
    )

    source_certificate = models.ForeignKey(
        'certification.Certificate',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='renewal_enrollments',
        verbose_name='الشهادة المراد تجديدها'
    )

    status = models.CharField(
        max_length=40,
        choices=Status.choices,
        default=Status.NEW_REQUEST,
        verbose_name='حالة الطلب'
    )

    rejection_reason = models.TextField(blank=True, verbose_name='سبب الرفض')
    invoice_number = models.CharField(max_length=100, blank=True, verbose_name='رقم الفاتورة')

    exam_date = models.DateTimeField(null=True, blank=True, verbose_name='موعد الاختبار')

    exam_template = models.ForeignKey(
        ExamTemplate,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='enrollments',  # ✅ مفيد للاستعلام
        verbose_name='قالب الاختبار'
    )

    exam_session = models.ForeignKey(
        ExamSession,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='enrollments',
        verbose_name='جلسة الاختبار'
    )

    # ✅ Exam access code (stored hashed; never store plaintext)
    exam_code_hash = models.CharField(
        max_length=128,
        blank=True,
        default='',
        verbose_name='هاش كود دخول الاختبار'
    )

    attempts_count = models.PositiveIntegerField(default=0, verbose_name='عدد المحاولات')
    theoretical_attempts_count = models.PositiveIntegerField(default=0, verbose_name='محاولات النظري')
    practical_attempts_count = models.PositiveIntegerField(default=0, verbose_name='محاولات العملي')
    project_attempts_count = models.PositiveIntegerField(default=0, verbose_name='محاولات المشروع')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاريخ الإنشاء')

    class Meta:
        verbose_name = 'طلب تسجيل'
        verbose_name_plural = 'طلبات التسجيل'
        constraints = []

    def __str__(self):
        return f"{self.contractor} - {self.program} ({self.get_status_display()})"

    def snapshot_supporting_documents(self, documents=None):
        """
        Copy currently linked contractor documents into enrollment-owned files.
        This preserves trainer access even if the contractor deletes originals later.
        """
        if documents is None:
            documents = self.supporting_documents.all()

        existing_source_ids = set(
            self.supporting_document_snapshots.exclude(source_document__isnull=True)
            .values_list('source_document_id', flat=True)
        )

        for doc in documents:
            source_id = getattr(doc, 'id', None)
            if not source_id or source_id in existing_source_ids:
                continue

            source_file = getattr(doc, 'pdf_file', None)
            source_name = (getattr(source_file, 'name', '') or '')
            if not source_file or not source_name:
                continue

            try:
                source_file.open('rb')
                content = source_file.read()
            except Exception:
                continue
            finally:
                try:
                    source_file.close()
                except Exception:
                    pass

            if not content:
                continue

            base_name = os.path.basename(source_name)
            snapshot_name = f"{uuid.uuid4().hex}_{base_name}"
            snapshot = EnrollmentSupportingDocument(
                enrollment=self,
                source_document=doc,
                title=(getattr(doc, 'title', '') or '').strip(),
            )
            snapshot.pdf_file.save(snapshot_name, ContentFile(content), save=True)
            existing_source_ids.add(source_id)


    @property
    def status_key(self) -> str:
        return (self.status or '').lower()

    @property
    def status_css(self) -> str:
        s = self.status
        if s in {
            self.Status.NEW_REQUEST,
            self.Status.INVOICE_ISSUED,
            self.Status.PAYMENT_VERIFICATION,
            self.Status.WAITING_EXAM_SCHEDULING,
        }:
            return "pending"
        if s in {self.Status.REJECTED, self.Status.FAILED}:
            return "rejected"
        if s in {
            self.Status.EXAM_SCHEDULED,
            self.Status.EXAM_CONFIRMED,
            self.Status.IN_EXAM,
            self.Status.WAITING_PRACTICAL_GRADE,
            self.Status.CERTIFIED,
            self.Status.COMPLETED_WITH_PASS_CARD,
        }:
            return "approved"
        return "other"

    # ============================
    # Exam Parts / Gating (Backward-Compatible)
    # ============================

    def _configured_exam_parts(self):
        try:
            return list(self.program.exam_parts.all())
        except Exception:
            return []

    def required_exam_parts(self) -> list[str]:
        """Returns required part types for this program.

        Backward-compatible behavior:
        - If no config rows exist, infer THEORETICAL when an exam_template exists.
        """
        configs = [c for c in self._configured_exam_parts() if getattr(c, 'is_required', True)]
        if configs:
            return [c.part_type for c in sorted(configs, key=lambda x: (x.order or 0, x.id))]

        # Fallback for existing programs / when config is not set
        try:
            pt = getattr(getattr(self, 'program', None), 'program_type', None)
        except Exception:
            pt = None

        if pt == Program.ProgramType.TECHNICAL_EXAM:
            return [ProgramExamPartConfig.PartType.PRACTICAL]
        if pt == Program.ProgramType.SOLAR_POWER_EXAM:
            return [
                ProgramExamPartConfig.PartType.THEORETICAL,
                ProgramExamPartConfig.PartType.PRACTICAL,
            ]

        # Legacy program types: treat them as theoretical exams that are rendered in-system.
        # This must not depend on `exam_template_id` because scheduling happens before template is assigned.
        if pt in {Program.ProgramType.EXAM_ONLY, Program.ProgramType.COURSE_ATTENDANCE}:
            return [ProgramExamPartConfig.PartType.THEORETICAL]

        # E-learning has no exam scheduling in the current workflow.
        if pt == Program.ProgramType.E_LEARNING:
            return []

        if getattr(self, 'exam_template_id', None):
            return [ProgramExamPartConfig.PartType.THEORETICAL]
        return []

    def has_passed_theoretical(self) -> bool:
        return self.exam_attempts.filter(passed=True).exists()

    def has_passed_practical(self) -> bool:
        try:
            return self.external_assessments.filter(
                part_type=ProgramExamPartConfig.PartType.PRACTICAL,
                passed=True,
            ).exists()
        except Exception:
            return False

    def has_passed_project(self) -> bool:
        try:
            return self.external_assessments.filter(
                part_type=ProgramExamPartConfig.PartType.PROJECT,
                passed=True,
            ).exists()
        except Exception:
            return False

    def can_issue_outcome(self) -> bool:
        """True when all required parts are completed and passed."""
        required = set(self.required_exam_parts() or [])
        if not required:
            # Programs with no parts configured (or e-learning) rely on existing workflow.
            return True

        if ProgramExamPartConfig.PartType.THEORETICAL in required:
            if not self.has_passed_theoretical():
                return False

        if ProgramExamPartConfig.PartType.PRACTICAL in required:
            if not self.has_passed_practical():
                return False

        # PROJECT is currently manual/outside; treat as not completed unless implemented.
        if ProgramExamPartConfig.PartType.PROJECT in required:
            if not self.has_passed_project():
                return False

        return True

    # ============================
    # Workflow Logic
    # ============================

    def start_workflow(self):
        if self.program.requires_approval:
            self.status = self.Status.NEW_REQUEST
        else:
            if self.program.requires_payment:
                self.status = self.Status.INVOICE_ISSUED
            else:
                if self.program.program_type == Program.ProgramType.EXAM_ONLY:
                    self.status = self.Status.WAITING_EXAM_SCHEDULING
                elif self.program.program_type == Program.ProgramType.E_LEARNING:
                    if self.program.outcome_type == Program.OutcomeType.CERTIFICATE:
                        self.status = self.Status.CERTIFIED
                    else:
                        self.status = self.Status.COMPLETED_WITH_PASS_CARD
                else:
                    self.status = self.Status.WAITING_EXAM_SCHEDULING

    def approve_by_trainer(self):
        if self.status == self.Status.REJECTED:
            return

        if self.program.requires_payment:
            self.status = self.Status.INVOICE_ISSUED
        else:
            if self.program.program_type == Program.ProgramType.EXAM_ONLY:
                self.status = self.Status.WAITING_EXAM_SCHEDULING
            elif self.program.program_type == Program.ProgramType.E_LEARNING:
                if self.program.outcome_type == Program.OutcomeType.CERTIFICATE:
                    self.status = self.Status.CERTIFIED
                else:
                    self.status = self.Status.COMPLETED_WITH_PASS_CARD
            else:
                self.status = self.Status.WAITING_EXAM_SCHEDULING

    def confirm_payment(self):
        if self.status == self.Status.REJECTED:
            return
        if not self.program.requires_payment:
            return
        # Keep backward-compatibility: allow legacy flows where trainer confirms directly from INVOICE_ISSUED.
        if self.status not in {self.Status.INVOICE_ISSUED, self.Status.PAYMENT_VERIFICATION}:
            return

        if self.program.program_type == Program.ProgramType.EXAM_ONLY:
            self.status = self.Status.WAITING_EXAM_SCHEDULING
        elif self.program.program_type == Program.ProgramType.E_LEARNING:
            if self.program.outcome_type == Program.OutcomeType.CERTIFICATE:
                self.status = self.Status.CERTIFIED
            else:
                self.status = self.Status.COMPLETED_WITH_PASS_CARD
        else:
            self.status = self.Status.WAITING_EXAM_SCHEDULING

    def submit_payment_by_contractor(self):
        """Contractor confirms payment; moves to a verification stage for trainer review."""
        if self.status == self.Status.REJECTED:
            return
        if not self.program.requires_payment:
            return
        if self.status != self.Status.INVOICE_ISSUED:
            return

        self.status = self.Status.PAYMENT_VERIFICATION

    # ✅✅✅ تحديد موعد الاختبار (القالب إلزامي)
    def schedule_exam(self, exam_datetime, exam_template=None, exam_code_hash: str | None = None):
        if self.status == self.Status.REJECTED:
            return
        if self.status != self.Status.WAITING_EXAM_SCHEDULING:
            return
        if not exam_datetime:
            return
        if exam_template is None:
            return

        if timezone.is_naive(exam_datetime):
            exam_datetime = timezone.make_aware(exam_datetime, timezone.get_current_timezone())

        if exam_datetime <= timezone.now():
            return

        if not exam_code_hash:
            return

        self.exam_date = exam_datetime
        self.exam_template = exam_template
        self.exam_code_hash = exam_code_hash
        self.status = self.Status.EXAM_SCHEDULED


class EnrollmentSupportingDocument(models.Model):
    enrollment = models.ForeignKey(
        EnrollmentRequest,
        on_delete=models.CASCADE,
        related_name='supporting_document_snapshots',
        verbose_name='طلب التسجيل'
    )

    source_document = models.ForeignKey(
        'accounts.ContractorDocument',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='enrollment_snapshots',
        verbose_name='المرفق الأصلي'
    )

    title = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='عنوان الملف'
    )

    pdf_file = models.FileField(
        upload_to='enrollment_supporting_docs/',
        verbose_name='ملف PDF'
    )

    uploaded_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='تاريخ الرفع'
    )

    class Meta:
        verbose_name = 'مرفق طلب التسجيل'
        verbose_name_plural = 'مرفقات طلبات التسجيل'
        ordering = ['-uploaded_at', '-id']

    def __str__(self):
        label = (self.title or '').strip()
        if not label:
            label = os.path.basename((getattr(self.pdf_file, 'name', '') or '')) or 'PDF'
        return f"{self.enrollment_id} - {label}"


# ============================
# محاولة الاختبار
# ============================

class ExamAttempt(models.Model):
    """
    محاولة أداء اختبار
    """

    enrollment = models.ForeignKey(
        EnrollmentRequest,
        on_delete=models.CASCADE,
        related_name='exam_attempts',
        verbose_name='طلب التسجيل'
    )

    started_at = models.DateTimeField(auto_now_add=True, verbose_name='وقت بدء الاختبار')
    completed_at = models.DateTimeField(null=True, blank=True, verbose_name='وقت انتهاء الاختبار')
    score = models.FloatField(null=True, blank=True, verbose_name='الدرجة')
    passed = models.BooleanField(default=False, verbose_name='ناجح')

    class Meta:
        verbose_name = 'محاولة اختبار'
        verbose_name_plural = 'محاولات الاختبارات'

    def __str__(self):
        return f"محاولة - {self.enrollment}"


# ============================
# ✅ Practical Assessment (Trainer enters grade + uploads PDF)
# ============================


class ExternalPartAssessment(models.Model):
    """Trainer-entered assessment for external parts (Practical / Project).

    Stored separately from theoretical online attempts.
    """

    enrollment = models.ForeignKey(
        EnrollmentRequest,
        on_delete=models.CASCADE,
        related_name='external_assessments',
        verbose_name='طلب التسجيل'
    )

    part_type = models.CharField(
        max_length=20,
        choices=ProgramExamPartConfig.PartType.choices,
        verbose_name='نوع الجزء'
    )

    grade_percent = models.PositiveSmallIntegerField(verbose_name='الدرجة %')

    passed = models.BooleanField(default=False, verbose_name='ناجح')

    pdf_file = models.FileField(
        upload_to='external_assessments/',
        blank=True,
        null=True,
        verbose_name='ملف التقييم (PDF)'
    )

    submitted_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='submitted_external_assessments',
        verbose_name='تم الإدخال بواسطة'
    )

    submitted_at = models.DateTimeField(auto_now=True, verbose_name='تاريخ الإدخال')

    class Meta:
        verbose_name = 'تقييم خارجي'
        verbose_name_plural = 'التقييمات الخارجية'
        ordering = ['-submitted_at', '-id']
        constraints = [
            models.UniqueConstraint(
                fields=['enrollment', 'part_type'],
                name='unique_external_assessment_per_enrollment_part'
            )
        ]

    def __str__(self):
        return f"External {self.part_type} - {self.enrollment_id}"


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

    class Meta:
        verbose_name = 'Course'
        verbose_name_plural = 'Courses'
        ordering = ['title', 'id']

    def __str__(self):
        return self.title


class CourseAssignmentRule(models.Model):
    business = models.ForeignKey(
        'accounts.BusinessTenant',
        on_delete=models.CASCADE,
        related_name='course_assignment_rules',
        verbose_name='Business',
    )
    job_title = models.ForeignKey(
        'accounts.JobTitle',
        on_delete=models.CASCADE,
        related_name='course_assignment_rules',
        verbose_name='Job title',
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='assignment_rules',
        verbose_name='Course',
    )
    assigned_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_course_assignment_rules',
        verbose_name='Assigned by',
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created at',
    )

    class Meta:
        verbose_name = 'Course assignment rule'
        verbose_name_plural = 'Course assignment rules'
        ordering = ['job_title__name', 'course__title', 'id']
        constraints = [
            models.UniqueConstraint(fields=['job_title', 'course'], name='unique_course_rule_per_job_title'),
        ]

    def __str__(self):
        return f'{self.job_title} -> {self.course}'


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
    assigned_via_job_title = models.ForeignKey(
        'accounts.JobTitle',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='course_assignments',
        verbose_name='Assigned via job title',
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
