import json
import re

from django import forms
from django.core.exceptions import ValidationError
from django.core.validators import RegexValidator
from django.forms import (
    formset_factory,
    BaseFormSet,
    inlineformset_factory,
    BaseInlineFormSet,
)

from .models import BusinessTenant, JobTitle
from training.models import (
    Course,
    CourseAssignmentRule,
    ExamTemplate,
    ExamQuestion,
    ExamOption,
    Program,
    ProgramExamPartConfig,
    ExternalPartAssessment,
    SOPChecklist,
    SOPChecklistAssignmentRule,
)
from training.program_catalog import PROGRAM_HIERARCHY


class MultipleFileInput(forms.ClearableFileInput):
    allow_multiple_selected = True


class MultipleFileField(forms.FileField):
    def clean(self, data, initial=None):
        if not data:
            return []
        if isinstance(data, (list, tuple)):
            cleaned = []
            for item in data:
                cleaned.append(super().clean(item, initial))
            return cleaned
        return [super().clean(data, initial)]


# =========================
# Auth / Register
# =========================

class RegisterForm(forms.Form):
    ROLE_CHOICES = (
        ('contractor', 'مقاول'),
        ('coordinator', 'شركة (منسق تدريب)'),
        ('trainer', 'مدرب'),
    )

    username = forms.CharField(label='اسم المستخدم', max_length=150)
    email = forms.EmailField(label='البريد الإلكتروني', required=False)
    full_name_en = forms.CharField(label='Full Name (English)', max_length=255)
    full_name_ar = forms.CharField(label='الاسم الكامل (بالعربية)', max_length=255)
    password = forms.CharField(label='كلمة المرور', widget=forms.PasswordInput)
    role = forms.ChoiceField(label='نوع الحساب', choices=ROLE_CHOICES)

    # حقول المقاول
    company_name = forms.CharField(label='اسم الشركة', max_length=255, required=False)
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
    sec_business_line = forms.ChoiceField(
        label='SEC Business line',
        choices=SEC_BUSINESS_LINE_CHOICES,
        required=False,
    )
    phone_number = forms.CharField(
        label='رقم الجوال',
        max_length=10,
        required=False,
        validators=[
            RegexValidator(
                regex=r'^0\d{9}$',
                message='رقم الجوال يجب أن يكون 10 أرقام ويبدأ بـ 0'
            )
        ],
        widget=forms.TextInput(attrs={
            'inputmode': 'numeric',
            'maxlength': '10',
            'autocomplete': 'tel',
        })
    )

    id_number = forms.CharField(
        label='رقم الهوية',
        max_length=10,
        required=False,
        validators=[
            RegexValidator(
                regex=r'^[12]\d{9}$',
                message='رقم الهوية يجب أن يكون 10 أرقام ويبدأ بـ 1 أو 2'
            )
        ],
        widget=forms.TextInput(attrs={
            'inputmode': 'numeric',
            'maxlength': '10',
            'autocomplete': 'off',
        })
    )

    REGION_CHOICES = (
        ('', 'اختر المنطقة'),
        ('Eastern region', 'المنطقة الشرقية'),
        ('Central region', 'المنطقة الوسطى'),
        ('Western region', 'المنطقة الغربية'),
        ('Southern region', 'المنطقة الجنوبية'),
    )

    region = forms.ChoiceField(
        label='المنطقة',
        choices=REGION_CHOICES,
        required=False,
    )

    # حقل المدرب
    specialization = forms.CharField(label='التخصص', max_length=255, required=False)

    def clean_email(self):
        # EmailField already validates format; just normalize whitespace.
        return (self.cleaned_data.get('email') or '').strip()

    def clean_full_name_en(self):
        return (self.cleaned_data.get('full_name_en') or '').strip()

    def clean_full_name_ar(self):
        return (self.cleaned_data.get('full_name_ar') or '').strip()

    def clean_phone_number(self):
        # Allow blank (depending on role); regex validator enforces format when provided.
        return (self.cleaned_data.get('phone_number') or '').strip()

    def clean_id_number(self):
        # Allow blank (depending on role); regex validator enforces format when provided.
        return (self.cleaned_data.get('id_number') or '').strip()

    def clean_region(self):
        # ChoiceField returns a string value.
        return (self.cleaned_data.get('region') or '').strip()

    def clean_sec_business_line(self):
        return (self.cleaned_data.get('sec_business_line') or '').strip()

    def clean(self):
        cleaned_data = super().clean()
        role = cleaned_data.get('role')

        if role in {'contractor', 'coordinator'}:
            if not cleaned_data.get('company_name'):
                self.add_error('company_name', ' اسم الشركة مطلوب')
            if not cleaned_data.get('phone_number'):
                self.add_error('phone_number', ' رقم الجوال مطلوب')
            if not cleaned_data.get('id_number'):
                self.add_error('id_number', ' رقم الهوية مطلوب')
            if not cleaned_data.get('region'):
                self.add_error('region', ' المنطقة مطلوبة')
            if not cleaned_data.get('sec_business_line'):
                self.add_error('sec_business_line', ' SEC Business line is required')

        if role == 'trainer':
            if not cleaned_data.get('specialization'):
                self.add_error('specialization', 'التخصص مطلوب')

        return cleaned_data


