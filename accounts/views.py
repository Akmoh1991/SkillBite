from datetime import datetime
import io
import json
import mimetypes
import os
from functools import lru_cache
from pathlib import Path
import urllib.parse
import uuid
import xml.etree.ElementTree as ET
import zipfile

from django.conf import settings
from django.contrib import messages
from django.contrib.auth import authenticate, get_user_model, login, logout
from django.contrib.auth.decorators import login_required
from django.core.files.base import ContentFile
from django.core.files.storage import FileSystemStorage
from django.db import IntegrityError, transaction
from django.db.models import Count, Prefetch, Q
from django.forms import inlineformset_factory
from django.http import FileResponse, Http404, HttpResponseForbidden, HttpResponsePermanentRedirect, JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone
from django.utils.http import url_has_allowed_host_and_scheme
from django.utils.text import get_valid_filename
from django.views.decorators.clickjacking import xframe_options_sameorigin
from django.views.decorators.http import require_POST

from certification.models import ScormCertificate
from training.models import Course, CourseAssignment, CourseBusinessAssignment, CourseContentItem, SOPChecklist, SOPChecklistAssignmentRule, SOPChecklistCompletion, SOPChecklistItem, SOPChecklistItemCompletion
from training.models import CourseExamSession, ExamOption, ExamQuestion, ExamTemplate

from .forms import (
    BusinessEmployeeCreateForm,
    CourseContentItemForm,
    CourseForm,
    JobTitleForm,
    RegisterForm,
    SOPChecklistAssignmentRuleForm,
    SOPChecklistForm,
    SuperAdminBusinessCreateForm,
    SuperAdminCourseBusinessAssignmentForm,
    SuperAdminCourseContentItemForm,
    SuperAdminCourseCreateForm,
    SuperAdminExamOptionForm,
    SuperAdminExamQuestionForm,
    SuperAdminExamSessionForm,
    SuperAdminExamTemplateForm,
    SuperAdminGrantRoleForm,
    SuperAdminUserCreateForm,
)
from .models import BusinessTenant, EmployeeProfile, JobTitle


User = get_user_model()

mimetypes.add_type('text/css', '.css')
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/json', '.json')
mimetypes.add_type('image/svg+xml', '.svg')
mimetypes.add_type('audio/mpeg', '.mp3')


def _is_business_owner(user) -> bool:
    return bool(user and user.is_authenticated and BusinessTenant.objects.filter(owner=user, is_active=True).exists())


def _is_super_admin(user) -> bool:
    return bool(user and user.is_authenticated and (getattr(user, 'is_superuser', False) or getattr(user, 'is_staff', False)))


def _is_employee(user) -> bool:
    return bool(user and user.is_authenticated and EmployeeProfile.objects.filter(user=user, is_active=True, business__is_active=True).exists())


def _super_admin_guard(request) -> bool:
    return _is_super_admin(getattr(request, 'user', None))


def _business_owner_guard(request) -> bool:
    return _is_business_owner(getattr(request, 'user', None))


def _employee_guard(request) -> bool:
    return _is_employee(getattr(request, 'user', None))


def _flash_form_errors(request, form, label_map: dict[str, str] | None = None) -> None:
    label_map = label_map or {}
    for field_name, errors in form.errors.items():
        label = label_map.get(field_name)
        if label is None and field_name != '__all__' and field_name in form.fields:
            label = form.fields[field_name].label or field_name
        label = label or 'النموذج'
        for error in errors:
            text = str(error)
            if text == 'This field is required.':
                text = 'هذا الحقل مطلوب.'
            messages.error(request, f'{label}: {text}')


def _primary_dashboard_route(user):
    if _is_super_admin(user):
        return 'super_admin_dashboard'
    if _is_business_owner(user):
        return 'business_owner_dashboard'
    if _is_employee(user):
        return 'employee_dashboard'
    return 'home'


def _get_owned_business(user):
    return BusinessTenant.objects.filter(owner=user, is_active=True).first()


def _get_employee_profile(user):
    return EmployeeProfile.objects.select_related('business', 'job_title', 'user').filter(user=user, is_active=True, business__is_active=True).first()


def _get_business_employee_profile(business, employee_id: int):
    return (
        EmployeeProfile.objects.select_related('user')
        .filter(business=business, is_active=True)
        .filter(id=employee_id)
        .first()
    )


def _assign_course_to_employee(*, business, course, employee_profile, assigned_by):
    assignment = CourseAssignment.objects.filter(
        business=business,
        course=course,
        employee=employee_profile.user,
    ).first()
    if assignment is None:
        CourseAssignment.objects.create(
            business=business,
            course=course,
            employee=employee_profile.user,
            assigned_by=assigned_by,
        )
        return True, None
    return False, 'هذه الدورة مدرجة بالفعل لهذا الموظف.'


EMPLOYEE_COURSE_CATALOG_PATH = Path(settings.BASE_DIR) / 'accounts' / 'data' / 'employee_course_catalog.json'


@lru_cache(maxsize=1)
def _load_employee_course_catalog():
    with EMPLOYEE_COURSE_CATALOG_PATH.open('r', encoding='utf-8') as catalog_file:
        return json.load(catalog_file)


def _course_card_defaults(course):
    fallback = {
        'card_image_url': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=900&q=80',
        'card_label': 'الدورة',
    }
    catalog_entry = next((item for item in _load_employee_course_catalog() if item['title'] == course.title), None)
    if catalog_entry:
        fallback['card_image_url'] = catalog_entry['card_image_url']
        fallback['card_label'] = catalog_entry['card_label']
    if not getattr(course, 'card_image_url', ''):
        course.card_image_url = fallback['card_image_url']
    if not getattr(course, 'card_label', ''):
        course.card_label = fallback['card_label']
    return course


def _visible_course_content_items(items):
    visible_items = []
    for item in items:
        if any(
            (
                (item.material_url or '').strip(),
                bool(item.video_file),
                bool(item.pdf_file),
            )
        ):
            visible_items.append(item)
    return visible_items


def _accessible_business_courses_queryset(business):
    return (
        Course.objects.filter(
            Q(business=business) | Q(business_assignments__business=business)
        )
        .distinct()
    )


def _publish_legacy_employee_course_catalog(business, created_by=None):
    catalog_entries = _load_employee_course_catalog()
    creator = created_by or User.objects.filter(is_active=True, is_staff=True, is_superuser=True).order_by('id').first() or business.owner
    published_courses = []
    for entry in catalog_entries:
        course, created = Course.objects.get_or_create(
            business=business,
            title=entry['title'],
            defaults={
                'description': entry['description'],
                'estimated_minutes': entry['estimated_minutes'],
                'is_active': True,
                'created_by': creator,
            },
        )
        if not created:
            changed_fields = []
            if not course.description:
                course.description = entry['description']
                changed_fields.append('description')
            if not course.estimated_minutes:
                course.estimated_minutes = entry['estimated_minutes']
                changed_fields.append('estimated_minutes')
            if changed_fields:
                course.save(update_fields=changed_fields)
        if not course.content_items.exists():
            for order in range(1, entry['content_count'] + 1):
                CourseContentItem.objects.create(
                    course=course,
                    content_type=CourseContentItem.ContentType.TEXT,
                    title=f"{entry['title']} - الجزء {order}",
                    body=entry['description'],
                    order=order,
                )
        published_courses.append(course)

    return published_courses


def _ensure_employee_courses_are_backed_by_db(business):
    if business:
        _publish_legacy_employee_course_catalog(business)


def _visible_employee_course_assignments_queryset(user, business):
    return (
        CourseAssignment.objects.filter(
            employee=user,
            business=business,
        )
        .select_related('course', 'assigned_by')
        .prefetch_related(
            Prefetch('course__content_items', queryset=CourseContentItem.objects.order_by('order', 'id'))
        )
        .order_by('-assigned_at', '-id')
    )


def _assigned_checklists_queryset(employee_profile):
    if not employee_profile or not employee_profile.job_title_id:
        return SOPChecklist.objects.none()
    queryset = SOPChecklist.objects.filter(business=employee_profile.business, is_active=True, assignment_rules__job_title=employee_profile.job_title).prefetch_related('items').distinct().order_by('title', 'id')
    if queryset.exists():
        return queryset
    if JobTitle.objects.filter(business=employee_profile.business).count() == 1:
        return SOPChecklist.objects.filter(business=employee_profile.business, is_active=True).prefetch_related('items').order_by('title', 'id')
    return queryset


def _display_name(user) -> str:
    full_name = f'{getattr(user, "first_name", "")} {getattr(user, "last_name", "")}'.strip()
    return full_name or getattr(user, 'username', 'User')


def _split_full_name(full_name: str) -> tuple[str, str]:
    cleaned = (full_name or '').strip()
    first_name, _, last_name = cleaned.partition(' ')
    return first_name.strip(), last_name.strip()


def _user_role_label(user) -> str:
    if _is_super_admin(user):
        return 'Super Admin'
    if BusinessTenant.objects.filter(owner=user).exists():
        return 'Business Owner'
    if EmployeeProfile.objects.filter(user=user).exists():
        return 'Employee'
    return 'User'


def _english_text_only(value: object, fallback: str = 'N/A') -> str:
    raw = '' if value is None else str(value)
    ascii_text = ''.join(ch for ch in raw if 32 <= ord(ch) <= 126)
    ascii_text = ' '.join(ascii_text.split())
    return ascii_text or fallback


def _safe_extract_zip(zip_abs_path: str, extract_to_dir: str) -> None:
    os.makedirs(extract_to_dir, exist_ok=True)
    with zipfile.ZipFile(zip_abs_path) as zf:
        for member in zf.infolist():
            member_name = (member.filename or '').replace('\\', '/')
            if not member_name:
                continue
            dest_path = os.path.normpath(os.path.join(extract_to_dir, member_name))
            if not dest_path.startswith(os.path.normpath(extract_to_dir) + os.sep):
                continue
            if member.is_dir() or member_name.endswith('/'):
                os.makedirs(dest_path, exist_ok=True)
                continue
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            with zf.open(member) as src, open(dest_path, 'wb') as dst:
                dst.write(src.read())


