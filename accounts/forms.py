from django import forms
from django.contrib.auth import get_user_model
from django.core.validators import RegexValidator

from .models import BusinessTenant, JobTitle
from training.models import (
    Course,
    CourseAssignmentRule,
    CourseContentItem,
    CourseExamSession,
    ExamOption,
    ExamQuestion,
    ExamTemplate,
    SOPChecklist,
    SOPChecklistAssignmentRule,
)


User = get_user_model()


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


class JobTitleForm(forms.ModelForm):
    class Meta:
        model = JobTitle
        fields = ['name']


class CourseForm(forms.ModelForm):
    class Meta:
        model = Course
        fields = ['title', 'description', 'estimated_minutes', 'is_active']


class CourseAssignmentRuleForm(forms.ModelForm):
    class Meta:
        model = CourseAssignmentRule
        fields = ['job_title', 'course']

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business')
        super().__init__(*args, **kwargs)
        self.fields['job_title'].queryset = JobTitle.objects.filter(business=business).order_by('name', 'id')
        self.fields['course'].queryset = Course.objects.filter(business=business, is_active=True).order_by('title', 'id')


class CourseContentItemForm(forms.ModelForm):
    class Meta:
        model = CourseContentItem
        fields = ['course', 'content_type', 'title', 'body', 'material_url', 'video_file', 'pdf_file', 'order']

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business')
        super().__init__(*args, **kwargs)
        self.fields['course'].queryset = Course.objects.filter(business=business).order_by('title', 'id')


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

    def clean(self):
        cleaned_data = super().clean()
        role = cleaned_data.get('role')
        business = cleaned_data.get('business')
        if role == 'business_owner' and not business:
            self.add_error('business', 'Select a business for the business owner.')
        return cleaned_data


class SuperAdminCourseCreateForm(forms.ModelForm):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='Select business',
    )

    class Meta:
        model = Course
        fields = ['business', 'title', 'description', 'estimated_minutes', 'is_active']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['business'].queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')


class SuperAdminCourseAssignmentRuleForm(forms.ModelForm):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='Select business',
    )

    class Meta:
        model = CourseAssignmentRule
        fields = ['business', 'job_title', 'course']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        business_queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')
        self.fields['business'].queryset = business_queryset
        self.fields['job_title'].queryset = JobTitle.objects.none()
        self.fields['course'].queryset = Course.objects.none()

        business = None
        if self.is_bound:
            business_id = self.data.get(self.add_prefix('business'))
            if business_id:
                business = business_queryset.filter(id=business_id).first()
        else:
            business = self.initial.get('business')

        if business:
            self.fields['job_title'].queryset = JobTitle.objects.filter(business=business).order_by('name', 'id')
            self.fields['course'].queryset = Course.objects.filter(business=business, is_active=True).order_by('title', 'id')

    def clean(self):
        cleaned_data = super().clean()
        business = cleaned_data.get('business')
        job_title = cleaned_data.get('job_title')
        course = cleaned_data.get('course')
        if business and job_title and job_title.business_id != business.id:
            self.add_error('job_title', 'Select a job title from the same business.')
        if business and course and course.business_id != business.id:
            self.add_error('course', 'Select a course from the same business.')
        return cleaned_data


class SuperAdminCourseContentItemForm(forms.ModelForm):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='Select business',
    )

    class Meta:
        model = CourseContentItem
        fields = ['course', 'content_type', 'title', 'body', 'material_url', 'video_file', 'pdf_file', 'order']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        business_queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')
        self.fields['business'].queryset = business_queryset
        self.fields['course'].queryset = Course.objects.none()

        business = None
        if self.is_bound:
            business_id = self.data.get(self.add_prefix('business'))
            if business_id:
                business = business_queryset.filter(id=business_id).first()
        else:
            business = self.initial.get('business')

        if business:
            self.fields['course'].queryset = Course.objects.filter(business=business).order_by('title', 'id')

    def clean(self):
        cleaned_data = super().clean()
        business = cleaned_data.get('business')
        course = cleaned_data.get('course')
        if business and course and course.business_id != business.id:
            self.add_error('course', 'Select a course from the same business.')
        return cleaned_data


class SuperAdminCourseCatalogPublishForm(forms.Form):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='Select business',
        label='Business',
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['business'].queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')


class SuperAdminExamTemplateForm(forms.ModelForm):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='Select business',
    )
    course = forms.ModelChoiceField(
        queryset=Course.objects.none(),
        required=False,
        empty_label='Assign later',
    )

    class Meta:
        model = ExamTemplate
        fields = [
            'business',
            'course',
            'name',
            'duration_minutes',
            'passing_score_percent',
            'instructions',
            'show_result_after_submit',
            'shuffle_questions',
        ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        business_queryset = BusinessTenant.objects.filter(is_active=True).order_by('name', 'id')
        self.fields['business'].queryset = business_queryset
        self.fields['course'].queryset = Course.objects.none()

        business = None
        if self.is_bound:
            business_id = self.data.get(self.add_prefix('business'))
            if business_id:
                business = business_queryset.filter(id=business_id).first()
        else:
            business = self.initial.get('business') or getattr(self.instance, 'business', None)

        if business:
            self.fields['course'].queryset = Course.objects.filter(business=business).order_by('title', 'id')

        if self.instance.pk:
            assigned_course = self.instance.courses.order_by('id').first()
            if assigned_course and not self.is_bound:
                self.fields['course'].initial = assigned_course

    def clean(self):
        cleaned_data = super().clean()
        business = cleaned_data.get('business')
        course = cleaned_data.get('course')
        if business and course and course.business_id != business.id:
            self.add_error('course', 'Select a course from the same business.')
        return cleaned_data


class SuperAdminExamSessionForm(forms.ModelForm):
    business = forms.ModelChoiceField(
        queryset=BusinessTenant.objects.none(),
        empty_label='Select business',
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
            self.add_error('course', 'Select a course from the same business.')
        if business and exam_template and exam_template.business_id not in (None, business.id):
            self.add_error('exam_template', 'Select a template from the same business.')
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


class SuperAdminExamOptionForm(forms.ModelForm):
    class Meta:
        model = ExamOption
        fields = ['option_text', 'is_correct']