class TrainingCoordinatorRegisterContractorForm(forms.Form):
    """Form used by training coordinators to create contractor accounts."""

    username = forms.CharField(label='اسم المستخدم', max_length=150)
    email = forms.EmailField(label='البريد الإلكتروني', required=False)
    password = forms.CharField(label='كلمة المرور', widget=forms.PasswordInput)

    company_name = forms.CharField(label='اسم الشركة', max_length=255, required=True)

    phone_number = forms.CharField(
        label='رقم الجوال',
        max_length=10,
        required=True,
        validators=[
            RegexValidator(
                regex=r'^0\d{9}$',
                message='رقم الجوال يجب أن يكون 10 أرقام ويبدأ بـ 0'
            )
        ],
        widget=forms.TextInput(attrs={
            'inputmode': 'numeric',
            'maxlength': '10',
            'autocomplete': 'tel',
        })
    )

    id_number = forms.CharField(
        label='رقم الهوية',
        max_length=10,
        required=True,
        validators=[
            RegexValidator(
                regex=r'^[12]\d{9}$',
                message='رقم الهوية يجب أن يكون 10 أرقام ويبدأ بـ 1 أو 2'
            )
        ],
        widget=forms.TextInput(attrs={
            'inputmode': 'numeric',
            'maxlength': '10',
            'autocomplete': 'off',
        })
    )

    REGION_CHOICES = RegisterForm.REGION_CHOICES
    region = forms.ChoiceField(
        label='المنطقة',
        choices=REGION_CHOICES,
        required=True,
    )

    # Optional: create a training request at registration time
    program = forms.ModelChoiceField(
        label='البرنامج التدريبي (اختياري)',
        queryset=Program.objects.none(),
        required=False,
        empty_label='بدون تسجيل في برنامج الآن',
    )

    # Optional: upload one-or-more supporting PDFs
    pdf_files = MultipleFileField(
        label='مرفقات PDF (اختياري)',
        required=False,
        widget=MultipleFileInput(attrs={'multiple': True, 'accept': 'application/pdf'}),
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Keep queryset dynamic (safe for migrations/tests)
        self.fields['program'].queryset = Program.objects.filter(is_active=True).order_by('title')

    def clean_email(self):
        return (self.cleaned_data.get('email') or '').strip()

    def clean_phone_number(self):
        return (self.cleaned_data.get('phone_number') or '').strip()

    def clean_id_number(self):
        return (self.cleaned_data.get('id_number') or '').strip()

    def clean_region(self):
        return (self.cleaned_data.get('region') or '').strip()


# =========================
# ✅ Exam Template Form
# =========================

class ExamTemplateForm(forms.ModelForm):
    DEFAULT_PASSING_SCORE = 60

    class Meta:
        model = ExamTemplate
        fields = [
            'name',
            'duration_minutes',
            'passing_score_percent',
            'shuffle_questions',
            'show_result_after_submit',
            'instructions',
        ]
        widgets = {
            'name': forms.TextInput(attrs={
                'class': 'input',
                
            }),
            'duration_minutes': forms.NumberInput(attrs={
                'class': 'input',
                'min': 1,
                'max': 600
            }),
            'passing_score_percent': forms.NumberInput(attrs={
                'class': 'input',
                'min': 1,
                'max': 100
            }),
            'instructions': forms.Textarea(attrs={
                'class': 'textarea',
                'placeholder': 'تعليمات للمتدرب قبل بدء الاختبار (اختياري)',
                'rows': 3
            }),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # ✅ احذف أي حقل غير موجود فعليًا في الموديل
        model_field_names = {f.name for f in self._meta.model._meta.get_fields()}
        for key in list(self.fields.keys()):
            if key not in model_field_names:
                self.fields.pop(key, None)

        # ✅ default لنسبة النجاح
        if 'passing_score_percent' in self.fields:
            self.fields['passing_score_percent'].required = False
            if getattr(self.instance, 'passing_score_percent', None) in (None, ''):
                self.fields['passing_score_percent'].initial = self.DEFAULT_PASSING_SCORE

        for chk in ('shuffle_questions', 'show_result_after_submit'):
            if chk in self.fields:
                self.fields[chk].required = False

    def clean_duration_minutes(self):
        v = self.cleaned_data.get('duration_minutes')
        if v is None or v <= 0:
            raise ValidationError('مدة الاختبار لازم تكون رقم أكبر من صفر')
        if v > 600:
            raise ValidationError('مدة الاختبار كبيرة جدًا (حد أقصى 600 دقيقة)')
        return v

    def clean_passing_score_percent(self):
        if 'passing_score_percent' not in self.fields:
            return None

        v = self.cleaned_data.get('passing_score_percent')
        if v in (None, ''):
            return self.DEFAULT_PASSING_SCORE

        try:
            v = int(v)
        except (TypeError, ValueError):
            raise ValidationError('نسبة النجاح لازم تكون رقم')

        if v < 1 or v > 100:
            raise ValidationError('نسبة النجاح لازم تكون بين 1 و 100')

        return v


# ==========================================================
# ✅✅✅ الحل الحقيقي لمشكلة "الاختيارات ما تنحفظ"
# ----------------------------------------------------------
# بدل ما نخلي الخيارات مجرد FormSet عادي (يصعب حفظه للموديل)
# نستخدم InlineFormSet مربوط مباشرة بـ ExamQuestion -> ExamOption
# وبكذا لما تسوي formset.save() تنحفظ الخيارات في ExamOption model.
# ==========================================================

class ExamQuestionForm(forms.ModelForm):
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
            'question_text': forms.Textarea(attrs={
                'class': 'textarea',
                'placeholder': 'اكتب السؤال هنا...',
                'rows': 3
            }),
            'question_type': forms.Select(attrs={'class': 'input'}),
            'points': forms.NumberInput(attrs={'class': 'input', 'min': 1, 'max': 100}),
            'explanation': forms.Textarea(attrs={
                'class': 'textarea',
                'placeholder': 'توضيح سبب الإجابة الصحيحة (اختياري)',
                'rows': 2
            }),
        }

    def clean_question_text(self):
        txt = (self.cleaned_data.get('question_text') or '').strip()
        if not txt:
            raise ValidationError('نص السؤال مطلوب')
        if len(txt) < 3:
            raise ValidationError('السؤال قصير جدًا')
        if len(txt) > 4000:
            raise ValidationError('السؤال طويل جدًا')
        return txt

    def clean_explanation(self):
        txt = (self.cleaned_data.get('explanation') or '').strip()
        if txt and len(txt) > 4000:
            raise ValidationError('شرح الإجابة طويل جدًا')
        return txt


class ExamOptionForm(forms.ModelForm):
    class Meta:
        model = ExamOption
        fields = ['option_text', 'is_correct']
        widgets = {
            'option_text': forms.TextInput(attrs={
                'class': 'input',
                'placeholder': 'مثال: ارتداء الخوذة إلزامي'
            }),
        }


# =========================
# Super Admin – Programs
# =========================


class ProgramForm(forms.ModelForm):
    REQUIRED_TAX_CERTIFICATE_REQUIREMENT = '\u0625\u0631\u0641\u0627\u0642 \u0627\u0644\u0634\u0647\u0627\u062f\u0629 \u0627\u0644\u0636\u0631\u064a\u0628\u064a\u0629'
    NUMBERED_ITEM_RE = re.compile(r'^\s*(\d+)\s*[\.\-\)]\s*(.+?)\s*$')

    program_tertiary = forms.ChoiceField(
        required=False,
        choices=[('', 'No tertiary category')],
        widget=forms.Select(attrs={'class': 'input'}),
    )

    class Meta:
        model = Program
        fields = [
            'title',
            'title_ar',
            'title_en',
            'description',
            'requirements',
            'program_type',
            'program_subcategory',
            'program_tertiary',
            'outcome_type',
            'requires_approval',
            'requires_payment',
            'renewal_window_months',
            'is_active',
        ]
        widgets = {
            'title': forms.TextInput(attrs={'class': 'input', 'placeholder': 'اسم البرنامج'}),
            'title_ar': forms.TextInput(attrs={'class': 'input', 'placeholder': 'اسم البرنامج (عربي)'}),
            'title_en': forms.TextInput(attrs={'class': 'input', 'placeholder': 'Program Name (English)'}),
            'description': forms.Textarea(attrs={'class': 'textarea', 'rows': 4, 'placeholder': 'وصف البرنامج'}),
            'requirements': forms.Textarea(attrs={'class': 'textarea', 'rows': 3, 'placeholder': 'المتطلبات'}),
            'program_type': forms.Select(attrs={'class': 'input'}),
            'program_subcategory': forms.Select(attrs={'class': 'input'}),
            'outcome_type': forms.Select(attrs={'class': 'input'}),
            'renewal_window_months': forms.NumberInput(attrs={'class': 'input', 'min': 1, 'max': 36}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # `title` is not rendered in the template; derive it from Arabic/English names.
        self.fields['title'].required = False
        self.subcategory_map = self._build_subcategory_map()
        self.tertiary_map = self._build_tertiary_map()
        self.fields['program_subcategory'].required = False
        self.fields['program_subcategory'].choices = self._choices_for_program_type(
            self._current_program_type()
        )
        self.fields['program_tertiary'].choices = self._choices_for_subcategory(
            self._current_program_type(),
            self._current_program_subcategory(),
        )
        self.fields['program_tertiary'].initial = self._initial_program_tertiary()

    def _current_program_type(self):
        if self.is_bound:
            return (self.data.get('program_type') or '').strip()
        if getattr(self.instance, 'pk', None):
            return getattr(self.instance, 'program_type', '') or ''
        return (self.initial.get('program_type') or '').strip()

    def clean_requirements(self):
        requirements = (self.cleaned_data.get('requirements') or '').strip()
        lines = [line.strip() for line in requirements.splitlines() if line.strip()]
        cleaned_lines = []
        max_number = 0

        for line in lines:
            plain_text = self._strip_requirement_number(line)
            if plain_text == self.REQUIRED_TAX_CERTIFICATE_REQUIREMENT:
                continue
            cleaned_lines.append(line)
            parsed_number = self._extract_requirement_number(line)
            if parsed_number > max_number:
                max_number = parsed_number

        next_number = max_number + 1 if max_number else len(cleaned_lines) + 1
        cleaned_lines.append(f'{next_number}.{self.REQUIRED_TAX_CERTIFICATE_REQUIREMENT}')
        return '\n'.join(cleaned_lines)

    @classmethod
    def _strip_requirement_number(cls, line: str) -> str:
        match = cls.NUMBERED_ITEM_RE.match(line or '')
        return (match.group(2) if match else (line or '')).strip()

    @classmethod
    def _extract_requirement_number(cls, line: str) -> int:
        match = cls.NUMBERED_ITEM_RE.match(line or '')
        if not match:
            return 0
        try:
            return int(match.group(1))
        except (TypeError, ValueError):
            return 0

    @staticmethod
    def _build_subcategory_map():
        data = {}
        for category_code, entries in PROGRAM_HIERARCHY.items():
            values = []
            for entry in entries:
                values.append({
                    'code': entry.get('code', ''),
                    'label': entry.get('main_exam_ar') or entry.get('main_exam_en') or entry.get('code', ''),
                })
            data[category_code] = values
        return data

    @staticmethod
    def _build_tertiary_map():
        data = {}
        for category_code, entries in PROGRAM_HIERARCHY.items():
            per_sub = {}
            for entry in entries:
                tertiary_levels = entry.get('tertiary_levels') or []
                values = []
                for level in tertiary_levels:
                    values.append({
                        'code': level.get('code', ''),
                        'label': level.get('label_ar') or level.get('label_en') or level.get('code', ''),
                    })
                per_sub[entry.get('code', '')] = values
            data[category_code] = per_sub
        return data

    def _current_program_subcategory(self):
        if self.is_bound:
            return (self.data.get('program_subcategory') or '').strip()
        if getattr(self.instance, 'pk', None):
            return getattr(self.instance, 'program_subcategory', '') or ''
        return (self.initial.get('program_subcategory') or '').strip()

    def _choices_for_program_type(self, program_type):
        base = [('', 'بدون تصنيف فرعي')]
        options = self.subcategory_map.get(program_type, [])
        choices = base + [(item['code'], item['label']) for item in options if item.get('code')]

        current_value = ''
        if self.is_bound:
            current_value = (self.data.get('program_subcategory') or '').strip()
        elif getattr(self.instance, 'pk', None):
            current_value = (getattr(self.instance, 'program_subcategory', '') or '').strip()

        if current_value and current_value not in {c[0] for c in choices}:
            choices.append((current_value, current_value))

        return choices

    def _choices_for_subcategory(self, program_type, subcategory):
        base = [('', 'No tertiary category')]
        options = (self.tertiary_map.get(program_type, {}) or {}).get(subcategory, []) or []
        choices = base + [(item['code'], item['label']) for item in options if item.get('code')]

        current_value = ''
        if self.is_bound:
            current_value = (self.data.get('program_tertiary') or '').strip()
        elif getattr(self.instance, 'pk', None):
            current_value = self._infer_tertiary_from_instance()

        if current_value and current_value not in {c[0] for c in choices}:
            choices.append((current_value, current_value))

        return choices

    def _infer_tertiary_from_instance(self):
        if not getattr(self.instance, 'pk', None):
            return ''

        program_type = (getattr(self.instance, 'program_type', '') or '').strip()
        subcategory = (getattr(self.instance, 'program_subcategory', '') or '').strip()
        if not program_type or not subcategory:
            return ''

        title_candidates = {
            (getattr(self.instance, 'title', '') or '').strip().lower(),
            (getattr(self.instance, 'title_ar', '') or '').strip().lower(),
            (getattr(self.instance, 'title_en', '') or '').strip().lower(),
        }
        title_candidates.discard('')
        if not title_candidates:
            return ''

        entries = PROGRAM_HIERARCHY.get(program_type) or []
        sub_entry = next((item for item in entries if (item.get('code') or '') == subcategory), None)
        if not sub_entry:
            return ''

        for level in (sub_entry.get('tertiary_levels') or []):
            for prog in (level.get('programs') or []):
                names = {
                    (prog.get('en') or '').strip().lower(),
                    (prog.get('ar') or '').strip().lower(),
                }
                names.discard('')
                if names and names.intersection(title_candidates):
                    return (level.get('code') or '').strip()
        return ''

    def _initial_program_tertiary(self):
        if self.is_bound:
            return (self.data.get('program_tertiary') or '').strip()
        return self._infer_tertiary_from_instance()

    @property
    def subcategory_map_json(self):
        return json.dumps(self.subcategory_map, ensure_ascii=False)

    @property
    def tertiary_map_json(self):
        return json.dumps(self.tertiary_map, ensure_ascii=False)

    def clean_title(self):
        v = (self.cleaned_data.get('title') or '').strip()
        # Backward-compatible: allow title to be derived from Arabic/English fields.
        if not v:
            v = (
                (self.data.get('title_ar') or '').strip()
                or (self.data.get('title_en') or '').strip()
                or (self.cleaned_data.get('title_ar') or '').strip()
                or (self.cleaned_data.get('title_en') or '').strip()
            )
            if v:
                self.cleaned_data['title'] = v
        if not v:
            raise ValidationError('اسم البرنامج مطلوب')
        if len(v) > 255:
            raise ValidationError('اسم البرنامج طويل جدًا')
        return v

    def clean_program_subcategory(self):
        value = (self.cleaned_data.get('program_subcategory') or '').strip()
        program_type = (self.cleaned_data.get('program_type') or '').strip()
        allowed = {item['code'] for item in self.subcategory_map.get(program_type, []) if item.get('code')}
        if value and allowed and value not in allowed:
            raise ValidationError('التصنيف الفرعي المحدد غير صالح لهذا النوع')
        if not allowed:
            return ''
        return value

    def clean_program_tertiary(self):
        value = (self.cleaned_data.get('program_tertiary') or '').strip()
        program_type = (self.cleaned_data.get('program_type') or '').strip()
        subcategory = (self.cleaned_data.get('program_subcategory') or '').strip()
        allowed = {
            item.get('code', '')
            for item in ((self.tertiary_map.get(program_type, {}) or {}).get(subcategory, []) or [])
            if item.get('code')
        }
        if value and allowed and value not in allowed:
            raise ValidationError('Selected tertiary category is not valid for this subcategory')
        if not allowed:
            return ''
        return value

    def clean_renewal_window_months(self):
        value = self.cleaned_data.get('renewal_window_months')
        if value is None:
            return 6
        try:
            value = int(value)
        except Exception:
            raise ValidationError('فترة التجديد يجب أن تكون رقمًا صحيحًا')
        if value < 1 or value > 36:
            raise ValidationError('فترة التجديد يجب أن تكون بين 1 و 36 شهرًا')
        return value


class ProgramExamPartsConfigForm(forms.Form):
    """Super Admin grading configuration: choose included parts + passing per part."""

    include_theoretical = forms.BooleanField(label='نظري', required=False)
    theoretical_passing = forms.IntegerField(
        label='نسبة نجاح النظري %',
        required=False,
        min_value=1,
        max_value=100,
        widget=forms.NumberInput(attrs={'class': 'input', 'min': 1, 'max': 100}),
    )

    include_practical = forms.BooleanField(label='عملي', required=False)
    practical_passing = forms.IntegerField(
        label='نسبة نجاح العملي %',
        required=False,
        min_value=1,
        max_value=100,
        widget=forms.NumberInput(attrs={'class': 'input', 'min': 1, 'max': 100}),
    )

    include_project = forms.BooleanField(label='مشروع', required=False)
    project_passing = forms.IntegerField(
        label='نسبة نجاح المشروع %',
        required=False,
        min_value=1,
        max_value=100,
        widget=forms.NumberInput(attrs={'class': 'input', 'min': 1, 'max': 100}),
    )

    def clean(self):
        cleaned = super().clean()
        if not (cleaned.get('include_theoretical') or cleaned.get('include_practical') or cleaned.get('include_project')):
            raise ValidationError('اختر جزءاً واحداً على الأقل')
        if cleaned.get('include_theoretical') and cleaned.get('theoretical_passing') in (None, ''):
            self.add_error('theoretical_passing', 'حدد نسبة نجاح النظري')
        if cleaned.get('include_practical') and cleaned.get('practical_passing') in (None, ''):
            self.add_error('practical_passing', 'حدد نسبة نجاح العملي')
        if cleaned.get('include_project') and cleaned.get('project_passing') in (None, ''):
            self.add_error('project_passing', 'حدد نسبة نجاح المشروع')
        return cleaned


class ExternalPartAssessmentForm(forms.ModelForm):
    class Meta:
        model = ExternalPartAssessment
        fields = ['part_type', 'grade_percent', 'pdf_file']
        widgets = {
            'part_type': forms.Select(attrs={'class': 'input'}),
            'grade_percent': forms.NumberInput(attrs={'class': 'input', 'min': 0, 'max': 100}),
        }

    def clean_grade_percent(self):
        v = self.cleaned_data.get('grade_percent')
        if v is None:
            raise ValidationError('الدرجة مطلوبة')
        try:
            v = int(v)
        except Exception:
            raise ValidationError('الدرجة غير صحيحة')
        if v < 0 or v > 100:
            raise ValidationError('الدرجة يجب أن تكون بين 0 و 100')
        return v

    def clean_pdf_file(self):
        f = self.cleaned_data.get('pdf_file')
        if not f:
            return f
        name = (getattr(f, 'name', '') or '').lower()
        if name and not name.endswith('.pdf'):
            raise ValidationError('الملف المسموح به فقط: PDF')
        content_type = (getattr(f, 'content_type', '') or '').lower()
        if content_type and 'pdf' not in content_type:
            raise ValidationError('الملف المسموح به فقط: PDF')
        return f


class BusinessOwnerSetupForm(forms.ModelForm):
    class Meta:
        model = BusinessTenant
        fields = ['name', 'industry']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'input', 'placeholder': 'Business name'}),
            'industry': forms.TextInput(attrs={'class': 'input', 'placeholder': 'Food & Beverage'}),
        }

    def clean_name(self):
        value = (self.cleaned_data.get('name') or '').strip()
        if not value:
            raise ValidationError('Business name is required')
        return value