def _scorm_storage() -> FileSystemStorage:
    scorm_dir = os.path.join(settings.MEDIA_ROOT, 'scorm')
    os.makedirs(scorm_dir, exist_ok=True)
    return FileSystemStorage(location=scorm_dir, base_url=settings.MEDIA_URL.rstrip('/') + '/scorm/')


def _scorm_extracted_storage() -> FileSystemStorage:
    extracted_dir = os.path.join(settings.MEDIA_ROOT, 'scorm_extracted')
    os.makedirs(extracted_dir, exist_ok=True)
    return FileSystemStorage(location=extracted_dir, base_url=settings.MEDIA_URL.rstrip('/') + '/scorm_extracted/')


def _scorm_metadata_path() -> str:
    return os.path.join(_scorm_storage().location, 'metadata.json')


def _load_scorm_metadata() -> dict:
    try:
        with open(_scorm_metadata_path(), 'r', encoding='utf-8') as handle:
            data = json.load(handle)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _save_scorm_metadata(data: dict) -> None:
    try:
        with open(_scorm_metadata_path(), 'w', encoding='utf-8') as handle:
            json.dump(data, handle, ensure_ascii=False, indent=2)
    except Exception:
        pass


def _find_scorm_launch_relpath(extract_dir: str) -> str | None:
    manifest_path = os.path.join(extract_dir, 'imsmanifest.xml')
    if os.path.exists(manifest_path):
        try:
            tree = ET.parse(manifest_path)
            root = tree.getroot()
            for element in root.iter():
                if not str(element.tag).lower().endswith('resource'):
                    continue
                href = (element.attrib.get('href') or '').replace('\\', '/').lstrip('/')
                if not href:
                    continue
                candidate = os.path.normpath(os.path.join(extract_dir, href))
                if candidate.startswith(os.path.normpath(extract_dir) + os.sep) and os.path.isfile(candidate):
                    return href
        except Exception:
            pass
    for fallback in ('index.html', 'Index.html', 'INDEX.html'):
        candidate = os.path.join(extract_dir, fallback)
        if os.path.isfile(candidate):
            return fallback
    for root_dir, _dirs, files in os.walk(extract_dir):
        for filename in sorted(files, key=lambda item: item.lower()):
            if filename.lower().endswith('.html'):
                return os.path.relpath(os.path.join(root_dir, filename), extract_dir).replace('\\', '/')
    return None


def _ensure_extracted_for_zip(zip_filename: str) -> dict | None:
    storage = _scorm_storage()
    if not storage.exists(zip_filename):
        return None
    metadata = _load_scorm_metadata()
    entry = metadata.get(zip_filename)
    extracted_storage = _scorm_extracted_storage()
    if isinstance(entry, dict):
        folder = entry.get('folder')
        launch = entry.get('launch')
        if folder and launch and os.path.isfile(os.path.join(extracted_storage.location, folder, launch)):
            return entry
    zip_abs = os.path.join(storage.location, zip_filename)
    folder = f'{os.path.splitext(os.path.basename(zip_filename))[0]}_{uuid.uuid4().hex[:8]}'
    extract_dir = os.path.join(extracted_storage.location, folder)
    try:
        _safe_extract_zip(zip_abs, extract_dir)
        launch_rel = _find_scorm_launch_relpath(extract_dir)
    except Exception:
        launch_rel = None
    if not launch_rel:
        return None
    metadata[zip_filename] = {'folder': folder, 'launch': launch_rel, 'extracted_at': timezone.now().isoformat()}
    _save_scorm_metadata(metadata)
    return metadata[zip_filename]


def _get_scorm_entry_for_folder(folder: str) -> tuple[str, dict] | None:
    if not folder or '/' in folder or '\\' in folder:
        return None
    for zip_name, entry in _load_scorm_metadata().items():
        if isinstance(entry, dict) and entry.get('folder') == folder:
            return zip_name, entry
    return None


def _list_scorm_packages(include_download_url: bool = True):
    storage = _scorm_storage()
    extracted_storage = _scorm_extracted_storage()
    metadata = _load_scorm_metadata()
    packages = []
    try:
        names = os.listdir(storage.location)
    except FileNotFoundError:
        names = []
    for name in sorted(names, key=lambda item: item.lower()):
        if not name.lower().endswith('.zip'):
            continue
        file_path = os.path.join(storage.location, name)
        if not os.path.isfile(file_path):
            continue
        try:
            stat = os.stat(file_path)
            size_kb = int(stat.st_size / 1024)
            modified_at = datetime.fromtimestamp(stat.st_mtime)
        except OSError:
            size_kb = None
            modified_at = None
        package = {'name': name, 'url': storage.url(name) if include_download_url else None, 'size_kb': size_kb, 'modified_at': modified_at, 'launch_url': None}
        entry = metadata.get(name)
        if isinstance(entry, dict) and entry.get('folder') and entry.get('launch'):
            folder = str(entry['folder']).strip()
            launch = str(entry['launch']).replace('\\', '/').lstrip('/')
            if os.path.isfile(os.path.join(extracted_storage.location, folder, launch)):
                package['launch_url'] = extracted_storage.base_url.rstrip('/') + '/' + urllib.parse.quote(folder) + '/' + urllib.parse.quote(launch)
        packages.append(package)
    return packages


def _get_scorm_package_or_404(filename: str, include_download_url: bool = True):
    if not filename or '/' in filename or '\\' in filename or not filename.lower().endswith('.zip'):
        raise Http404('SCORM package not found')
    storage = _scorm_storage()
    if not storage.exists(filename):
        raise Http404('SCORM package not found')
    file_path = os.path.join(storage.location, filename)
    try:
        stat = os.stat(file_path)
        size_kb = int(stat.st_size / 1024)
        modified_at = datetime.fromtimestamp(stat.st_mtime)
    except OSError:
        size_kb = None
        modified_at = None
    extracted_storage = _scorm_extracted_storage()
    entry = _ensure_extracted_for_zip(filename)
    launch_url = None
    if isinstance(entry, dict) and entry.get('folder') and entry.get('launch'):
        folder = str(entry['folder']).strip()
        launch = str(entry['launch']).replace('\\', '/').lstrip('/')
        if os.path.isfile(os.path.join(extracted_storage.location, folder, launch)):
            launch_url = extracted_storage.base_url.rstrip('/') + '/' + urllib.parse.quote(folder) + '/' + urllib.parse.quote(launch)
    return {'name': filename, 'url': storage.url(filename) if include_download_url else None, 'size_kb': size_kb, 'modified_at': modified_at, 'launch_url': launch_url}


def _handle_scorm_upload_post(request, success_redirect_name: str):
    uploaded = request.FILES.get('scorm_zip')
    if not uploaded:
        messages.error(request, 'يرجى اختيار ملف SCORM بصيغة ZIP')
        return redirect(success_redirect_name)
    if not uploaded.name.lower().endswith('.zip'):
        messages.error(request, 'صيغة الملف غير مدعومة. يرجى رفع ملف ZIP فقط')
        return redirect(success_redirect_name)
    storage = _scorm_storage()
    safe_name = get_valid_filename(uploaded.name)
    if not safe_name.lower().endswith('.zip'):
        safe_name += '.zip'
    candidate = safe_name
    if storage.exists(candidate):
        base, ext = os.path.splitext(safe_name)
        candidate = f'{base}_{uuid.uuid4().hex[:8]}{ext}'
    storage.save(candidate, uploaded)
    try:
        _ensure_extracted_for_zip(candidate)
    except Exception:
        pass
    messages.success(request, 'تم رفع ملف SCORM بنجاح')
    return redirect(success_redirect_name)


def _generate_certificate_pdf_bytes(owner_name: str, course_name: str, verification_code: str, issued_at: datetime | None = None) -> bytes:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.pdfgen import canvas
    issued_at = issued_at or timezone.now()
    buffer = io.BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    dark_green = colors.HexColor('#0b6b57')
    brand_green = colors.HexColor('#11b67a')
    pale_green = colors.HexColor('#eaf8f1')
    slate = colors.HexColor('#24364b')
    pdf.setTitle('SkillBite Certificate')
    pdf.setFillColor(pale_green)
    pdf.rect(30, 30, width - 60, height - 60, fill=1, stroke=0)
    pdf.setStrokeColor(dark_green)
    pdf.setLineWidth(4)
    pdf.roundRect(45, 45, width - 90, height - 90, 18, stroke=1, fill=0)
    pdf.setLineWidth(1.5)
    pdf.setStrokeColor(brand_green)
    pdf.roundRect(60, 60, width - 120, height - 120, 14, stroke=1, fill=0)
    pdf.setFillColor(dark_green)
    pdf.setFont('Helvetica-Bold', 28)
    pdf.drawCentredString(width / 2, height - 120, 'SkillBite')
    pdf.setFillColor(brand_green)
    pdf.setFont('Helvetica-Bold', 24)
    pdf.drawCentredString(width / 2, height - 155, 'Certificate of Completion')
    pdf.setFillColor(slate)
    pdf.setFont('Helvetica', 13)
    pdf.drawCentredString(width / 2, height - 215, 'This certifies that')
    pdf.setFont('Helvetica-Bold', 24)
    pdf.drawCentredString(width / 2, height - 265, _english_text_only(owner_name, fallback='Learner'))
    pdf.setFont('Helvetica', 13)
    pdf.drawCentredString(width / 2, height - 310, 'has successfully completed the course')
    pdf.setFont('Helvetica-Bold', 20)
    pdf.drawCentredString(width / 2, height - 350, _english_text_only(course_name, fallback='SkillBite Course'))
    pdf.setFillColor(dark_green)
    pdf.setFont('Helvetica-Bold', 12)
    pdf.drawCentredString(width / 2, height - 420, f'Issued on {issued_at:%Y-%m-%d}')
    pdf.drawCentredString(width / 2, height - 442, f'Verification code: {verification_code}')
    pdf.setStrokeColor(brand_green)
    pdf.line(width / 2 - 100, 135, width / 2 + 100, 135)
    pdf.drawCentredString(width / 2, 118, 'SkillBite Certification')
    pdf.showPage()
    pdf.save()
    return buffer.getvalue()


