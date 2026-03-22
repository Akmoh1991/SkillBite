from pathlib import Path

from django import forms
from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.validators import RegexValidator

from .models import BusinessTenant, JobTitle
from training.models import (
    Course,
    CourseBusinessAssignment,
    CourseContentItem,
    CourseExamSession,
    ExamOption,
    ExamQuestion,
    ExamTemplate,
    SOPChecklist,
    SOPChecklistAssignmentRule,
)


User = get_user_model()

SAFE_VIDEO_EXTENSIONS = {'.mp4', '.webm'}
SAFE_VIDEO_MIME_TYPES = {'video/mp4', 'video/webm'}
SAFE_VIDEO_ACCEPT_ATTR = 'video/mp4,video/webm,.mp4,.webm'
SAFE_PDF_EXTENSIONS = {'.pdf'}
SAFE_PDF_MIME_TYPES = {'application/pdf'}
SAFE_PDF_ACCEPT_ATTR = 'application/pdf,.pdf'
MAX_VIDEO_UPLOAD_BYTES = int(getattr(settings, 'MAX_VIDEO_UPLOAD_BYTES', 250 * 1024 * 1024))
MAX_PDF_UPLOAD_BYTES = int(getattr(settings, 'MAX_PDF_UPLOAD_BYTES', 20 * 1024 * 1024))


def _validate_upload_size(upload, *, max_bytes: int, label: str):
    if not upload:
        return upload
    if getattr(upload, 'size', 0) > max_bytes:
        max_mb = max_bytes // (1024 * 1024)
        raise forms.ValidationError(f'{label} exceeds the allowed size limit of {max_mb} MB.')
    return upload


def validate_browser_safe_video(upload):
    if not upload:
        return upload
    _validate_upload_size(upload, max_bytes=MAX_VIDEO_UPLOAD_BYTES, label='Video file')
    suffix = Path((upload.name or '').strip()).suffix.lower()
    if suffix not in SAFE_VIDEO_EXTENSIONS:
        raise forms.ValidationError('صيغة الفيديو غير مدعومة. استخدم MP4 أو WebM فقط.')
    content_type = (getattr(upload, 'content_type', '') or '').lower()
    if content_type and content_type not in SAFE_VIDEO_MIME_TYPES:
        raise forms.ValidationError('نوع ملف الفيديو غير مدعوم. استخدم MP4 أو WebM فقط.')
    return upload


def validate_browser_safe_pdf(upload):
    if not upload:
        return upload
    _validate_upload_size(upload, max_bytes=MAX_PDF_UPLOAD_BYTES, label='PDF file')
    suffix = Path((upload.name or '').strip()).suffix.lower()
    if suffix not in SAFE_PDF_EXTENSIONS:
        raise forms.ValidationError('Unsupported document format. Upload a PDF file only.')
    content_type = (getattr(upload, 'content_type', '') or '').lower()
    if content_type and content_type not in SAFE_PDF_MIME_TYPES:
        raise forms.ValidationError('Unsupported PDF content type. Upload a valid PDF file only.')
    return upload


class RegisterForm(forms.Form):
    ROLE_CHOICES = (
        ('business_owner', 'Business Owner'),
    )
    REGION_CHOICES = (
        ('', 'اختر المنطقة'),
        ('Eastern region', 'المنطقة الشرقية'),
        ('Central region', 'المنطقة الوسطى'),
        ('Western region', 'المنطقة الغربية'),
        ('Northern region', 'المنطقة الشمالية'),
        ('Southern region', 'المنطقة الجنوبية'),
    )
    SEC_BUSINESS_LINE_CHOICES = (
        ('', 'Select SEC Business line'),
        ('Distribution Contractors', 'Distribution Contractors'),
        ('National Grid Contractors', 'National Grid Contractors'),
        ('Projects Contractors', 'Projects Contractors'),
        ('Generation Contractors', 'Generation Contractors'),
        ('Dawiyat Contractors', 'Dawiyat Contractors'),
        ('HSSE Contractors', 'HSSE Contractors'),
        ('Material Sector', 'Material Sector'),
        ('Facilities Sector', 'Facilities Sector'),
    )

    username = forms.CharField(label='اسم المستخدم', max_length=150)
    email = forms.EmailField(label='البريد الإلكتروني', required=False)
    full_name_en = forms.CharField(label='Full Name (English)', max_length=255)
    full_name_ar = forms.CharField(label='الاسم الكامل (بالعربية)', max_length=255, required=False)
    password = forms.CharField(label='كلمة المرور', widget=forms.PasswordInput)
    role = forms.ChoiceField(label='نوع الحساب', choices=ROLE_CHOICES)
    company_name = forms.CharField(label='اسم الشركة', max_length=255, required=False)
    sec_business_line = forms.ChoiceField(label='SEC Business line', choices=SEC_BUSINESS_LINE_CHOICES, required=False)
    phone_number = forms.CharField(
        label='رقم الجوال',
        max_length=10,
        required=False,
        validators=[RegexValidator(regex=r'^0\d{9}$', message='رقم الجوال يجب أن يكون 10 أرقام ويبدأ بـ 0')],
    )
    id_number = forms.CharField(
        label='رقم الهوية',
        max_length=10,
        required=False,
        validators=[RegexValidator(regex=r'^[12]\d{9}$', message='رقم الهوية يجب أن يكون 10 أرقام ويبدأ بـ 1 أو 2')],
    )
    region = forms.ChoiceField(label='المنطقة', choices=REGION_CHOICES, required=False)

    def clean_password(self):
        password = self.cleaned_data.get('password') or ''
        validate_password(password)
        return password

    def clean(self):
        cleaned_data = super().clean()
        for field in ('company_name', 'phone_number', 'id_number', 'region', 'sec_business_line'):
            if not (cleaned_data.get(field) or '').strip():
                self.add_error(field, 'هذا الحقل مطلوب')
        return cleaned_data