class JobTitleForm(forms.ModelForm):
    class Meta:
        model = JobTitle
        fields = ['name']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'input', 'placeholder': 'e.g. Barista'}),
        }

    def clean_name(self):
        value = (self.cleaned_data.get('name') or '').strip()
        if not value:
            raise ValidationError('Job title is required')
        return value


class BusinessEmployeeCreateForm(forms.Form):
    username = forms.CharField(label='Username', max_length=150)
    email = forms.EmailField(label='Email', required=False)
    full_name = forms.CharField(label='Full name', max_length=255)
    password = forms.CharField(label='Password', widget=forms.PasswordInput)
    job_title = forms.ModelChoiceField(
        label='Job title',
        queryset=JobTitle.objects.none(),
        required=False,
        empty_label='No job title yet',
    )

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business', None)
        super().__init__(*args, **kwargs)
        if business is not None:
            self.fields['job_title'].queryset = business.job_titles.order_by('name')

    def clean_username(self):
        return (self.cleaned_data.get('username') or '').strip()

    def clean_full_name(self):
        value = (self.cleaned_data.get('full_name') or '').strip()
        if not value:
            raise ValidationError('Full name is required')
        return value


class CourseForm(forms.ModelForm):
    class Meta:
        model = Course
        fields = ['title', 'description', 'estimated_minutes', 'is_active']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'input', 'placeholder': 'Course title'}),
            'description': forms.Textarea(attrs={'class': 'textarea', 'rows': 3, 'placeholder': 'What should the employee learn?'}),
            'estimated_minutes': forms.NumberInput(attrs={'class': 'input', 'min': 1}),
        }

    def clean_title(self):
        value = (self.cleaned_data.get('title') or '').strip()
        if not value:
            raise ValidationError('Course title is required')
        return value