def _issue_course_exam_certificate(user, course) -> tuple[str | None, str | None]:
    certificate_key = f'course_exam_{course.id}'
    cert, _created = ScormCertificate.objects.get_or_create(
        owner=user,
        scorm_filename=certificate_key,
        defaults={
            'course_name': course.title,
            'verification_code': uuid.uuid4().hex[:12].upper(),
        },
    )
    if cert.course_name != course.title:
        cert.course_name = course.title
        cert.save(update_fields=['course_name'])
    if not cert.pdf_file:
        try:
            pdf_bytes = _generate_certificate_pdf_bytes(
                owner_name=_display_name(user),
                course_name=course.title,
                verification_code=cert.verification_code,
                issued_at=getattr(cert, 'issued_at', None) or timezone.now(),
            )
            cert.pdf_file.save(
                f'course_certificate_{user.id}_{course.id}_{cert.verification_code}.pdf',
                ContentFile(pdf_bytes),
                save=False,
            )
            cert.save()
        except Exception:
            return None, 'تم إنهاء الاختبار، لكن تعذر إنشاء ملف الشهادة الآن.'
    return cert.pdf_file.url if cert.pdf_file else None, None


def _store_course_completion_popup(request, assignment):
    certificate_url, certificate_error = _issue_course_exam_certificate(request.user, assignment.course)
    request.session['course_completion_popup'] = {
        'course_title': assignment.course.title,
        'employee_name': _display_name(request.user),
        'completed_at': timezone.localtime(assignment.completed_at).strftime('%Y-%m-%d'),
        'certificate_url': certificate_url,
        'certificate_error': certificate_error,
    }


@xframe_options_sameorigin
@login_required
def scorm_player_file_view(request, folder: str, filepath: str):
    if not _super_admin_guard(request):
        return HttpResponseForbidden('Access denied')
    folder = (folder or '').strip()
    filepath = (filepath or '').replace('\\', '/').lstrip('/')
    if not _get_scorm_entry_for_folder(folder):
        raise Http404('SCORM file not found')
    base_dir = os.path.join(_scorm_extracted_storage().location, folder)
    base_dir_norm = os.path.normpath(base_dir)
    abs_path = os.path.normpath(os.path.join(base_dir_norm, filepath))
    if not abs_path.startswith(base_dir_norm + os.sep) or not os.path.isfile(abs_path):
        raise Http404('SCORM file not found')
    content_type, _enc = mimetypes.guess_type(abs_path)
    response = FileResponse(open(abs_path, 'rb'), content_type=content_type or 'application/octet-stream')
    response['Content-Disposition'] = 'inline'
    return response


@login_required
def scorm_player_file_redirect_view(request, folder: str, filepath: str):
    if not _super_admin_guard(request):
        return HttpResponseForbidden('Access denied')
    return HttpResponsePermanentRedirect(reverse('scorm_player_file', kwargs={'folder': folder, 'filepath': filepath}))


@login_required
def scorm_zip_download_view(request, filename: str):
    if not _super_admin_guard(request):
        return HttpResponseForbidden('غير مصرح لك')
    if not filename or '/' in filename or '\\' in filename or not filename.lower().endswith('.zip'):
        raise Http404('SCORM package not found')
    storage = _scorm_storage()
    if not storage.exists(filename):
        raise Http404('SCORM package not found')
    response = FileResponse(open(os.path.join(storage.location, filename), 'rb'), content_type='application/zip')
    response['Content-Disposition'] = f'attachment; filename="{filename}"'
    return response


def _super_admin_dashboard_context():
    businesses = BusinessTenant.objects.select_related('owner').order_by('name', 'id')
    assignments = CourseAssignment.objects.select_related('business', 'course', 'employee').order_by('-assigned_at', '-id')
    completions = SOPChecklistCompletion.objects.select_related('business', 'checklist', 'employee').order_by('-completed_for', '-completed_at', '-id')
    super_admins = User.objects.filter(is_active=True).filter(Q(is_staff=True) | Q(is_superuser=True)).order_by('username')
    return {
        'business_count': businesses.count(),
        'active_business_count': businesses.filter(is_active=True).count(),
        'employee_count': EmployeeProfile.objects.filter(is_active=True, business__is_active=True, user__is_active=True).count(),
        'course_count': Course.objects.count(),
        'active_course_count': Course.objects.filter(is_active=True).count(),
        'checklist_count': SOPChecklist.objects.count(),
        'active_checklist_count': SOPChecklist.objects.filter(is_active=True).count(),
        'completed_assignment_count': assignments.filter(status=CourseAssignment.Status.COMPLETED).count(),
        'super_admin_count': super_admins.count(),
        'recent_businesses': businesses[:6],
        'recent_assignments': assignments[:8],
        'recent_completions': completions[:8],
        'super_admins': super_admins[:6],
    }


def _super_admin_businesses_context():
    businesses = list(
        BusinessTenant.objects.select_related('owner')
        .annotate(
            employee_total=Count('employees', distinct=True),
            course_total=Count('courses', distinct=True),
            checklist_total=Count('sop_checklists', distinct=True),
        )
        .order_by('name', 'id')
    )
    return {'businesses': businesses, 'business_form': SuperAdminBusinessCreateForm()}


def _super_admin_business_create_context(form: SuperAdminBusinessCreateForm | None = None):
    return {'business_form': form or SuperAdminBusinessCreateForm()}


def _super_admin_users_context():
    users = list(
        User.objects.all()
        .select_related('owned_business', 'employee_profile__business', 'employee_profile__job_title')
        .order_by('username')
    )
    business_owner_count = 0
    employee_count = 0
    super_admin_count = 0
    for user in users:
        user.role_label = _user_role_label(user)
        user.business_name = ''
        if hasattr(user, 'owned_business'):
            user.business_name = user.owned_business.name
            business_owner_count += 1
        elif hasattr(user, 'employee_profile'):
            user.business_name = user.employee_profile.business.name
            employee_count += 1
        if _is_super_admin(user):
            super_admin_count += 1
    return {
        'users': users,
        'user_form': SuperAdminUserCreateForm(),
        'super_admin_count': super_admin_count,
        'business_owner_count': business_owner_count,
        'employee_count': employee_count,
    }


def _super_admin_user_create_context(form: SuperAdminUserCreateForm | None = None):
    return {'user_form': form or SuperAdminUserCreateForm()}


def _super_admin_user_role_grant_context(form: SuperAdminGrantRoleForm | None = None):
    return {'grant_role_form': form or SuperAdminGrantRoleForm()}


def _super_admin_learning_context():
    courses = list(
        Course.objects.select_related('business', 'created_by')
        .prefetch_related('business_assignments__business')
        .annotate(
            content_item_total=Count('content_items', distinct=True),
            assignment_total=Count('assignments', distinct=True),
            assigned_business_total=Count('business_assignments', distinct=True),
        )
        .order_by('title', 'id')
    )
    for course in courses:
        course.visible_businesses = [assignment.business for assignment in course.business_assignments.all()]
    checklists = list(
        SOPChecklist.objects.select_related('business', 'created_by')
        .annotate(item_total=Count('items'), completion_total=Count('completions'))
        .order_by('business__name', 'title', 'id')
    )
    exam_templates = list(
        ExamTemplate.objects.select_related('business', 'created_by')
        .annotate(question_total=Count('questions'))
        .order_by('business__name', 'name', 'id')
    )
    exam_sessions = list(
        CourseExamSession.objects.select_related('course', 'course__business', 'exam_template')
        .order_by('-exam_date', '-id')[:10]
    )
    return {
        'courses': courses,
        'checklists': checklists,
        'course_count': len(courses),
        'checklist_count': len(checklists),
        'exam_template_count': len(exam_templates),
        'exam_session_count': len(exam_sessions),
        'course_form': SuperAdminCourseCreateForm(),
        'course_business_assignment_form': SuperAdminCourseBusinessAssignmentForm(),
        'course_content_form': SuperAdminCourseContentItemForm(),
        'businesses': BusinessTenant.objects.filter(is_active=True).order_by('name', 'id'),
    }


def _super_admin_learning_course_create_context(form: SuperAdminCourseCreateForm | None = None):
    return {'course_form': form or SuperAdminCourseCreateForm()}


def _super_admin_course_business_assignment_context(form: SuperAdminCourseBusinessAssignmentForm | None = None):
    courses = list(
        Course.objects.select_related('business')
        .prefetch_related('business_assignments__business')
        .order_by('title', 'id')
    )
    for course in courses:
        course.visible_businesses = [assignment.business for assignment in course.business_assignments.all()]
    return {
        'assignment_form': form or SuperAdminCourseBusinessAssignmentForm(),
        'courses': courses,
    }


def _super_admin_learning_content_create_context(form: SuperAdminCourseContentItemForm | None = None):
    return {'course_content_form': form or SuperAdminCourseContentItemForm()}


def _sync_exam_template_total_questions(template: ExamTemplate) -> None:
    total_questions = template.questions.count()
    if template.total_questions != total_questions:
        template.total_questions = total_questions
        template.save(update_fields=['total_questions', 'updated_at'])


def _super_admin_exam_templates_context():
    templates = list(
        ExamTemplate.objects.select_related('business', 'created_by')
        .annotate(question_total=Count('questions'), course_total=Count('courses'))
        .order_by('-created_at', '-id')
    )
    return {
        'templates': templates,
        'template_count': len(templates),
    }


def _super_admin_exam_sessions_context():
    sessions = list(
        CourseExamSession.objects.select_related('course', 'course__business', 'exam_template', 'created_by')
        .order_by('-exam_date', '-id')
    )
    return {
        'sessions': sessions,
        'session_count': len(sessions),
        'session_form': SuperAdminExamSessionForm(),
    }


def _super_admin_exam_grading_context():
    sessions = list(
        CourseExamSession.objects.select_related('course', 'course__business', 'exam_template')
        .annotate(assigned_employee_total=Count('course__assignments', distinct=True))
        .order_by('-exam_date', '-id')
    )
    return {
        'sessions': sessions,
        'session_count': len(sessions),
    }


def _super_admin_operations_context():
    assignments = CourseAssignment.objects.select_related(
        'business', 'course', 'employee'
    ).order_by('-assigned_at', '-id')[:30]
    completions = SOPChecklistCompletion.objects.select_related(
        'business', 'checklist', 'employee'
    ).order_by('-completed_for', '-completed_at', '-id')[:30]
    return {'assignments': assignments, 'completions': completions}