class BusinessEmployeeCreateForm(forms.Form):
    username = forms.CharField(max_length=150)
    email = forms.EmailField(required=False)
    full_name = forms.CharField(max_length=255)
    password = forms.CharField(widget=forms.PasswordInput)
    job_title = forms.ModelChoiceField(queryset=JobTitle.objects.none(), required=False, empty_label='بدون مسمى وظيفي')

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business')
        super().__init__(*args, **kwargs)
        self.fields['job_title'].queryset = JobTitle.objects.filter(business=business).order_by('name', 'id')

    def clean_password(self):
        password = self.cleaned_data.get('password') or ''
        validate_password(password)
        return password


class JobTitleForm(forms.ModelForm):
    class Meta:
        model = JobTitle
        fields = ['name']


class CourseForm(forms.ModelForm):
    class Meta:
        model = Course
        fields = ['title', 'description', 'estimated_minutes', 'is_active']


class CourseContentItemForm(forms.ModelForm):
    class Meta:
        model = CourseContentItem
        fields = ['course', 'content_type', 'title', 'body', 'material_url', 'video_file', 'pdf_file', 'order']

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business')
        super().__init__(*args, **kwargs)
        self.fields['course'].queryset = Course.objects.filter(business=business).order_by('title', 'id')
        self.fields['video_file'].widget.attrs['accept'] = SAFE_VIDEO_ACCEPT_ATTR
        self.fields['pdf_file'].widget.attrs['accept'] = SAFE_PDF_ACCEPT_ATTR

    def clean_video_file(self):
        return validate_browser_safe_video(self.cleaned_data.get('video_file'))

    def clean_pdf_file(self):
        return validate_browser_safe_pdf(self.cleaned_data.get('pdf_file'))


class SOPChecklistForm(forms.ModelForm):
    item_lines = forms.CharField(
        widget=forms.Textarea,
        help_text='عنصر واحد في كل سطر',
    )

    class Meta:
        model = SOPChecklist
        fields = ['title', 'description', 'frequency', 'is_active']

    def clean_item_lines(self):
        raw = self.cleaned_data.get('item_lines') or ''
        items = [line.strip() for line in raw.splitlines() if line.strip()]
        if not items:
            raise forms.ValidationError('أضف عنصر SOP واحداً على الأقل')
        return items


class SOPChecklistAssignmentRuleForm(forms.ModelForm):
    class Meta:
        model = SOPChecklistAssignmentRule
        fields = ['job_title', 'checklist']

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business')
        super().__init__(*args, **kwargs)
        self.fields['job_title'].queryset = JobTitle.objects.filter(business=business).order_by('name', 'id')
        self.fields['checklist'].queryset = SOPChecklist.objects.filter(business=business, is_active=True).order_by('title', 'id')


class SuperAdminBusinessCreateForm(forms.Form):
    business_name = forms.CharField(max_length=255)
    industry = forms.CharField(max_length=100, required=False, initial='Food & Beverage')
    owner_username = forms.CharField(max_length=150)
    owner_email = forms.EmailField(required=False)
    owner_full_name = forms.CharField(max_length=255)
    owner_password = forms.CharField(widget=forms.PasswordInput)
    is_active = forms.BooleanField(required=False, initial=True)

    def clean_owner_password(self):
        password = self.cleaned_data.get('owner_password') or ''
        validate_password(password)
        return password