class CourseAssignmentRuleForm(forms.ModelForm):
    class Meta:
        model = CourseAssignmentRule
        fields = ['job_title', 'course']
        widgets = {
            'job_title': forms.Select(attrs={'class': 'input'}),
            'course': forms.Select(attrs={'class': 'input'}),
        }

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business', None)
        super().__init__(*args, **kwargs)
        if business is not None:
            self.fields['job_title'].queryset = business.job_titles.order_by('name')
            self.fields['course'].queryset = business.courses.filter(is_active=True).order_by('title')


class SOPChecklistForm(forms.ModelForm):
    item_lines = forms.CharField(
        label='Checklist items',
        widget=forms.Textarea(attrs={'class': 'textarea', 'rows': 5, 'placeholder': 'One item per line'}),
        help_text='Enter one checklist item per line.',
    )

    class Meta:
        model = SOPChecklist
        fields = ['title', 'description', 'frequency', 'is_active']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'input', 'placeholder': 'Opening shift checklist'}),
            'description': forms.Textarea(attrs={'class': 'textarea', 'rows': 3, 'placeholder': 'Describe when employees should use this checklist'}),
            'frequency': forms.Select(attrs={'class': 'input'}),
        }

    def clean_title(self):
        value = (self.cleaned_data.get('title') or '').strip()
        if not value:
            raise ValidationError('Checklist title is required')
        return value

    def clean_item_lines(self):
        raw_value = self.cleaned_data.get('item_lines') or ''
        items = [line.strip() for line in raw_value.splitlines() if line.strip()]
        if not items:
            raise ValidationError('Add at least one checklist item')
        return items


