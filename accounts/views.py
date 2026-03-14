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
from django.http import FileResponse, Http404, HttpResponseForbidden, HttpResponsePermanentRedirect, JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone
from django.utils.http import url_has_allowed_host_and_scheme
from django.utils.text import get_valid_filename
from django.views.decorators.clickjacking import xframe_options_sameorigin
from django.views.decorators.http import require_POST

from certification.models import ScormCertificate
from training.models import Course, CourseAssignment, CourseAssignmentRule, CourseContentItem, SOPChecklist, SOPChecklistAssignmentRule, SOPChecklistCompletion, SOPChecklistItem, SOPChecklistItemCompletion

from .forms import (
    BusinessEmployeeCreateForm,
    CourseAssignmentRuleForm,
    CourseContentItemForm,
    CourseForm,
    JobTitleForm,
    RegisterForm,
    SOPChecklistAssignmentRuleForm,
    SOPChecklistForm,
    SuperAdminBusinessCreateForm,
    SuperAdminCourseAssignmentRuleForm,
    SuperAdminCourseCatalogPublishForm,
    SuperAdminCourseContentItemForm,
    SuperAdminCourseCreateForm,
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

    job_titles = list(JobTitle.objects.filter(business=business).order_by('name', 'id'))
    if len(job_titles) > 1:
        for job_title in job_titles:
            for course in published_courses:
                CourseAssignmentRule.objects.get_or_create(
                    business=business,
                    job_title=job_title,
                    course=course,
                    defaults={'assigned_by': creator},
                )
    return published_courses


def _ensure_employee_courses_are_backed_by_db(business):
    if business:
        _publish_legacy_employee_course_catalog(business)


def _provision_course_assignments_for_employee(employee_profile, assigned_by=None):
    if not employee_profile or not employee_profile.job_title_id:
        return
    single_job_title_mode = JobTitle.objects.filter(business=employee_profile.business).count() == 1
    rules = CourseAssignmentRule.objects.filter(business=employee_profile.business, job_title=employee_profile.job_title, course__is_active=True).select_related('course', 'job_title')
    if single_job_title_mode:
        assigned_course_ids = set(rules.values_list('course_id', flat=True))
        implicit_courses = Course.objects.filter(business=employee_profile.business, is_active=True).exclude(id__in=assigned_course_ids)
        for course in implicit_courses:
            CourseAssignment.objects.get_or_create(
                business=employee_profile.business,
                course=course,
                employee=employee_profile.user,
                defaults={'assigned_by': assigned_by, 'assigned_via_job_title': employee_profile.job_title},
            )
    for rule in rules:
        CourseAssignment.objects.get_or_create(
            business=employee_profile.business,
            course=rule.course,
            employee=employee_profile.user,
            defaults={'assigned_by': assigned_by or rule.assigned_by, 'assigned_via_job_title': rule.job_title},
        )


def _ensure_course_assignments_for_rule(rule):
    employees = EmployeeProfile.objects.filter(business=rule.business, job_title=rule.job_title, is_active=True, user__is_active=True).select_related('user')
    for employee in employees:
        CourseAssignment.objects.get_or_create(
            business=rule.business,
            course=rule.course,
            employee=employee.user,
            defaults={'assigned_by': rule.assigned_by, 'assigned_via_job_title': rule.job_title},
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
    from reportlab.pdfgen import canvas
    issued_at = issued_at or timezone.now()
    buffer = io.BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    pdf.setTitle('SkillBite SCORM Certificate')
    pdf.setFont('Helvetica-Bold', 24)
    pdf.drawCentredString(width / 2, height - 120, 'SkillBite Certificate')
    pdf.setFont('Helvetica', 14)
    pdf.drawCentredString(width / 2, height - 170, 'Certificate of SCORM completion')
    pdf.setFont('Helvetica-Bold', 18)
    pdf.drawCentredString(width / 2, height - 250, _english_text_only(owner_name, fallback='Learner'))
    pdf.setFont('Helvetica', 14)
    pdf.drawCentredString(width / 2, height - 290, 'has successfully completed')
    pdf.setFont('Helvetica-Bold', 16)
    pdf.drawCentredString(width / 2, height - 330, _english_text_only(course_name, fallback='SCORM Course'))
    pdf.setFont('Helvetica', 12)
    pdf.drawCentredString(width / 2, height - 390, f'Issued at: {issued_at:%Y-%m-%d}')
    pdf.drawCentredString(width / 2, height - 415, f'Verification code: {verification_code}')
    pdf.showPage()
    pdf.save()
    return buffer.getvalue()


@xframe_options_sameorigin
def scorm_player_file_view(request, folder: str, filepath: str):
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


def scorm_player_file_redirect_view(request, folder: str, filepath: str):
    return HttpResponsePermanentRedirect(reverse('scorm_player_file', kwargs={'folder': folder, 'filepath': filepath}))


@login_required
def scorm_zip_download_view(request, filename: str):
    if not (_is_business_owner(request.user) or getattr(request.user, 'is_staff', False) or getattr(request.user, 'is_superuser', False)):
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


def _super_admin_learning_context():
    courses = list(
        Course.objects.select_related('business', 'created_by')
        .annotate(content_item_total=Count('content_items'), assignment_total=Count('assignments'))
        .order_by('business__name', 'title', 'id')
    )
    checklists = list(
        SOPChecklist.objects.select_related('business', 'created_by')
        .annotate(item_total=Count('items'), completion_total=Count('completions'))
        .order_by('business__name', 'title', 'id')
    )
    return {
        'courses': courses,
        'checklists': checklists,
        'course_count': len(courses),
        'checklist_count': len(checklists),
        'course_form': SuperAdminCourseCreateForm(),
        'course_rule_form': SuperAdminCourseAssignmentRuleForm(),
        'course_content_form': SuperAdminCourseContentItemForm(),
        'catalog_publish_form': SuperAdminCourseCatalogPublishForm(),
        'businesses': BusinessTenant.objects.filter(is_active=True).order_by('name', 'id'),
    }


def _super_admin_operations_context():
    assignments = CourseAssignment.objects.select_related(
        'business', 'course', 'employee', 'assigned_via_job_title'
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
def super_admin_users_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-users.html', _super_admin_users_context())


@login_required
def super_admin_learning_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-learning.html', _super_admin_learning_context())


@login_required
@require_POST
def super_admin_course_create_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminCourseCreateForm(request.POST)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return redirect('super_admin_learning')
    course = form.save(commit=False)
    course.created_by = request.user
    course.save()
    messages.success(request, f'Course "{course.title}" created for {course.business.name}.')
    return redirect('super_admin_learning')


@login_required
@require_POST
def super_admin_course_assignment_rule_create_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminCourseAssignmentRuleForm(request.POST)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return redirect('super_admin_learning')
    business = form.cleaned_data['business']
    rule = form.save(commit=False)
    rule.business = business
    rule.assigned_by = request.user
    try:
        rule.save()
        _ensure_course_assignments_for_rule(rule)
        messages.success(request, f'Assignment rule added for "{rule.course.title}".')
    except IntegrityError:
        messages.error(request, 'This course is already assigned to that job title.')
    return redirect('super_admin_learning')


@login_required
@require_POST
def super_admin_course_content_create_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminCourseContentItemForm(request.POST, request.FILES)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return redirect('super_admin_learning')
    content_item = form.save(commit=False)
    content_item.save()
    messages.success(request, f'Content item "{content_item.title}" added to "{content_item.course.title}".')
    return redirect('super_admin_learning')


@login_required
@require_POST
def super_admin_publish_employee_catalog_action(request):
    if not _super_admin_guard(request):
        return redirect('home')
    form = SuperAdminCourseCatalogPublishForm(request.POST)
    if not form.is_valid():
        messages.error(request, form.errors.as_text())
        return redirect('super_admin_learning')
    business = form.cleaned_data['business']
    published_courses = _publish_legacy_employee_course_catalog(business, created_by=request.user)
    messages.success(request, f'Published {len(published_courses)} employee courses to {business.name}.')
    return redirect('super_admin_learning')


@login_required
def super_admin_operations_view(request):
    if not _super_admin_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/super-admin-operations.html', _super_admin_operations_context())


@login_required
def super_admin_scorm_library_view(request):
    if not _super_admin_guard(request):
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
        return redirect('super_admin_businesses')
    username = form.cleaned_data['owner_username']
    if User.objects.filter(username=username).exists():
        messages.error(request, 'Username already exists.')
        return redirect('super_admin_businesses')
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
        return redirect('super_admin_users')
    username = form.cleaned_data['username']
    if User.objects.filter(username=username).exists():
        messages.error(request, 'Username already exists.')
        return redirect('super_admin_users')
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
    employees = EmployeeProfile.objects.filter(business=business).select_related('user', 'job_title').order_by('user__username')
    courses = business.courses.annotate(content_item_total=Count('content_items')).order_by('title', 'id')
    checklists = business.sop_checklists.prefetch_related('items').order_by('title', 'id')
    job_titles = business.job_titles.order_by('name', 'id')
    course_rules = CourseAssignmentRule.objects.filter(business=business).select_related('job_title', 'course').order_by('job_title__name', 'course__title', 'id')
    checklist_rules = SOPChecklistAssignmentRule.objects.filter(business=business).select_related('job_title', 'checklist').order_by('job_title__name', 'checklist__title', 'id')
    course_assignment_counts = {row['course_id']: row['total'] for row in CourseAssignment.objects.filter(business=business).values('course_id').annotate(total=Count('id'))}
    checklist_completion_counts = {row['checklist_id']: row['total'] for row in SOPChecklistCompletion.objects.filter(business=business, completed_for=timezone.localdate()).values('checklist_id').annotate(total=Count('id'))}
    for course in courses:
        course.assignment_total = course_assignment_counts.get(course.id, 0)
    for checklist in checklists:
        checklist.completion_total_today = checklist_completion_counts.get(checklist.id, 0)
    return {
        'business': business,
        'employees': employees,
        'courses': courses,
        'checklists': checklists,
        'job_titles': job_titles,
        'course_rules': course_rules,
        'checklist_rules': checklist_rules,
        'employee_form': BusinessEmployeeCreateForm(business=business),
        'job_title_form': JobTitleForm(),
        'course_form': CourseForm(),
        'course_rule_form': CourseAssignmentRuleForm(business=business),
        'checklist_form': SOPChecklistForm(),
        'checklist_rule_form': SOPChecklistAssignmentRuleForm(business=business),
    }


@login_required
def business_owner_dashboard_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-dashboard.html', _business_owner_dashboard_context(request))


@login_required
def business_owner_employees_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-employees.html', _business_owner_dashboard_context(request))


@login_required
def business_owner_courses_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-courses.html', _business_owner_dashboard_context(request))


@login_required
def business_owner_course_content_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    courses = list(business.courses.annotate(content_item_total=Count('content_items')).order_by('title', 'id'))
    selected_course = None
    selected_course_id = request.GET.get('course')
    if selected_course_id and str(selected_course_id).isdigit():
        selected_course = get_object_or_404(business.courses.annotate(content_item_total=Count('content_items')), id=int(selected_course_id))
    elif courses:
        selected_course = courses[0]
    content_items = []
    next_order = 1
    if selected_course is not None:
        content_items = list(selected_course.content_items.order_by('order', 'id'))
        next_order = (content_items[-1].order + 1) if content_items else 1
        for item in content_items:
            item.edit_form = CourseContentItemForm(instance=item, business=business, prefix=f'item-{item.id}')
    initial = {'order': next_order}
    if selected_course is not None:
        initial['course'] = selected_course
    return render(request, 'accounts-templates/business-owner-course-content.html', {'business': business, 'courses': courses, 'selected_course': selected_course, 'content_items': content_items, 'content_form': CourseContentItemForm(business=business, initial=initial)})


@login_required
def business_owner_checklists_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/business-owner-checklists.html', _business_owner_dashboard_context(request))


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
    _provision_course_assignments_for_employee(employee_profile, assigned_by=request.user)
    messages.success(request, 'تم إنشاء حساب الموظف')
    return redirect('business_owner_employees')


@login_required
@require_POST
def business_owner_course_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    form = CourseForm(request.POST)
    if form.is_valid():
        course = form.save(commit=False)
        course.business = business
        course.created_by = request.user
        course.save()
        messages.success(request, 'تم إنشاء الدورة')
    else:
        messages.error(request, form.errors.as_text())
    return redirect('business_owner_courses')


@login_required
@require_POST
def business_owner_course_assignment_rule_create_action(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    form = CourseAssignmentRuleForm(request.POST, business=business)
    if form.is_valid():
        rule = form.save(commit=False)
        rule.business = business
        rule.assigned_by = request.user
        try:
            rule.save()
            _ensure_course_assignments_for_rule(rule)
            messages.success(request, 'تم حفظ قاعدة إسناد الدورة')
        except IntegrityError:
            messages.error(request, 'هذه الدورة مسندة بالفعل لهذا المسمى الوظيفي')
    else:
        messages.error(request, form.errors.as_text())
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
            messages.success(request, 'تم حفظ قاعدة إسناد قائمة SOP')
        except IntegrityError:
            messages.error(request, 'هذه القائمة مسندة بالفعل لهذا المسمى الوظيفي')
    else:
        messages.error(request, form.errors.as_text())
    return redirect('business_owner_checklists')


def _employee_dashboard_context(request):
    employee_profile = _get_employee_profile(request.user)
    business = employee_profile.business
    today = timezone.localdate()
    _ensure_employee_courses_are_backed_by_db(business)
    _provision_course_assignments_for_employee(employee_profile)
    course_assignments = CourseAssignment.objects.filter(employee=request.user, business=business).select_related('course').prefetch_related(Prefetch('course__content_items', queryset=CourseContentItem.objects.order_by('order', 'id'))).order_by('status', 'course__title', 'id')
    for assignment in course_assignments:
        _course_card_defaults(assignment.course)
    completed_course_count = sum(1 for assignment in course_assignments if assignment.status == CourseAssignment.Status.COMPLETED)
    assigned_checklists = list(_assigned_checklists_queryset(employee_profile))
    today_completions = {completion.checklist_id: completion for completion in SOPChecklistCompletion.objects.filter(business=business, employee=request.user, completed_for=today).select_related('checklist')}
    recent_checklist_completions = SOPChecklistCompletion.objects.filter(business=business, employee=request.user).select_related('checklist').order_by('-completed_for', '-completed_at')[:10]
    return {'employee_profile': employee_profile, 'business': business, 'course_assignments': course_assignments, 'completed_course_count': completed_course_count, 'assigned_checklists': assigned_checklists, 'today_completions': today_completions, 'recent_checklist_completions': recent_checklist_completions, 'today': today}


@login_required
def employee_dashboard_view(request):
    if not _employee_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/employee-dashboard.html', _employee_dashboard_context(request))


@login_required
def employee_courses_view(request):
    if not _employee_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/employee-courses.html', _employee_dashboard_context(request))


@login_required
def employee_course_view(request, assignment_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    assignment = get_object_or_404(CourseAssignment.objects.filter(employee=request.user, business=employee_profile.business).select_related('course').prefetch_related(Prefetch('course__content_items', queryset=CourseContentItem.objects.order_by('order', 'id'))), id=assignment_id)
    if assignment.status == CourseAssignment.Status.ASSIGNED:
        assignment.status = CourseAssignment.Status.IN_PROGRESS
        assignment.save(update_fields=['status'])
    return render(request, 'accounts-templates/employee-course-view.html', {'employee_profile': employee_profile, 'business': employee_profile.business, 'assignment': assignment, 'course': assignment.course, 'content_items': assignment.course.content_items.all()})


@login_required
def employee_checklists_view(request):
    if not _employee_guard(request):
        return redirect('home')
    return render(request, 'accounts-templates/employee-checklists.html', _employee_dashboard_context(request))


@login_required
@require_POST
def employee_course_complete_action(request, assignment_id: int):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    assignment = get_object_or_404(CourseAssignment.objects.select_related('course'), id=assignment_id, employee=request.user, business=employee_profile.business)
    assignment.status = CourseAssignment.Status.COMPLETED
    assignment.completed_at = timezone.now()
    assignment.save(update_fields=['status', 'completed_at'])
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
    items = list(checklist.items.all())
    selected_item_ids = {int(value) for value in request.POST.getlist('item_ids') if str(value).isdigit()}
    expected_item_ids = {item.id for item in items}
    if expected_item_ids and selected_item_ids != expected_item_ids:
        messages.error(request, 'يجب تحديد جميع عناصر قائمة SOP قبل الإكمال')
        return redirect('employee_checklists')
    completion, created = SOPChecklistCompletion.objects.get_or_create(business=employee_profile.business, checklist=checklist, employee=request.user, completed_for=timezone.localdate(), defaults={'notes': (request.POST.get('notes') or '').strip()})
    if not created:
        completion.notes = (request.POST.get('notes') or '').strip()
        completion.save(update_fields=['notes'])
    for item in items:
        SOPChecklistItemCompletion.objects.update_or_create(completion=completion, item=item, defaults={'is_checked': True})
    messages.success(request, 'تم اكمال المهام اليومية')
    return redirect('employee_checklists')


@login_required
def business_owner_scorm_library_view(request):
    if not _business_owner_guard(request):
        return redirect('home')
    business = _get_owned_business(request.user)
    if request.method == 'POST':
        return _handle_scorm_upload_post(request, 'business_owner_scorm')
    return render(request, 'accounts-templates/business-owner-scorm.html', {'business': business, 'packages': _list_scorm_packages(include_download_url=False)})


@login_required
def employee_scorm_courses_view(request):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    return render(request, 'accounts-templates/employee-scorm-courses.html', {'employee_profile': employee_profile, 'business': employee_profile.business, 'packages': _list_scorm_packages(include_download_url=False)})


@login_required
def employee_scorm_course_view(request, filename: str):
    if not _employee_guard(request):
        return redirect('home')
    employee_profile = _get_employee_profile(request.user)
    selected = _get_scorm_package_or_404(filename, include_download_url=False)
    metadata = _load_scorm_metadata().get(filename)
    if isinstance(metadata, dict) and metadata.get('folder') and metadata.get('launch'):
        selected['player_url'] = reverse('scorm_player_file', kwargs={'folder': str(metadata["folder"]).strip(), 'filepath': str(metadata["launch"]).replace('\\', '/').lstrip('/')})
    else:
        selected['player_url'] = None
    return render(request, 'accounts-templates/employee-scorm-course-view.html', {'employee_profile': employee_profile, 'business': employee_profile.business, 'packages': _list_scorm_packages(include_download_url=False), 'selected': selected})


@login_required
@require_POST
@transaction.atomic
def employee_scorm_check_complete_action(request, filename: str):
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