class SuperAdminUserCreateForm(forms.Form):
    ROLE_CHOICES = (
        ('super_admin', 'Super Admin'),
        ('business_owner', 'Business Owner'),
    )

    username = forms.CharField(max_length=150)
    email = forms.EmailField(required=False)
    full_name = forms.CharField(max_length=255)
    password = forms.CharField(widget=forms.PasswordInput)
    role = forms.ChoiceField(choices=ROLE_CHOICES)
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        required=False,
        empty_label='No business',
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['business'].queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')

    def clean_password(self):
        password = self.cleaned_data.get('password') or ''
        validate_password(password)
        return password

    def clean(self):
        cleaned_data = super().clean()
        role = cleaned_data.get('role')
        business = cleaned_data.get('business')
        if role == 'business_owner' and not business:
            self.add_error('business', 'Select a business for the business owner.')
        return cleaned_data


class SuperAdminGrantRoleForm(forms.Form):
    user = forms.ModelChoiceField(
        queryset=User.objects.none(),
        empty_label='اختر المستخدم',
        label='المستخدم',
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['user'].queryset = User.objects.exclude(is_staff=True, is_superuser=True).order_by('username', 'id')


class ExamTemplateChoiceField(forms.ModelChoiceField):
    def label_from_instance(self, obj):
        if obj.business_id and obj.business:
            return f'{obj.name} - {obj.business.name}'
        return obj.name


class SuperAdminCourseCreateForm(forms.ModelForm):
    exam_template = ExamTemplateChoiceField(
        queryset=ExamTemplate.objects.none(),
        required=False,
        empty_label='بدون قالب اختبار',
    )

    class Meta:
        model = Course
        fields = ['title', 'description', 'estimated_minutes', 'exam_template', 'is_active']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['exam_template'].queryset = ExamTemplate.objects.select_related('business').order_by('business__name', 'name', 'id')
        self.fields['exam_template'].label = 'قالب الاختبار'
        self.fields['title'].label = 'عنوان الدورة'
        self.fields['description'].label = 'الوصف'
        self.fields['estimated_minutes'].label = 'المدة التقديرية بالدقائق'
        self.fields['is_active'].label = 'الدورة نشطة'

    def clean_title(self):
        title = (self.cleaned_data.get('title') or '').strip()
        if not title:
            return title
        queryset = Course.objects.filter(business__isnull=True, title__iexact=title)
        if self.instance.pk:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise forms.ValidationError('يوجد بالفعل دورة عامة بهذا العنوان.')
        return title


class SuperAdminCourseContentItemForm(forms.ModelForm):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='Select business',
        required=False,
    )

    class Meta:
        model = CourseContentItem
        fields = ['course', 'content_type', 'title', 'body', 'material_url', 'video_file', 'pdf_file', 'order']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        business_queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')
        self.fields['business'].queryset = business_queryset
        self.fields['course'].queryset = Course.objects.none()
        self.fields['video_file'].widget.attrs['accept'] = SAFE_VIDEO_ACCEPT_ATTR
        self.fields['pdf_file'].widget.attrs['accept'] = SAFE_PDF_ACCEPT_ATTR

        business = None
        if self.is_bound:
            business_id = self.data.get(self.add_prefix('business'))
            if business_id:
                business = business_queryset.filter(id=business_id).first()
        else:
            business = self.initial.get('business')

        if business:
            self.fields['course'].queryset = Course.objects.filter(business=business).order_by('title', 'id')
        else:
            self.fields['course'].queryset = Course.objects.filter(business__isnull=True).order_by('title', 'id')

    def clean(self):
        cleaned_data = super().clean()
        business = cleaned_data.get('business')
        course = cleaned_data.get('course')
        if business and course and course.business_id and course.business_id != business.id:
            self.add_error('course', 'Select a course from the same business.')
        return cleaned_data

    def clean_video_file(self):
        return validate_browser_safe_video(self.cleaned_data.get('video_file'))

    def clean_pdf_file(self):
        return validate_browser_safe_pdf(self.cleaned_data.get('pdf_file'))


class SuperAdminCourseCatalogPublishForm(forms.Form):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='اختر الشركة',
        label='الشركة',
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['business'].queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')