class SOPChecklistAssignmentRuleForm(forms.ModelForm):
    class Meta:
        model = SOPChecklistAssignmentRule
        fields = ['job_title', 'checklist']
        widgets = {
            'job_title': forms.Select(attrs={'class': 'input'}),
            'checklist': forms.Select(attrs={'class': 'input'}),
        }

    def __init__(self, *args, **kwargs):
        business = kwargs.pop('business', None)
        super().__init__(*args, **kwargs)
        if business is not None:
            self.fields['job_title'].queryset = business.job_titles.order_by('name')
            self.fields['checklist'].queryset = business.sop_checklists.filter(is_active=True).order_by('title')


class TrainerRoleGrantForm(forms.Form):
    specialization = forms.CharField(
        label='التخصص',
        max_length=255,
        required=True,
        widget=forms.TextInput(attrs={'class': 'input', 'placeholder': 'مثال: السلامة المهنية'})
    )

    def clean_specialization(self):
        v = (self.cleaned_data.get('specialization') or '').strip()
        if not v:
            raise ValidationError('التخصص مطلوب')
        return v



class BaseExamOptionInlineFormSet(BaseInlineFormSet):
    """
    ✅ يتحقق حسب نوع السؤال + يمنع التكرار + يضمن عدد الخيارات والإجابات الصحيحة.
    """

    def clean(self):
        super().clean()
        if any(self.errors):
            return

        qt = getattr(self.instance, 'question_type', None)

        rows = []
        correct_count = 0

        for form in self.forms:
            if not hasattr(form, 'cleaned_data'):
                continue

            cd = form.cleaned_data or {}
            if cd.get('DELETE'):
                continue

            text = (cd.get('option_text') or '').strip()
            if not text:
                # ✅ نتجاهل الفاضي (extra)
                continue

            rows.append(text)
            if cd.get('is_correct'):
                correct_count += 1

        is_choice = qt in {
            ExamQuestion.QuestionType.MULTIPLE_CHOICE_SINGLE,
            ExamQuestion.QuestionType.MULTIPLE_CHOICE_MULTI,
            ExamQuestion.QuestionType.TRUE_FALSE,
        }

        if not is_choice:
            return

        if len(rows) != len(set(rows)):
            raise ValidationError('يوجد خيارات مكررة. عدّل الخيارات.')

        if qt == ExamQuestion.QuestionType.MULTIPLE_CHOICE_SINGLE:
            if len(rows) < 2:
                raise ValidationError('اختيار من متعدد يحتاج على الأقل خيارين.')
            if correct_count != 1:
                raise ValidationError('اختيار من متعدد (إجابة واحدة) لازم تحديد إجابة صحيحة واحدة فقط.')

        if qt == ExamQuestion.QuestionType.MULTIPLE_CHOICE_MULTI:
            if len(rows) < 2:
                raise ValidationError('اختيار متعدد يحتاج على الأقل خيارين.')
            if correct_count < 1:
                raise ValidationError('لازم تحدد على الأقل إجابة صحيحة واحدة.')

        if qt == ExamQuestion.QuestionType.TRUE_FALSE:
            if len(rows) < 2:
                raise ValidationError('صح/خطأ يحتاج خيارين (صح) و(خطأ).')
            if correct_count != 1:
                raise ValidationError('صح/خطأ لازم تحديد إجابة صحيحة واحدة.')