@login_required
def super_admin_dashboard_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-dashboard.html', _super_admin_dashboard_context())


@login_required
def super_admin_businesses_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-businesses.html', _super_admin_businesses_context())


@login_required
def super_admin_business_create_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-business-create.html', _super_admin_business_create_context())


@login_required
def super_admin_users_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-users.html', _super_admin_users_context())


@login_required
def super_admin_user_create_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-user-create.html', _super_admin_user_create_context())


@login_required
def super_admin_user_role_grant_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-user-role-grant.html', _super_admin_user_role_grant_context())


@login_required
def super_admin_learning_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-learning.html', _super_admin_learning_context())


@login_required
def super_admin_course_list_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    courses = list(
        Course.objects.select_related('business')
        .filter(is_active=True)
        .prefetch_related('business_assignments__business')
        .prefetch_related(Prefetch('content_items', queryset=CourseContentItem.objects.order_by('order', 'id')))
        .order_by('title', 'id')
    )
    for course in courses:
        _course_card_defaults(course)
        course.visible_businesses = [assignment.business for assignment in course.business_assignments.all()]
    return render(
        request,
        'accounts-templates/super-admin-course-list.html',
        {
            'courses': courses,
        },
    )


@login_required
def super_admin_course_view(request, course_id: int):
    if not _super_admin_guard(request):
        return redirect('home')
    course = get_object_or_404(
        Course.objects.select_related('business').prefetch_related(
            'business_assignments__business',
            Prefetch('content_items', queryset=CourseContentItem.objects.order_by('order', 'id'))
        ),
        id=course_id,
        is_active=True,
    )
    _course_card_defaults(course)
    course.visible_businesses = [assignment.business for assignment in course.business_assignments.all()]
    content_items = _visible_course_content_items(course.content_items.all())
    return render(
        request,
        'accounts-templates/super-admin-course-view.html',
        {
            'course': course,
            'content_items': content_items,
        },
    )


@login_required
def super_admin_learning_course_create_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-learning-course-create.html', _super_admin_learning_course_create_context())


@login_required
def super_admin_course_business_assignments_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(
        request,
        'accounts-templates/super-admin-course-business-assignments.html',
        _super_admin_course_business_assignment_context(),
    )


@login_required
def super_admin_learning_content_create_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-learning-content-create.html', _super_admin_learning_content_create_context())


@login_required
def super_admin_exam_templates_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-exam-templates.html', _super_admin_exam_templates_context())


@login_required
def super_admin_exam_template_editor_view(request, template_id: int | None = None):
    if not _super_admin_guard(request):
        return redirect('home')
    template_obj = get_object_or_404(
        ExamTemplate.objects.select_related('business', 'created_by').prefetch_related('questions__options', 'courses'),
        id=template_id,
    ) if template_id is not None else None
    initial = {}
    if template_obj and template_obj.business_id:
        initial['business'] = template_obj.business
    form = SuperAdminExamTemplateForm(request.POST or None, instance=template_obj, initial=initial)
    if request.method == 'POST':
        if form.is_valid():
            saved_template = form.save(commit=False)
            saved_template.created_by = template_obj.created_by if template_obj else request.user
            saved_template.save()
            selected_courses = list(form.cleaned_data.get('courses') or [])
            Course.objects.filter(exam_template=saved_template).exclude(id__in=[course.id for course in selected_courses]).update(exam_template=None)
            for selected_course in selected_courses:
                if selected_course.exam_template_id != saved_template.id:
                    selected_course.exam_template = saved_template
                    selected_course.save(update_fields=['exam_template'])
            _sync_exam_template_total_questions(saved_template)
            messages.success(request, f'تم حفظ قالب الاختبار "{saved_template.name}".')
            return redirect('super_admin_exam_template_editor', template_id=saved_template.id)
        messages.error(request, form.errors.as_text())
    return render(
        request,
        'accounts-templates/super-admin-exam-template-editor.html',
        {
            'template_obj': template_obj,
            'template_form': form,
            'questions': template_obj.questions.all() if template_obj else [],
            'assigned_courses': template_obj.courses.select_related('business').order_by('business__name', 'title', 'id') if template_obj else [],
        },
    )


@login_required
@transaction.atomic
def super_admin_exam_question_editor_view(request, template_id: int, question_id: int | None = None):
    if not _super_admin_guard(request):
        return redirect('home')
    template_obj = get_object_or_404(ExamTemplate.objects.select_related('business', 'created_by'), id=template_id)
    question = get_object_or_404(ExamQuestion.objects.select_related('template'), id=question_id, template=template_obj) if question_id is not None else None
    option_formset_factory = inlineformset_factory(
        ExamQuestion,
        ExamOption,
        form=SuperAdminExamOptionForm,
        extra=4,
        can_delete=True,
    )
    question_form = SuperAdminExamQuestionForm(request.POST or None, instance=question)
    option_formset = option_formset_factory(request.POST or None, instance=question, prefix='options')
    if request.method == 'POST':
        if question_form.is_valid() and option_formset.is_valid():
            saved_question = question_form.save(commit=False)
            saved_question.template = template_obj
            if not saved_question.pk:
                saved_question.order = template_obj.questions.count() + 1
            saved_question.save()
            option_formset.instance = saved_question
            for deleted_form in option_formset.deleted_forms:
                if deleted_form.instance.pk:
                    deleted_form.instance.delete()

            next_option_order = 1
            for option_form in option_formset.forms:
                cleaned_data = getattr(option_form, 'cleaned_data', None) or {}
                if cleaned_data.get('DELETE'):
                    continue
                option_text = (cleaned_data.get('option_text') or '').strip()
                if not option_text:
                    continue
                option = option_form.save(commit=False)
                option.question = saved_question
                option.option_text = option_text
                option.order = next_option_order
                option.save()
                next_option_order += 1
            _sync_exam_template_total_questions(template_obj)
            messages.success(request, 'تم حفظ السؤال بنجاح.')
            return redirect('super_admin_exam_template_editor', template_id=template_obj.id)
        messages.error(request, question_form.errors.as_text() or 'يرجى مراجعة بيانات السؤال والخيارات.')
    return render(
        request,
        'accounts-templates/super-admin-question-editor.html',
        {
            'template_obj': template_obj,
            'question_obj': question,
            'q_form': question_form,
            'opt_formset': option_formset,
        },
    )


@login_required
@require_POST
def super_admin_exam_question_delete_action(request, template_id: int, question_id: int):
    if not _super_admin_guard(request):
        return redirect('home')
    template_obj = get_object_or_404(ExamTemplate, id=template_id)
    question = get_object_or_404(ExamQuestion, id=question_id, template=template_obj)
    question.delete()
    for index, item in enumerate(template_obj.questions.order_by('order', 'id'), start=1):
        if item.order != index:
            item.order = index
            item.save(update_fields=['order'])
    _sync_exam_template_total_questions(template_obj)
    messages.success(request, 'تم حذف السؤال بنجاح.')
    return redirect('super_admin_exam_template_editor', template_id=template_obj.id)


@login_required
def super_admin_exam_sessions_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    if request.method == 'POST':
        form = SuperAdminExamSessionForm(request.POST)
        if form.is_valid():
            session = form.save(commit=False)
            session.created_by = request.user
            if not session.exam_template_id:
                session.exam_template = session.course.exam_template
            session.save()
            messages.success(request, 'تم إنشاء جلسة الاختبار بنجاح.')
            return redirect('super_admin_exam_sessions')
        messages.error(request, form.errors.as_text())
        context = _super_admin_exam_sessions_context()
        context['session_form'] = form
        return render(request, 'accounts-templates/super-admin-exam-sessions.html', context)
    return render(request, 'accounts-templates/super-admin-exam-sessions.html', _super_admin_exam_sessions_context())


@login_required
def super_admin_exam_grading_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-exam-grading.html', _super_admin_exam_grading_context())


@login_required
@require_POST
@transaction.atomic
def super_admin_course_create_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    if not request.FILES.get('content_video_file'):
        messages.error(request, 'ملف الفيديو: هذا الحقل مطلوب.')
        return render(
            request,
            'accounts-templates/super-admin-learning-course-create.html',
            _super_admin_learning_course_create_context(SuperAdminCourseCreateForm(request.POST)),
        )
    form = SuperAdminCourseCreateForm(request.POST)
    if not form.is_valid():
        _flash_form_errors(request, form, {
            'title': 'عنوان الدورة',
            'description': 'الوصف',
            'estimated_minutes': 'المدة التقديرية بالدقائق',
            'is_active': 'الدورة نشطة',
        })
        return render(request, 'accounts-templates/super-admin-learning-course-create.html', _super_admin_learning_course_create_context(form))

    content_title = (request.POST.get('content_title') or '').strip()
    content_body = (request.POST.get('content_body') or '').strip()
    content_material_url = (request.POST.get('content_material_url') or '').strip()
    content_order = (request.POST.get('content_order') or '').strip() or '1'
    content_type = (request.POST.get('content_type') or CourseContentItem.ContentType.LESSON).strip()
    has_initial_content = any([
        content_title,
        content_body,
        content_material_url,
        request.FILES.get('content_video_file'),
        request.FILES.get('content_pdf_file'),
    ])

    if request.FILES.get('content_video_file') and not content_title:
        content_title = (request.POST.get('title') or '').strip()

    course = form.save(commit=False)
    course.business = None
    course.created_by = request.user
    course.save()

    if has_initial_content:
        content_data = request.POST.copy()
        content_data['course'] = str(course.id)
        content_data['title'] = content_title
        content_data['body'] = content_body
        content_data['material_url'] = content_material_url
        content_data['content_type'] = content_type
        content_data['order'] = content_order
        content_files = request.FILES.copy()
        if request.FILES.get('content_video_file'):
            content_files['video_file'] = request.FILES['content_video_file']
        if request.FILES.get('content_pdf_file'):
            content_files['pdf_file'] = request.FILES['content_pdf_file']
        content_form = SuperAdminCourseContentItemForm(content_data, content_files)
        if content_form.is_valid():
            content_item = content_form.save(commit=False)
            content_item.course = course
            content_item.save()
        else:
            _flash_form_errors(request, content_form, {
                'course': 'الدورة',
                'content_type': 'نوع المحتوى',
                'title': 'عنوان المحتوى',
                'body': 'الوصف',
                'material_url': 'رابط المادة',
                'video_file': 'ملف الفيديو',
                'pdf_file': 'ملف PDF',
                'order': 'الترتيب',
            })
            transaction.set_rollback(True)
            return render(
                request,
                'accounts-templates/super-admin-learning-course-create.html',
                _super_admin_learning_course_create_context(form),
            )

    messages.success(request, f'تم إنشاء الدورة "{course.title}" بنجاح.')
    return redirect('super_admin_learning')