class SuperAdminCourseBusinessAssignmentForm(forms.Form):
    course = forms.ModelChoiceField(
        queryset=Course.objects.none(),
        empty_label='اختر الدورة',
        label='الدورة',
    )
    businesses = forms.ModelMultipleChoiceField(
        queryset=BusinessTenant.objects.none(),
        required=False,
        label='الشركات',
        widget=forms.SelectMultiple,
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['course'].queryset = Course.objects.filter(business__isnull=True).order_by('title', 'id')
        self.fields['businesses'].queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')


class SuperAdminExamTemplateForm(forms.ModelForm):
    primary_course = forms.ModelChoiceField(
        queryset=Course.objects.none(),
        empty_label='اختر الدورة',
        label='الدورة',
    )

    class Meta:
        model = ExamTemplate
        fields = [
            'name',
            'duration_minutes',
            'passing_score_percent',
            'instructions',
            'show_result_after_submit',
            'shuffle_questions',
        ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        course_queryset = Course.objects.filter(is_active=True).select_related('business').order_by('title', 'id')
        self.fields['primary_course'].queryset = course_queryset
        self.fields['primary_course'].label = 'الدورة'
        self.fields['name'].label = 'اسم قالب الاختبار'
        self.fields['duration_minutes'].label = 'مدة الاختبار بالدقائق'
        self.fields['passing_score_percent'].label = 'نسبة النجاح %'
        self.fields['instructions'].label = 'التعليمات'
        self.fields['show_result_after_submit'].label = 'إظهار النتيجة بعد التسليم'
        self.fields['shuffle_questions'].label = 'خلط الأسئلة'

        primary_course = None
        if self.is_bound:
            primary_course_id = self.data.get(self.add_prefix('primary_course'))
            if primary_course_id:
                primary_course = course_queryset.filter(id=primary_course_id).first()
        else:
            assigned_courses = self.instance.courses.order_by('title', 'id') if self.instance.pk else Course.objects.none()
            if assigned_courses:
                primary_course = assigned_courses.first()
                self.fields['primary_course'].initial = primary_course

    def clean(self):
        cleaned_data = super().clean()
        primary_course = cleaned_data.get('primary_course')
        if not primary_course:
            self.add_error('primary_course', 'اختر دورة واحدة على الأقل.')
            return cleaned_data

        cleaned_data['business'] = primary_course.business
        return cleaned_data


class SuperAdminExamSessionForm(forms.ModelForm):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='اختر الشركة',
        label='الشركة',
    )

    class Meta:
        model = CourseExamSession
        fields = ['business', 'course', 'exam_template', 'exam_date', 'access_code', 'is_active']
        widgets = {
            'exam_date': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        business_queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')
        self.fields['business'].queryset = business_queryset
        self.fields['course'].queryset = Course.objects.none()
        self.fields['exam_template'].queryset = ExamTemplate.objects.none()
        self.fields['course'].label = 'الدورة'
        self.fields['exam_template'].label = 'قالب الاختبار'
        self.fields['exam_date'].label = 'موعد الاختبار'
        self.fields['access_code'].label = 'كود الدخول'
        self.fields['is_active'].label = 'نشط'

        business = None
        if self.is_bound:
            business_id = self.data.get(self.add_prefix('business'))
            if business_id:
                business = business_queryset.filter(id=business_id).first()
        else:
            business = self.initial.get('business')
            if not business and self.instance.pk and self.instance.course_id:
                business = self.instance.course.business

        if business:
            self.fields['course'].queryset = Course.objects.filter(business=business).order_by('title', 'id')
            self.fields['exam_template'].queryset = ExamTemplate.objects.filter(business=business).order_by('name', 'id')

    def clean(self):
        cleaned_data = super().clean()
        business = cleaned_data.get('business')
        course = cleaned_data.get('course')
        exam_template = cleaned_data.get('exam_template')
        if business and course and course.business_id != business.id:
            self.add_error('course', 'اختر دورة من نفس الشركة.')
        if business and exam_template and exam_template.business_id not in (None, business.id):
            self.add_error('exam_template', 'اختر قالبًا من نفس الشركة.')
        return cleaned_data


class SuperAdminExamQuestionForm(forms.ModelForm):
    class Meta:
        model = ExamQuestion
        fields = [
            'question_text',
            'question_type',
            'points',
            'is_required',
            'shuffle_options',
            'explanation',
        ]
        widgets = {
            'question_text': forms.Textarea(attrs={'rows': 4}),
            'explanation': forms.Textarea(attrs={'rows': 3}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['question_text'].label = 'نص السؤال'
        self.fields['question_type'].label = 'نوع السؤال'
        self.fields['points'].label = 'درجة السؤال'
        self.fields['is_required'].label = 'سؤال إلزامي'
        self.fields['shuffle_options'].label = 'خلط الخيارات'
        self.fields['explanation'].label = 'شرح الإجابة'


class SuperAdminExamOptionForm(forms.ModelForm):
    class Meta:
        model = ExamOption
        fields = ['option_text', 'is_correct']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['option_text'].label = 'الخيار'
        self.fields['is_correct'].label = 'إجابة صحيحة'