# ✅ هذا هو الفورم سِت اللي لازم تستخدمه في الـ view عند حفظ/تعديل السؤال
ExamOptionInlineFormSet = inlineformset_factory(
    parent_model=ExamQuestion,
    model=ExamOption,
    form=ExamOptionForm,
    formset=BaseExamOptionInlineFormSet,
    extra=4,
    max_num=10,
    can_delete=True
)


# =========================
# (اختياري) FormSet قديم (Backward-Compatible)
# =========================

class OptionForm(forms.Form):
    option_text = forms.CharField(
        label='نص الخيار',
        required=False,
        max_length=500,
        widget=forms.TextInput(attrs={
            'class': 'input',
            'placeholder': 'مثال: ارتداء الخوذة إلزامي'
        })
    )
    is_correct = forms.BooleanField(label='إجابة صحيحة', required=False)

    def clean_option_text(self):
        return (self.cleaned_data.get('option_text') or '').strip()


class BaseOptionFormSet(BaseFormSet):
    def __init__(self, *args, question_type=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.question_type = question_type

    def clean(self):
        super().clean()
        if any(self.errors):
            return

        rows = []
        correct_count = 0

        for form in self.forms:
            cd = form.cleaned_data or {}
            text = (cd.get('option_text') or '').strip()
            if not text:
                continue
            rows.append(text)
            if cd.get('is_correct'):
                correct_count += 1

        if len(rows) != len(set(rows)):
            raise ValidationError('يوجد خيارات مكررة. عدّل الخيارات.')

        qt = self.question_type

        if qt == ExamQuestion.QuestionType.MULTIPLE_CHOICE_SINGLE:
            if len(rows) < 2:
                raise ValidationError('اختيار من متعدد يحتاج على الأقل خيارين.')
            if correct_count != 1:
                raise ValidationError('اختيار من متعدد (إجابة واحدة) لازم تحديد إجابة صحيحة واحدة فقط.')

        if qt == ExamQuestion.QuestionType.MULTIPLE_CHOICE_MULTI:
            if len(rows) < 2:
                raise ValidationError('اختيار متعدد يحتاج على الأقل خيارين.')
            if correct_count < 1:
                raise ValidationError('لازم تحدد على الأقل إجابة صحيحة واحدة.')

        if qt == ExamQuestion.QuestionType.TRUE_FALSE:
            if len(rows) < 2:
                raise ValidationError('صح/خطأ يحتاج خيارين (صح) و(خطأ).')
            if correct_count != 1:
                raise ValidationError('صح/خطأ لازم تحديد إجابة صحيحة واحدة.')


OptionFormSet = formset_factory(
    OptionForm,
    formset=BaseOptionFormSet,
    extra=4,
    max_num=10
)


# =========================
# ✅ Manual (قديمة)
# =========================

class ManualQuestionForm(forms.Form):
    question_text = forms.CharField(
        label='نص السؤال',
        required=False,
        widget=forms.Textarea(attrs={
            'class': 'textarea',
            'placeholder': 'اكتب السؤال هنا...',
            'rows': 2
        })
    )

    def clean_question_text(self):
        txt = (self.cleaned_data.get('question_text') or '').strip()
        if txt and len(txt) < 3:
            raise ValidationError('السؤال قصير جدًا')
        if txt and len(txt) > 2000:
            raise ValidationError('السؤال طويل جدًا')
        return txt


ManualQuestionFormSet = formset_factory(ManualQuestionForm, extra=5, max_num=50)


# =========================
# ✅ Excel Upload
# =========================

class ExcelQuestionsUploadForm(forms.Form):
    excel_file = forms.FileField(
        label='ملف Excel للأسئلة',
        required=True,
        widget=forms.ClearableFileInput(attrs={'class': 'input', 'accept': '.xlsx'})
    )

    replace_existing = forms.BooleanField(
        label='استبدال الأسئلة الحالية',
        required=False,
        initial=False,
        widget=forms.CheckboxInput(attrs={'value': 'on'})
    )

    default_question_type = forms.ChoiceField(
        label='نوع السؤال الافتراضي',
        required=False,
        choices=ExamQuestion.QuestionType.choices,
        initial=ExamQuestion.QuestionType.SHORT_ANSWER,
        widget=forms.Select(attrs={'class': 'input'})
    )

    default_points = forms.IntegerField(
        label='درجة السؤال الافتراضية',
        required=False,
        min_value=1,
        max_value=100,
        initial=1,
        widget=forms.NumberInput(attrs={'class': 'input', 'min': 1, 'max': 100})
    )

    def clean_excel_file(self):
        f = self.cleaned_data.get('excel_file')
        if not f:
            raise ValidationError('اختر ملف Excel')

        name = (getattr(f, 'name', '') or '').lower()
        if not name.endswith('.xlsx'):
            raise ValidationError('الملف لازم يكون بصيغة .xlsx')

        max_size_mb = 5
        if getattr(f, 'size', 0) > max_size_mb * 1024 * 1024:
            raise ValidationError(f'حجم الملف كبير جدًا (حد أقصى {max_size_mb}MB)')

        return f