@login_required
@require_POST
def super_admin_course_content_create_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminCourseContentItemForm(request.POST, request.FILES)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return render(request, 'accounts-templates/super-admin-learning-content-create.html', _super_admin_learning_content_create_context(form))
    content_item = form.save(commit=False)
    content_item.save()
    messages.success(request, f'Content item "{content_item.title}" added to "{content_item.course.title}".')
    return redirect('super_admin_learning')


@login_required
@require_POST
@transaction.atomic
def super_admin_course_business_assignments_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminCourseBusinessAssignmentForm(request.POST)
    if not form.is_valid():
        _flash_form_errors(request, form, {
            'course': 'الدورة',
            'businesses': 'الشركات',
        })
        return render(
            request,
            'accounts-templates/super-admin-course-business-assignments.html',
            _super_admin_course_business_assignment_context(form),
        )

    course = form.cleaned_data['course']
    businesses = list(form.cleaned_data['businesses'])
    CourseBusinessAssignment.objects.filter(course=course).delete()
    CourseBusinessAssignment.objects.bulk_create([
        CourseBusinessAssignment(course=course, business=business, assigned_by=request.user)
        for business in businesses
    ])
    messages.success(request, f'تم تحديث الشركات المسموح لها بمشاهدة الدورة "{course.title}".')
    return redirect('super_admin_course_business_assignments')


@login_required
def super_admin_operations_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-operations.html', _super_admin_operations_context())


@login_required
def super_admin_scorm_library_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    if not getattr(settings, 'SUPER_ADMIN_SCORM_PAGE_ENABLED', False):
        return redirect('home')
    if request.method == 'POST':
        return _handle_scorm_upload_post(request, 'super_admin_scorm')
    return render(request, 'accounts-templates/super-admin-scorm.html', {'packages': _list_scorm_packages(include_download_url=False)})


@login_required
@require_POST
@transaction.atomic
def super_admin_business_create_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminBusinessCreateForm(request.POST)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return render(request, 'accounts-templates/super-admin-business-create.html', _super_admin_business_create_context(form))
    username = form.cleaned_data['owner_username']
    if User.objects.filter(username=username).exists():
        messages.error(request, 'Username already exists.')
        return render(request, 'accounts-templates/super-admin-business-create.html', _super_admin_business_create_context(form))
    first_name, last_name = _split_full_name(form.cleaned_data['owner_full_name'])
    owner = User.objects.create_user(
        username=username,
        password=form.cleaned_data['owner_password'],
        email=(form.cleaned_data.get('owner_email') or '').strip(),
        first_name=first_name,
        last_name=last_name,
        is_active=True,
    )
    BusinessTenant.objects.create(
        owner=owner,
        name=form.cleaned_data['business_name'],
        industry=(form.cleaned_data.get('industry') or 'Food & Beverage').strip() or 'Food & Beverage',
        is_active=form.cleaned_data.get('is_active', False),
    )
    messages.success(request, 'Business and owner account created.')
    return redirect('super_admin_businesses')


@login_required
@require_POST
def super_admin_business_toggle_action(request, business_id: int):
    if not _super_admin_guard(request):
        return redirect('home')
    business = get_object_or_404(BusinessTenant, id=business_id)
    business.is_active = not business.is_active
    business.save(update_fields=['is_active'])
    messages.success(request, f'Business "{business.name}" is now {"active" if business.is_active else "inactive"}.')
    return redirect('super_admin_businesses')


@login_required
@require_POST
@transaction.atomic
def super_admin_user_create_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminUserCreateForm(request.POST)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return render(request, 'accounts-templates/super-admin-user-create.html', _super_admin_user_create_context(form))
    username = form.cleaned_data['username']
    if User.objects.filter(username=username).exists():
        messages.error(request, 'Username already exists.')
        return render(request, 'accounts-templates/super-admin-user-create.html', _super_admin_user_create_context(form))
    first_name, last_name = _split_full_name(form.cleaned_data['full_name'])
    role = form.cleaned_data['role']
    user = User.objects.create_user(
        username=username,
        password=form.cleaned_data['password'],
        email=(form.cleaned_data.get('email') or '').strip(),
        first_name=first_name,
        last_name=last_name,
        is_active=True,
        is_staff=(role == 'super_admin'),
        is_superuser=(role == 'super_admin'),
    )
    if role == 'business_owner':
        business = form.cleaned_data['business']
        business.owner = user
        business.save(update_fields=['owner'])
    messages.success(request, 'User account created.')
    return redirect('super_admin_users')


@login_required
@require_POST
def super_admin_user_role_grant_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminGrantRoleForm(request.POST)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return render(request, 'accounts-templates/super-admin-user-role-grant.html', _super_admin_user_role_grant_context(form))
    target = form.cleaned_data['user']
    if target.is_staff or target.is_superuser:
        messages.error(request, 'This user already has super admin access.')
        return render(request, 'accounts-templates/super-admin-user-role-grant.html', _super_admin_user_role_grant_context(form))
    target.is_staff = True
    target.is_superuser = True
    target.save(update_fields=['is_staff', 'is_superuser'])
    messages.success(request, f'User "{target.username}" is now a super admin.')
    return redirect('super_admin_users')


@login_required
@require_POST
def super_admin_user_toggle_active_action(request, user_id: int):
    if not _super_admin_guard(request):
        return redirect('home')
    target = get_object_or_404(User, id=user_id)
    if target == request.user and target.is_active:
        messages.error(request, 'You cannot deactivate your own account.')
        return redirect('super_admin_users')
    target.is_active = not target.is_active
    target.save(update_fields=['is_active'])
    messages.success(request, f'User "{target.username}" is now {"active" if target.is_active else "inactive"}.')
    return redirect('super_admin_users')


@login_required
@require_POST
def super_admin_user_toggle_role_action(request, user_id: int):
    if not _super_admin_guard(request):
        return redirect('home')
    target = get_object_or_404(User, id=user_id)
    if target == request.user and target.is_staff:
        messages.error(request, 'You cannot remove your own super admin access.')
        return redirect('super_admin_users')
    make_super = not _is_super_admin(target)
    if make_super:
        target.is_staff = True
        target.is_superuser = True
        target.save(update_fields=['is_staff', 'is_superuser'])
        messages.success(request, f'User "{target.username}" promoted to super admin.')
        return redirect('super_admin_users')
    if BusinessTenant.objects.filter(owner=target).exists():
        messages.error(request, 'Business owners must be reassigned before removing super admin access.')
        return redirect('super_admin_users')
    target.is_staff = False
    target.is_superuser = False
    target.save(update_fields=['is_staff', 'is_superuser'])
    messages.success(request, f'User "{target.username}" removed from super admin role.')
    return redirect('super_admin_users')


@login_required
@require_POST
def super_admin_course_toggle_action(request, course_id: int):
    if not _super_admin_guard(request):
        return redirect('home')
    course = get_object_or_404(Course, id=course_id)
    course.is_active = not course.is_active
    course.save(update_fields=['is_active'])
    messages.success(request, f'Course "{course.title}" is now {"active" if course.is_active else "inactive"}.')
    return redirect('super_admin_learning')


@login_required
@require_POST
def super_admin_checklist_toggle_action(request, checklist_id: int):
    if not _super_admin_guard(request):
        return redirect('home')
    checklist = get_object_or_404(SOPChecklist, id=checklist_id)
    checklist.is_active = not checklist.is_active
    checklist.save(update_fields=['is_active'])
    messages.success(request, f'Checklist "{checklist.title}" is now {"active" if checklist.is_active else "inactive"}.')
    return redirect('super_admin_learning')


def home_view(request):
    if request.user.is_authenticated:
        return redirect(_primary_dashboard_route(request.user))
    return render(request, 'home.html')


def register_view(request):
    if request.user.is_authenticated:
        return redirect('home')
    form = RegisterForm(request.POST or None, initial={'role': 'business_owner'})
    if request.method == 'POST' and form.is_valid():
        username = form.cleaned_data['username']
        if User.objects.filter(username=username).exists():
            messages.error(request, 'اسم المستخدم مستخدم مسبقاً')
            return redirect('register')
        user = User.objects.create_user(username=username, password=form.cleaned_data['password'])
        user.email = (form.cleaned_data.get('email') or '').strip()
        user.first_name = (form.cleaned_data.get('full_name_en') or '').strip()
        user.last_name = (form.cleaned_data.get('full_name_ar') or '').strip()
        user.save(update_fields=['email', 'first_name', 'last_name'])
        BusinessTenant.objects.get_or_create(owner=user, defaults={'name': (form.cleaned_data.get('company_name') or '').strip() or user.username, 'industry': 'Food & Beverage'})
        login(request, user)
        messages.success(request, 'تم إنشاء الحساب بنجاح')
        return redirect('business_owner_dashboard')
    if request.method == 'POST' and not form.is_valid():
        messages.error(request, 'تحقق من البيانات المدخلة')
    return render(request, 'accounts-templates/register.html', {'form': form, 'default_role': 'business_owner'})


def login_view(request):
    if request.user.is_authenticated:
        return redirect(_primary_dashboard_route(request.user))
    next_url = (request.POST.get('next') or request.GET.get('next') or '').strip()
    login_type = (request.GET.get('type') or '').strip().lower()
    if login_type not in {'individual', 'company'}:
        login_type = 'individual'
    if request.method == 'POST':
        user = authenticate(request, username=(request.POST.get('username') or '').strip(), password=request.POST.get('password') or '')
        if user:
            login(request, user)
            if next_url and url_has_allowed_host_and_scheme(url=next_url, allowed_hosts={request.get_host()}, require_https=request.is_secure()):
                return redirect(next_url)
            return redirect(_primary_dashboard_route(user))
        messages.error(request, 'اسم المستخدم أو كلمة المرور غير صحيحة')
    return render(request, 'accounts-templates/login.html', {'login_type': login_type, 'next': next_url})


