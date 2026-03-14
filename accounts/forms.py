from django import forms
from django.contrib.auth import get_user_model
from django.core.validators import RegexValidator

from .models import BusinessTenant, JobTitle
from training.models import (
    Course,
    CourseAssignmentRule,
    CourseContentItem,
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