def logout_view(request):
    logout(request)
    return redirect('home')


def _business_owner_dashboard_context(request):
    business = _get_owned_business(request.user)
    employees = list(
        EmployeeProfile.objects.filter(
            business=business,
            is_active=True,
            user__is_active=True,
        )
        .select_related('user', 'job_title')
        .order_by('user__username')
    )
    courses = business.courses.annotate(content_item_total=Count('content_items')).order_by('title', 'id')
    assignable_courses = (
        Course.objects.all()
        .select_related('business')
        .order_by('business__name', 'title', 'id')
    )
    checklists = business.sop_checklists.prefetch_related('items').order_by('title', 'id')
    job_titles = business.job_titles.order_by('name', 'id')
    checklist_rules = SOPChecklistAssignmentRule.objects.filter(business=business).select_related('job_title', 'checklist').order_by('job_title__name', 'checklist__title', 'id')
    course_assignment_counts = {row['course_id']: row['total'] for row in CourseAssignment.objects.filter(business=business).values('course_id').annotate(total=Count('id'))}
    checklist_completion_counts = {row['checklist_id']: row['total'] for row in SOPChecklistCompletion.objects.filter(business=business, completed_for=timezone.localdate()).values('checklist_id').annotate(total=Count('id'))}
    employee_course_map = {}
    for row in (
        CourseAssignment.objects.filter(
            business=business,
            employee__employee_profile__business=business,
        )
        .values('employee_id', 'course_id')
    ):
        employee_course_map.setdefault(row['employee_id'], set()).add(row['course_id'])
    for employee in employees:
        assigned_course_ids = sorted(employee_course_map.get(employee.user_id, set()))
        employee.assigned_course_ids_csv = ','.join(str(course_id) for course_id in assigned_course_ids)
    for course in courses:
        course.assignment_total = course_assignment_counts.get(course.id, 0)
    for checklist in checklists:
        checklist.completion_total_today = checklist_completion_counts.get(checklist.id, 0)
    return {
        'business': business,
        'employees': employees,
        'courses': courses,
        'assignable_courses': assignable_courses,
        'checklists': checklists,
        'job_titles': job_titles,
        'checklist_rules': checklist_rules,
        'employee_form': BusinessEmployeeCreateForm(business=business),
        'job_title_form': JobTitleForm(),
        'course_form': CourseForm(),
        'checklist_form': SOPChecklistForm(),
        'checklist_rule_form': SOPChecklistAssignmentRuleForm(business=business),
    }


@login_required
def business_owner_dashboard_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-dashboard.html', _business_owner_dashboard_context(request))


@login_required
@require_POST
@transaction.atomic
def business_owner_dashboard_delete_employee_action(request, employee_id: int):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    employee = _get_business_employee_profile(business, employee_id)
    if employee is None:
        messages.error(request, 'الموظف غير موجود أو تم حذفه بالفعل.')
        return redirect('business_owner_dashboard')
    employee.is_active = False
    employee.save(update_fields=['is_active'])
    employee.user.is_active = False
    employee.user.save(update_fields=['is_active'])
    messages.success(request, 'تم حذف الموظف.')
    return redirect('business_owner_dashboard')


@login_required
@require_POST
@transaction.atomic
def business_owner_dashboard_assign_course_action(request, employee_id: int):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    employee = _get_business_employee_profile(business, employee_id)
    if employee is None or not employee.user.is_active:
        messages.error(request, 'الموظف غير موجود أو غير نشط.')
        return redirect('business_owner_dashboard')
    course_id = (request.POST.get('course_id') or '').strip()
    if not course_id:
        messages.error(request, 'الدورة التدريبية: هذا الحقل مطلوب.')
        return redirect('business_owner_dashboard')
    course = Course.objects.filter(id=course_id).select_related('business').first()
    if course is None:
        messages.error(request, 'الدورة التدريبية المحددة غير صالحة.')
        return redirect('business_owner_dashboard')
    created, error_message = _assign_course_to_employee(
        business=business,
        course=course,
        employee_profile=employee,
        assigned_by=request.user,
    )
    if not created:
        messages.error(request, error_message or 'هذه الدورة مدرجة بالفعل لهذا الموظف.')
        return redirect('business_owner_dashboard')
    messages.success(request, f'تم إدراج الدورة "{course.title}" إلى {employee.user.username}')
    return redirect('business_owner_dashboard')


@login_required
def business_owner_employees_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-employees.html', _business_owner_dashboard_context(request))


@login_required
def business_owner_job_titles_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-job-titles.html', _business_owner_dashboard_context(request))


@login_required
def business_owner_courses_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-courses.html', _business_owner_dashboard_context(request))


@login_required
def business_owner_course_list_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    _ensure_employee_courses_are_backed_by_db(business)
    courses = list(
        _accessible_business_courses_queryset(business)
        .filter(is_active=True)
        .select_related('business')
        .prefetch_related(Prefetch('content_items', queryset=CourseContentItem.objects.order_by('order', 'id')))
        .order_by('title', 'id')
    )
    for course in courses:
        _course_card_defaults(course)
    return render(
        request,
        'accounts-templates/business-owner-course-list.html',
        {
            'business': business,
            'courses': courses,
        },
    )


@login_required
def business_owner_course_view(request, course_id: int):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    course = get_object_or_404(
        _accessible_business_courses_queryset(business).prefetch_related(
            Prefetch('content_items', queryset=CourseContentItem.objects.order_by('order', 'id'))
        ),
        id=course_id,
    )
    _course_card_defaults(course)
    content_items = _visible_course_content_items(course.content_items.all())
    return render(
        request,
        'accounts-templates/business-owner-course-view.html',
        {
            'business': business,
            'course': course,
            'content_items': content_items,
            'employees': EmployeeProfile.objects.select_related('user', 'job_title').filter(
                business=business,
                is_active=True,
                user__is_active=True,
            ).order_by('user__first_name', 'user__last_name', 'user__username', 'id'),
        },
    )


@login_required
@require_POST
@transaction.atomic
def business_owner_course_assign_employees_action(request, course_id: int):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    course = get_object_or_404(_accessible_business_courses_queryset(business).filter(is_active=True), id=course_id)
    employees = list(
        EmployeeProfile.objects.select_related('user', 'job_title').filter(
            business=business,
            is_active=True,
            user__is_active=True,
        )
    )
    if not employees:
        messages.error(request, 'لا يوجد موظفون متاحون لإدراج هذه الدورة')
        return redirect('business_owner_course_view', course_id=course.id)

    assign_scope = (request.POST.get('assign_scope') or '').strip()
    if assign_scope == 'all':
        selected_profiles = employees
    else:
        selected_ids = {value.strip() for value in request.POST.getlist('employee_ids') if value.strip()}
        if not selected_ids:
            messages.error(request, 'اختر موظفاً واحداً على الأقل أو اختر جميع الموظفين')
            return redirect('business_owner_course_view', course_id=course.id)
        selected_profiles = [employee for employee in employees if str(employee.id) in selected_ids]

    if not selected_profiles:
        messages.error(request, 'تعذر العثور على الموظفين المحددين')
        return redirect('business_owner_course_view', course_id=course.id)

    created_count = 0
    duplicate_count = 0
    for employee in selected_profiles:
        created, _ = _assign_course_to_employee(
            business=business,
            course=course,
            employee_profile=employee,
            assigned_by=request.user,
        )
        if created:
            created_count += 1
        else:
            duplicate_count += 1

    if created_count and duplicate_count:
        messages.success(request, f'تم إدراج الدورة "{course.title}" إلى {created_count} موظف/موظفين. وتم ترك {duplicate_count} كما هي لأنها مدرجة بالفعل وتظهر في لوحة الموظف')
    elif created_count:
        messages.success(request, f'تم إدراج الدورة "{course.title}" إلى {created_count} موظف')
    else:
        messages.error(request, 'هذه الدورة مدرجة بالفعل للموظفين المحددين وتظهر لهم في لوحة الموظف')

    return redirect('business_owner_course_view', course_id=course.id)


@login_required
def business_owner_course_content_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return redirect('business_owner_course_list')


@login_required
def business_owner_checklists_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-checklists.html', _business_owner_dashboard_context(request))


@login_required
def business_owner_reports_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    employees = list(
        EmployeeProfile.objects.filter(
            business=business,
            is_active=True,
            user__is_active=True,
        )
        .select_related('user', 'job_title')
        .order_by('user__first_name', 'user__last_name', 'user__username', 'id')
    )
    assignments = list(
        CourseAssignment.objects.filter(
            business=business,
            employee__employee_profile__business=business,
            employee__employee_profile__is_active=True,
            employee__is_active=True,
        )
        .select_related('course', 'employee__employee_profile__job_title')
        .order_by('employee__username', 'course__title', 'id')
    )

    employee_rows = []
    employee_assignment_map = {employee.user_id: [] for employee in employees}
    for assignment in assignments:
        employee_assignment_map.setdefault(assignment.employee_id, []).append(assignment)

    for employee in employees:
        employee_assignments = employee_assignment_map.get(employee.user_id, [])
        completed_total = sum(1 for assignment in employee_assignments if assignment.status == CourseAssignment.Status.COMPLETED)
        in_progress_total = sum(1 for assignment in employee_assignments if assignment.status == CourseAssignment.Status.IN_PROGRESS)
        assigned_total = len(employee_assignments)
        display_name = (
            f'{employee.user.first_name} {employee.user.last_name}'.strip()
            or employee.user.username
        )

        course_rows = []
        for assignment in employee_assignments:
            is_completed = assignment.status == CourseAssignment.Status.COMPLETED
            is_in_progress = assignment.status == CourseAssignment.Status.IN_PROGRESS
            course_rows.append(
                {
                    'title': assignment.course.title,
                    'status_label': assignment.get_status_display(),
                    'status_class': 'completed' if is_completed else 'in-progress' if is_in_progress else 'assigned',
                    'assigned_at': timezone.localtime(assignment.assigned_at),
                    'completed_at': timezone.localtime(assignment.completed_at) if assignment.completed_at else None,
                }
            )

        employee_rows.append(
            {
                'display_name': display_name,
                'username': employee.user.username,
                'job_title_name': employee.job_title.name if employee.job_title else '',
                'assigned_total': assigned_total,
                'completed_total': completed_total,
                'in_progress_total': in_progress_total,
                'completion_rate': round((completed_total / assigned_total) * 100) if assigned_total else 0,
                'course_rows': course_rows,
            }
        )

    total_assigned = len(assignments)
    total_completed = sum(1 for assignment in assignments if assignment.status == CourseAssignment.Status.COMPLETED)
    total_in_progress = sum(1 for assignment in assignments if assignment.status == CourseAssignment.Status.IN_PROGRESS)
    employees_with_completed_courses = sum(1 for row in employee_rows if row['completed_total'] > 0)

    return render(
        request,
        'accounts-templates/business-owner-reports.html',
        {
            'business': business,
            'employee_rows': employee_rows,
            'tracked_employee_total': len(employee_rows),
            'total_assigned': total_assigned,
            'total_completed': total_completed,
            'total_in_progress': total_in_progress,
            'employees_with_completed_courses': employees_with_completed_courses,
            'overall_completion_rate': round((total_completed / total_assigned) * 100) if total_assigned else 0,
        },
    )


@login_required
@require_POST
def business_owner_job_title_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    form = JobTitleForm(request.POST)
    if form.is_valid():
        job_title = form.save(commit=False)
        job_title.business = business
        try:
            job_title.save()
            messages.success(request, 'تمت إضافة المسمى الوظيفي')
        except IntegrityError:
            messages.error(request, 'هذا المسمى الوظيفي موجود بالفعل')
    else:
        messages.error(request, form.errors.as_text())
    return redirect('business_owner_employees')


@login_required
@require_POST
@transaction.atomic
def business_owner_employee_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    if not (request.POST.get('job_title') or '').strip():
        messages.error(request, 'المسمى الوظيفي: هذا الحقل مطلوب.')
        return redirect('business_owner_employees')
    form = BusinessEmployeeCreateForm(request.POST, business=business)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return redirect('business_owner_employees')
    username = form.cleaned_data['username']
    if User.objects.filter(username=username).exists():
        messages.error(request, 'اسم المستخدم مستخدم مسبقاً')
        return redirect('business_owner_employees')
    first_name, _, last_name = form.cleaned_data['full_name'].partition(' ')
    user = User.objects.create_user(username=username, password=form.cleaned_data['password'], email=(form.cleaned_data.get('email') or '').strip(), first_name=first_name.strip(), last_name=last_name.strip())
    employee_profile = EmployeeProfile.objects.create(user=user, business=business, job_title=form.cleaned_data.get('job_title'), created_by=request.user)
    messages.success(request, 'تم إنشاء حساب الموظف')
    return redirect('business_owner_employees')


@login_required
@require_POST
@transaction.atomic
def business_owner_course_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    if not request.FILES.get('content_video_file'):
        messages.error(request, '??? ???????: ??? ????? ?????.')
        return redirect('business_owner_courses')
    form = CourseForm(request.POST)
    if not form.is_valid():
        _flash_form_errors(request, form, {
            'title': '????? ??????',
            'description': '?????',
            'estimated_minutes': '????? ????????? ????????',
            'is_active': '???? ??????',
        })
        return redirect('business_owner_courses')

    content_title = (request.POST.get('content_title') or '').strip()
    content_body = (request.POST.get('content_body') or '').strip()
    content_material_url = (request.POST.get('content_material_url') or '').strip()
    content_order = (request.POST.get('content_order') or '').strip() or '1'
    content_type = (request.POST.get('content_type') or CourseContentItem.ContentType.LESSON).strip()
    has_initial_content = any([
        content_title,
        content_body,
        content_material_url,
        request.FILES.get('content_video_file'),
        request.FILES.get('content_pdf_file'),
    ])

    if request.FILES.get('content_video_file') and not content_title:
        content_title = (request.POST.get('title') or '').strip()

    course = form.save(commit=False)
    course.business = business
    course.created_by = request.user
    course.save()

    if has_initial_content:
        content_data = request.POST.copy()
        content_data['course'] = str(course.id)
        content_data['title'] = content_title
        content_data['body'] = content_body
        content_data['material_url'] = content_material_url
        content_data['content_type'] = content_type
        content_data['order'] = content_order
        content_files = request.FILES.copy()
        if request.FILES.get('content_video_file'):
            content_files['video_file'] = request.FILES['content_video_file']
        if request.FILES.get('content_pdf_file'):
            content_files['pdf_file'] = request.FILES['content_pdf_file']
        content_form = CourseContentItemForm(content_data, content_files, business=business)
        if content_form.is_valid():
            content_form.save()
        else:
            _flash_form_errors(request, content_form, {
                'title': 'عنوان المحتوى',
                'body': 'الوصف',
                'material_url': 'رابط المادة',
                'video_file': 'ملف الفيديو',
                'pdf_file': 'ملف PDF',
                'order': 'الترتيب',
            })
            transaction.set_rollback(True)
            return redirect('business_owner_courses')

    messages.success(request, 'تم إنشاء الدورة بنجاح')
    return redirect('business_owner_courses')


@login_required
@require_POST
def business_owner_course_content_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    form = CourseContentItemForm(request.POST, request.FILES, business=business)
    if form.is_valid():
        content_item = form.save()
        messages.success(request, 'تمت إضافة محتوى الدورة')
        return redirect(f"{reverse('business_owner_course_content')}?course={content_item.course_id}")
    messages.error(request, form.errors.as_text())
    selected_course = request.POST.get('course')
    redirect_url = reverse('business_owner_course_content')
    if selected_course and str(selected_course).isdigit():
        redirect_url = f'{redirect_url}?course={selected_course}'
    return redirect(redirect_url)


@login_required
@require_POST
def business_owner_course_content_update_action(request, item_id: int):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    content_item = get_object_or_404(CourseContentItem.objects.select_related('course'), id=item_id, course__business=business)
    form = CourseContentItemForm(request.POST, request.FILES, instance=content_item, business=business, prefix=f'item-{content_item.id}')
    if form.is_valid():
        updated_item = form.save()
        messages.success(request, 'تم تحديث محتوى الدورة')
        return redirect(f"{reverse('business_owner_course_content')}?course={updated_item.course_id}")
    messages.error(request, form.errors.as_text())
    return redirect(f"{reverse('business_owner_course_content')}?course={content_item.course_id}")


@login_required
@require_POST
def business_owner_course_content_delete_action(request, item_id: int):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    content_item = get_object_or_404(CourseContentItem.objects.select_related('course'), id=item_id, course__business=business)
    course_id = content_item.course_id
    content_item.delete()
    messages.success(request, 'تم حذف عنصر المحتوى')
    return redirect(f"{reverse('business_owner_course_content')}?course={course_id}")


@login_required
@require_POST
def business_owner_checklist_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    form = SOPChecklistForm(request.POST)
    if form.is_valid():
        checklist = form.save(commit=False)
        checklist.business = business
        checklist.created_by = request.user
        checklist.save()
        for index, item_title in enumerate(form.cleaned_data['item_lines'], start=1):
            SOPChecklistItem.objects.create(checklist=checklist, title=item_title, order=index)
        job_title_id = (request.POST.get('job_title') or '').strip()
        if job_title_id:
            job_title = JobTitle.objects.filter(id=job_title_id, business=business).first()
            if job_title:
                try:
                    SOPChecklistAssignmentRule.objects.create(
                        business=business,
                        job_title=job_title,
                        checklist=checklist,
                        assigned_by=request.user,
                    )
                except IntegrityError:
                    messages.warning(request, 'تم إنشاء القائمة، ولكنها مدرجة بالفعل لهذا المسمى الوظيفي.')
        messages.success(request, 'تم إنشاء قائمة تشغيلية')
    else:
        messages.error(request, form.errors.as_text())
    return redirect('business_owner_checklists')


@login_required
@require_POST
def business_owner_checklist_assignment_rule_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    form = SOPChecklistAssignmentRuleForm(request.POST, business=business)
    if form.is_valid():
        rule = form.save(commit=False)
        rule.business = business
        rule.assigned_by = request.user
        try:
            rule.save()
            messages.success(request, 'تم حفظ قاعدة إدراج قائمة SOP')
        except IntegrityError:
            messages.error(request, 'هذه القائمة مدرجة بالفعل لهذا المسمى الوظيفي')
    else:
        messages.error(request, form.errors.as_text())
    return redirect('business_owner_checklists')


def _employee_dashboard_context(request):
    employee_profile = _get_employee_profile(request.user)
    business = employee_profile.business
    today = timezone.localdate()
    _ensure_employee_courses_are_backed_by_db(business)
    course_assignments = _visible_employee_course_assignments_queryset(request.user, business)
    certificate_map = {}
    for cert in ScormCertificate.objects.filter(owner=request.user, scorm_filename__startswith='course_exam_'):
        suffix = (cert.scorm_filename or '').replace('course_exam_', '', 1)
        if suffix.isdigit() and cert.pdf_file:
            certificate_map[int(suffix)] = cert.pdf_file.url
    for assignment in course_assignments:
        _course_card_defaults(assignment.course)
        if assignment.status == CourseAssignment.Status.COMPLETED and assignment.course_id not in certificate_map:
            certificate_url, _certificate_error = _issue_course_exam_certificate(request.user, assignment.course)
            if certificate_url:
                certificate_map[assignment.course_id] = certificate_url
        assignment.course_certificate_url = certificate_map.get(assignment.course_id)
    completed_course_count = sum(1 for assignment in course_assignments if assignment.status == CourseAssignment.Status.COMPLETED)
    active_course_assignments = [assignment for assignment in course_assignments if assignment.status != CourseAssignment.Status.COMPLETED]
    dashboard_course_assignments = active_course_assignments[:3]
    assigned_checklists = list(_assigned_checklists_queryset(employee_profile))
    today_completions = {completion.checklist_id: completion for completion in SOPChecklistCompletion.objects.filter(business=business, employee=request.user, completed_for=today).select_related('checklist')}
    recent_checklist_completions = SOPChecklistCompletion.objects.filter(business=business, employee=request.user).select_related('checklist').order_by('-completed_for', '-completed_at')[:10]
    return {'employee_profile': employee_profile, 'business': business, 'course_assignments': course_assignments, 'active_course_assignments': active_course_assignments, 'dashboard_course_assignments': dashboard_course_assignments, 'completed_course_count': completed_course_count, 'assigned_checklists': assigned_checklists, 'today_completions': today_completions, 'recent_checklist_completions': recent_checklist_completions, 'today': today}


@login_required
def employee_dashboard_view(request):
    if not _employee_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/employee-dashboard.html', _employee_dashboard_context(request))


@login_required
def employee_courses_view(request):
    if not _employee_guard(request):
        return redirect('home')
    context = _employee_dashboard_context(request)
    context['course_completion_popup'] = request.session.pop('course_completion_popup', None)
    return render(request, 'accounts-templates/employee-courses.html', context)


@login_required
def employee_learning_history_view(request):
    if not _employee_guard(request):
        return redirect('home')
    context = _employee_dashboard_context(request)
    context['learning_history'] = [
        assignment
        for assignment in context['course_assignments']
        if assignment.status == CourseAssignment.Status.COMPLETED
    ]
    return render(request, 'accounts-templates/employee-learning-history.html', context)


@login_required
def employee_course_view(request, assignment_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    assignment = get_object_or_404(
        _visible_employee_course_assignments_queryset(request.user, employee_profile.business),
        id=assignment_id,
    )
    if assignment.status == CourseAssignment.Status.ASSIGNED:
        assignment.status = CourseAssignment.Status.IN_PROGRESS
        assignment.save(update_fields=['status'])
    content_items = _visible_course_content_items(assignment.course.content_items.all())
    return render(request, 'accounts-templates/employee-course-view.html', {'employee_profile': employee_profile, 'business': employee_profile.business, 'assignment': assignment, 'course': assignment.course, 'content_items': content_items})


@login_required
def employee_course_exam_view(request, assignment_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    assignment = get_object_or_404(
        _visible_employee_course_assignments_queryset(request.user, employee_profile.business),
        id=assignment_id,
    )
    content_items = list(assignment.course.content_items.all())
    exam_template = assignment.course.exam_template
    estimated_exam_minutes = exam_template.duration_minutes if exam_template else max(10, min(45, max(assignment.course.estimated_minutes, 1) // 2))
    return render(
        request,
        'accounts-templates/employee-course-exam.html',
        {
            'employee_profile': employee_profile,
            'business': employee_profile.business,
            'assignment': assignment,
            'course': assignment.course,
            'exam_template': exam_template,
            'content_items': content_items,
            'content_items_count': len(content_items),
            'estimated_exam_minutes': estimated_exam_minutes,
        },
    )


@login_required
def employee_course_exam_take_view(request, assignment_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    assignment = get_object_or_404(
        _visible_employee_course_assignments_queryset(request.user, employee_profile.business),
        id=assignment_id,
    )
    content_items = list(assignment.course.content_items.all())
    exam_template = assignment.course.exam_template
    exam_questions = list(exam_template.questions.prefetch_related('options').order_by('order', 'id')) if exam_template else []
    total_questions = max(len(exam_questions) or len(content_items), 1)
    requested_index = request.GET.get('q', '1')
    current_index = int(requested_index) if str(requested_index).isdigit() else 1
    current_index = max(1, min(current_index, total_questions))
    current_question = exam_questions[current_index - 1] if exam_questions else None
    current_question_options = list(current_question.options.all()) if current_question else []
    current_item = content_items[current_index - 1] if content_items and not current_question else None
    estimated_exam_minutes = exam_template.duration_minutes if exam_template else max(10, min(45, max(assignment.course.estimated_minutes, 1) // 2))
    return render(
        request,
        'accounts-templates/employee-course-exam-take.html',
        {
            'employee_profile': employee_profile,
            'business': employee_profile.business,
            'assignment': assignment,
            'course': assignment.course,
            'content_items': content_items,
            'exam_template': exam_template,
            'current_question': current_question,
            'current_question_options': current_question_options,
            'current_item': current_item,
            'current_index': current_index,
            'total_questions': total_questions,
            'is_template_question': bool(current_question),
            'remaining_seconds': estimated_exam_minutes * 60,
            'estimated_exam_minutes': estimated_exam_minutes,
        },
    )


@login_required
@require_POST
def employee_course_exam_submit_action(request, assignment_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    assignment = get_object_or_404(
        _visible_employee_course_assignments_queryset(request.user, employee_profile.business),
        id=assignment_id,
    )
    if not assignment.course.exam_template_id:
        messages.error(request, 'لا يوجد اختبار مرتبط بهذه الدورة.')
        return redirect('employee_course_view', assignment_id=assignment.id)
    assignment.status = CourseAssignment.Status.COMPLETED
    assignment.completed_at = timezone.now()
    assignment.save(update_fields=['status', 'completed_at'])
    _store_course_completion_popup(request, assignment)
    messages.success(request, f'تم إنهاء الاختبار وإكمال الدورة: {assignment.course.title}')
    return redirect('employee_courses')


@login_required
def employee_checklists_view(request):
    if not _employee_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/employee-checklists.html', _employee_dashboard_context(request))


@login_required
def employee_checklist_detail_view(request, checklist_id: int):
    if not _employee_guard(request):
        return redirect('home')
    context = _employee_dashboard_context(request)
    checklist = get_object_or_404(_assigned_checklists_queryset(context['employee_profile']), id=checklist_id)
    context['checklist'] = checklist
    context['checklist_completion'] = context['today_completions'].get(checklist.id)
    return render(request, 'accounts-templates/employee-checklist-detail.html', context)


@login_required
@require_POST
def employee_course_complete_action(request, assignment_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    assignment = get_object_or_404(
        _visible_employee_course_assignments_queryset(request.user, employee_profile.business),
        id=assignment_id,
    )
    assignment.status = CourseAssignment.Status.COMPLETED
    assignment.completed_at = timezone.now()
    assignment.save(update_fields=['status', 'completed_at'])
    _store_course_completion_popup(request, assignment)
    messages.success(request, f'تم إكمال الدورة: {assignment.course.title}')
    return redirect('employee_courses')


@login_required
@require_POST
@transaction.atomic
def employee_checklist_complete_action(request, checklist_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    checklist = get_object_or_404(_assigned_checklists_queryset(employee_profile), id=checklist_id)
    redirect_target = request.POST.get('next') or reverse('employee_checklists')
    if not url_has_allowed_host_and_scheme(
        url=redirect_target,
        allowed_hosts={request.get_host()},
        require_https=request.is_secure(),
    ):
        redirect_target = reverse('employee_checklists')
    items = list(checklist.items.all())
    selected_item_ids = {int(value) for value in request.POST.getlist('item_ids') if str(value).isdigit()}
    expected_item_ids = {item.id for item in items}
    if expected_item_ids and selected_item_ids != expected_item_ids:
        messages.error(request, 'يجب تحديد جميع عناصر قائمة SOP قبل الإكمال')
        return redirect(redirect_target)
    completion, created = SOPChecklistCompletion.objects.get_or_create(business=employee_profile.business, checklist=checklist, employee=request.user, completed_for=timezone.localdate(), defaults={'notes': (request.POST.get('notes') or '').strip()})
    if not created:
        completion.notes = (request.POST.get('notes') or '').strip()
        completion.save(update_fields=['notes'])
    for item in items:
        SOPChecklistItemCompletion.objects.update_or_create(completion=completion, item=item, defaults={'is_checked': True})
    messages.success(request, 'تم اكمال المهام اليومية')
    return redirect(redirect_target)


@login_required
def business_owner_scorm_library_view(request):
    return redirect('home')


@login_required
def employee_scorm_courses_view(request):
    return redirect('home')


@login_required
def employee_scorm_course_view(request, filename: str):
    return redirect('home')


@login_required
@require_POST
@transaction.atomic
def employee_scorm_check_complete_action(request, filename: str):
    return JsonResponse(
        {
            'ok': False,
            'completed': False,
            'message': 'SCORM completion tracking is disabled until a server-verified flow is implemented.',
        },
        status=403,
    )
    if not _employee_guard(request):
        return JsonResponse({'ok': False, 'message': 'غير مصرح'}, status=403)
    selected = _get_scorm_package_or_404(filename)
    course_name = str(selected.get('name') or filename)
    if course_name.lower().endswith('.zip'):
        course_name = course_name[:-4]
    lesson_status = (request.POST.get('lesson_status') or '').strip().lower()
    completion_status = (request.POST.get('completion_status') or '').strip().lower()
    success_status = (request.POST.get('success_status') or '').strip().lower()
    completed = lesson_status in {'completed', 'passed'} or completion_status == 'completed' or success_status == 'passed'
    if not completed:
        return JsonResponse({'ok': False, 'completed': False, 'message': 'لم يتم تسجيل إكمال الدورة بعد. أكمل الدورة ثم أعد المحاولة.'})
    cert, _created = ScormCertificate.objects.get_or_create(owner=request.user, scorm_filename=filename, defaults={'course_name': course_name, 'verification_code': uuid.uuid4().hex[:12].upper()})
    if not cert.course_name:
        cert.course_name = course_name
        cert.save(update_fields=['course_name'])
    certificate_url = cert.pdf_file.url if cert.pdf_file else None
    certificate_error = None
    if not certificate_url:
        try:
            pdf_bytes = _generate_certificate_pdf_bytes(owner_name=_display_name(request.user), course_name=course_name, verification_code=cert.verification_code, issued_at=getattr(cert, 'issued_at', None) or timezone.now())
            cert.pdf_file.save(f'scorm_certificate_{request.user.id}_{cert.verification_code}.pdf', ContentFile(pdf_bytes), save=False)
            cert.save()
            certificate_url = cert.pdf_file.url if cert.pdf_file else None
        except Exception:
            certificate_error = 'تم تسجيل الإكمال، لكن تعذر إنشاء ملف PDF الآن. حاول لاحقاً.'
    return JsonResponse({'ok': True, 'completed': True, 'certificate_url': certificate_url, 'certificate_error': certificate_error})
