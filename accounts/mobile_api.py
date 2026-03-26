import json
from datetime import timedelta

from django.contrib.auth import authenticate
from django.db import IntegrityError, transaction
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST

from training.models import (
    Course,
    CourseAssignment,
    CourseContentItem,
    SOPChecklist,
    SOPChecklistCompletion,
    SOPChecklistItem,
    SOPChecklistItemCompletion,
)

from .forms import CourseForm, SOPChecklistForm
from .models import EmployeeProfile, JobTitle, MobileAuthToken
from .views import (
    AUTO_GRADED_QUESTION_TYPES,
    BusinessOwnerEmployeeCreateForm,
    _accessible_business_courses_queryset,
    _assign_course_to_employee,
    _assigned_checklists_queryset,
    _business_owner_dashboard_context,
    _display_name,
    _employee_dashboard_context,
    _ensure_employee_courses_are_backed_by_db,
    _evaluate_employee_exam_submission,
    _exam_questions_for_assignment,
    _get_employee_profile,
    _get_owned_business,
    _is_business_owner,
    _is_employee,
    _split_full_name,
    _visible_course_content_items,
    _visible_employee_course_assignments_queryset,
)


MOBILE_TOKEN_TTL_DAYS = 30


def _json_error(message: str, *, status: int = 400, code: str = 'bad_request') -> JsonResponse:
    return JsonResponse({'ok': False, 'error': {'code': code, 'message': message}}, status=status)


def _json_success(data: dict | None = None, *, status: int = 200) -> JsonResponse:
    payload = {'ok': True}
    if data:
        payload.update(data)
    return JsonResponse(payload, status=status)


def _load_json_body(request) -> dict:
    if not request.body:
        return {}
    try:
        payload = json.loads(request.body.decode('utf-8'))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return {}
    return payload if isinstance(payload, dict) else {}


def _extract_bearer_token(request) -> str:
    auth_header = (request.headers.get('Authorization') or '').strip()
    if auth_header.lower().startswith('bearer '):
        return auth_header[7:].strip()
    return ''


def _authenticate_mobile_request(request):
    raw_token = _extract_bearer_token(request)
    if not raw_token:
        return None, _json_error('Authentication token is required.', status=401, code='missing_token')
    auth_token = MobileAuthToken.find_active(raw_token)
    if auth_token is None:
        return None, _json_error('Authentication token is invalid or expired.', status=401, code='invalid_token')
    auth_token.touch()
    return auth_token, None


def _serialize_business(business) -> dict | None:
    if business is None:
        return None
    return {
        'id': business.id,
        'name': business.name,
        'slug': business.slug,
        'industry': business.industry,
    }


def _serialize_user(user, *, role: str, business=None, employee_profile=None) -> dict:
    return {
        'id': user.id,
        'username': user.username,
        'display_name': _display_name(user),
        'email': user.email or '',
        'role': role,
        'business': _serialize_business(business),
        'employee_profile': None if employee_profile is None else {
            'id': employee_profile.id,
            'job_title': employee_profile.job_title.name if employee_profile.job_title else '',
        },
    }


def _serialize_course_content_item(item: CourseContentItem) -> dict:
    return {
        'id': item.id,
        'title': item.title,
        'body': item.body,
        'content_type': item.content_type,
        'material_url': item.material_url or '',
        'video_url': item.video_playback_url if item.video_file else '',
        'video_mime_type': item.video_mime_type if item.video_file else '',
        'pdf_url': item.pdf_file.url if item.pdf_file else '',
        'order': item.order,
    }


def _serialize_assignment(assignment: CourseAssignment, *, include_content: bool = False) -> dict:
    course = assignment.course
    content_items = _visible_course_content_items(course.content_items.all()) if include_content else []
    return {
        'id': assignment.id,
        'status': assignment.status,
        'status_label': assignment.get_status_display(),
        'assigned_at': assignment.assigned_at.isoformat(),
        'completed_at': assignment.completed_at.isoformat() if assignment.completed_at else None,
        'course': {
            'id': course.id,
            'title': course.title,
            'description': course.description,
            'estimated_minutes': course.estimated_minutes,
            'has_exam': bool(course.exam_template_id),
            'content_items': [_serialize_course_content_item(item) for item in content_items],
        },
    }


def _serialize_checklist(checklist: SOPChecklist, *, completion=None, include_items: bool = False) -> dict:
    items = list(checklist.items.all()) if include_items else []
    return {
        'id': checklist.id,
        'title': checklist.title,
        'description': checklist.description,
        'frequency': checklist.frequency,
        'is_active': checklist.is_active,
        'completed_today': completion is not None,
        'completion': None if completion is None else {
            'id': completion.id,
            'completed_at': completion.completed_at.isoformat(),
            'completed_for': completion.completed_for.isoformat(),
            'notes': completion.notes or '',
        },
        'items': [
            {
                'id': item.id,
                'title': item.title,
                'order': item.order,
            }
            for item in items
        ],
    }


def _serialize_employee_profile(profile: EmployeeProfile) -> dict:
    return {
        'id': profile.id,
        'username': profile.user.username,
        'display_name': _display_name(profile.user),
        'email': profile.user.email or '',
        'job_title': profile.job_title.name if profile.job_title else '',
        'is_active': profile.is_active and profile.user.is_active,
        'created_at': profile.created_at.isoformat(),
    }


def _serialize_owner_course(course: Course, *, business) -> dict:
    assignment_total = CourseAssignment.objects.filter(business=business, course=course).count()
    visible_content_items = _visible_course_content_items(course.content_items.all())
    return {
        'id': course.id,
        'title': course.title,
        'description': course.description,
        'estimated_minutes': course.estimated_minutes,
        'is_active': course.is_active,
        'assignment_total': assignment_total,
        'has_exam': bool(course.exam_template_id),
        'content_items': [_serialize_course_content_item(item) for item in visible_content_items],
    }


def _role_for_user(user) -> str | None:
    if _is_business_owner(user):
        return 'business_owner'
    if _is_employee(user):
        return 'employee'
    return None


@csrf_exempt
@require_POST
def mobile_login_view(request):
    payload = _load_json_body(request)
    username = (payload.get('username') or '').strip()
    password = payload.get('password') or ''
    device_name = (payload.get('device_name') or 'flutter-mobile').strip() or 'flutter-mobile'
    if not username or not password:
        return _json_error('Username and password are required.')
    user = authenticate(request, username=username, password=password)
    if user is None or not user.is_active:
        return _json_error('Invalid username or password.', status=401, code='invalid_credentials')
    role = _role_for_user(user)
    if role is None:
        return _json_error('This account does not have mobile access.', status=403, code='role_not_supported')
    expires_at = timezone.now() + timedelta(days=MOBILE_TOKEN_TTL_DAYS)
    token, raw_token = MobileAuthToken.issue(user=user, label=device_name, expires_at=expires_at)
    employee_profile = _get_employee_profile(user) if role == 'employee' else None
    business = _get_owned_business(user) if role == 'business_owner' else employee_profile.business
    return _json_success(
        {
            'token': raw_token,
            'token_type': 'Bearer',
            'expires_at': token.expires_at.isoformat() if token.expires_at else None,
            'user': _serialize_user(user, role=role, business=business, employee_profile=employee_profile),
        }
    )


@csrf_exempt
@require_POST
def mobile_logout_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    auth_token.revoke()
    return _json_success({'message': 'Logged out successfully.'})


@require_GET
def mobile_me_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    user = auth_token.user
    role = _role_for_user(user)
    if role is None:
        auth_token.revoke()
        return _json_error('This account no longer has mobile access.', status=403, code='role_not_supported')
    employee_profile = _get_employee_profile(user) if role == 'employee' else None
    business = _get_owned_business(user) if role == 'business_owner' else employee_profile.business
    return _json_success({'user': _serialize_user(user, role=role, business=business, employee_profile=employee_profile)})


@require_GET
def employee_dashboard_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    request.user = auth_token.user
    context = _employee_dashboard_context(request)
    return _json_success(
        {
            'dashboard': {
                'completed_course_count': context['completed_course_count'],
                'active_course_count': len(context['active_course_assignments']),
                'assigned_checklist_count': len(context['assigned_checklists']),
                'course_assignments': [_serialize_assignment(item) for item in context['course_assignments']],
                'dashboard_course_assignments': [_serialize_assignment(item) for item in context['dashboard_course_assignments']],
                'assigned_checklists': [
                    _serialize_checklist(item, completion=context['today_completions'].get(item.id))
                    for item in context['assigned_checklists']
                ],
            }
        }
    )


@require_GET
def employee_courses_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    profile = _get_employee_profile(auth_token.user)
    assignments = list(_visible_employee_course_assignments_queryset(auth_token.user, profile.business))
    return _json_success({'courses': [_serialize_assignment(item) for item in assignments]})


@require_GET
def employee_course_detail_api_view(request, assignment_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    profile = _get_employee_profile(auth_token.user)
    assignment = get_object_or_404(_visible_employee_course_assignments_queryset(auth_token.user, profile.business), id=assignment_id)
    if assignment.status == CourseAssignment.Status.ASSIGNED:
        assignment.status = CourseAssignment.Status.IN_PROGRESS
        assignment.save(update_fields=['status'])
    return _json_success({'course_assignment': _serialize_assignment(assignment, include_content=True)})


@csrf_exempt
@require_POST
def employee_course_complete_api_view(request, assignment_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    profile = _get_employee_profile(auth_token.user)
    assignment = get_object_or_404(_visible_employee_course_assignments_queryset(auth_token.user, profile.business), id=assignment_id)
    if assignment.course.exam_template_id:
        return _json_error('This course must be completed through its exam.', status=409, code='exam_required')
    if assignment.status == CourseAssignment.Status.COMPLETED:
        return _json_error('This course is already completed.', status=409, code='already_completed')
    assignment.status = CourseAssignment.Status.COMPLETED
    assignment.completed_at = timezone.now()
    assignment.save(update_fields=['status', 'completed_at'])
    return _json_success({'course_assignment': _serialize_assignment(assignment)})


def _exam_attempt_session_key(user_id: int, assignment_id: int) -> str:
    return f'mobile-exam-attempt:{user_id}:{assignment_id}'


def _build_exam_attempt_payload(*, assignment: CourseAssignment, exam_questions) -> dict:
    expires_at = timezone.now() + timedelta(minutes=max(assignment.course.exam_template.duration_minutes, 1))
    token_seed = f'{assignment.employee_id}:{assignment.id}:{timezone.now().isoformat()}'
    return {
        'token': MobileAuthToken._hash_token(token_seed)[:32],
        'assignment_id': assignment.id,
        'course_id': assignment.course_id,
        'question_ids': [question.id for question in exam_questions],
        'expires_at': expires_at.isoformat(),
    }


@csrf_exempt
@require_POST
def employee_exam_start_api_view(request, assignment_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    profile = _get_employee_profile(auth_token.user)
    assignment = get_object_or_404(_visible_employee_course_assignments_queryset(auth_token.user, profile.business), id=assignment_id)
    if not assignment.course.exam_template_id:
        return _json_error('This course does not have an exam.', status=404, code='missing_exam')
    exam_questions = _exam_questions_for_assignment(assignment)
    if not exam_questions:
        return _json_error('This course does not have exam questions configured yet.', status=409, code='missing_questions')
    unsupported = [question for question in exam_questions if question.question_type not in AUTO_GRADED_QUESTION_TYPES]
    if unsupported:
        return _json_error('This exam includes question types that require manual grading.', status=409, code='unsupported_exam')
    attempt = _build_exam_attempt_payload(assignment=assignment, exam_questions=exam_questions)
    request.session[_exam_attempt_session_key(auth_token.user.id, assignment.id)] = attempt
    request.session.modified = True
    return _json_success(
        {
            'exam': {
                'attempt_token': attempt['token'],
                'expires_at': attempt['expires_at'],
                'passing_score_percent': assignment.course.exam_template.passing_score_percent,
                'duration_minutes': assignment.course.exam_template.duration_minutes,
                'questions': [
                    {
                        'id': question.id,
                        'order': question.order,
                        'question_text': question.question_text,
                        'question_type': question.question_type,
                        'points': question.points,
                        'is_required': question.is_required,
                        'options': [
                            {
                                'id': option.id,
                                'order': option.order,
                                'text': option.option_text,
                            }
                            for option in question.options.all()
                        ],
                    }
                    for question in exam_questions
                ],
            }
        }
    )


def _build_answer_payload_for_exam_submission(exam_questions, answers: dict):
    normalized_answers = answers if isinstance(answers, dict) else {}

    class AnswerPayload(dict):
        def getlist(self, key):
            value = self.get(key, [])
            if isinstance(value, list):
                return value
            if value in (None, ''):
                return []
            return [value]

    payload = AnswerPayload()
    for question in exam_questions:
        raw_answer = normalized_answers.get(str(question.id), normalized_answers.get(question.id))
        if question.question_type == question.QuestionType.MCQ_MULTI:
            payload[f'question_{question.id}'] = raw_answer if isinstance(raw_answer, list) else []
        elif question.question_type in {question.QuestionType.SHORT_ANSWER, question.QuestionType.ESSAY}:
            payload[f'question_{question.id}_text'] = str(raw_answer or '').strip()
        else:
            payload[f'question_{question.id}'] = '' if raw_answer is None else str(raw_answer).strip()
    return payload


@csrf_exempt
@require_POST
def employee_exam_submit_api_view(request, assignment_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    profile = _get_employee_profile(auth_token.user)
    assignment = get_object_or_404(_visible_employee_course_assignments_queryset(auth_token.user, profile.business), id=assignment_id)
    payload = _load_json_body(request)
    attempt_token = (payload.get('attempt_token') or '').strip()
    attempt = request.session.get(_exam_attempt_session_key(auth_token.user.id, assignment.id))
    if not isinstance(attempt, dict) or attempt.get('token') != attempt_token:
        return _json_error('This exam session has expired.', status=409, code='expired_attempt')
    try:
        expires_at = timezone.datetime.fromisoformat(attempt['expires_at'])
    except (KeyError, ValueError):
        request.session.pop(_exam_attempt_session_key(auth_token.user.id, assignment.id), None)
        request.session.modified = True
        return _json_error('This exam session is invalid.', status=409, code='invalid_attempt')
    if timezone.is_naive(expires_at):
        expires_at = timezone.make_aware(expires_at, timezone.get_current_timezone())
    if expires_at <= timezone.now():
        request.session.pop(_exam_attempt_session_key(auth_token.user.id, assignment.id), None)
        request.session.modified = True
        return _json_error('This exam session has expired.', status=409, code='expired_attempt')

    exam_questions = _exam_questions_for_assignment(assignment)
    answer_payload = _build_answer_payload_for_exam_submission(exam_questions, payload.get('answers') or {})
    evaluation = _evaluate_employee_exam_submission(exam_questions, answer_payload)
    if evaluation['unsupported_questions']:
        return _json_error('This exam includes question types that require manual grading.', status=409, code='unsupported_exam')
    if evaluation['missing_required']:
        return _json_error('Answer all required questions before submitting the exam.', status=400, code='missing_required_answers')

    passing_score = assignment.course.exam_template.passing_score_percent
    passed = evaluation['percent'] >= passing_score
    request.session.pop(_exam_attempt_session_key(auth_token.user.id, assignment.id), None)
    request.session.modified = True
    if passed:
        assignment.status = CourseAssignment.Status.COMPLETED
        assignment.completed_at = timezone.now()
        assignment.save(update_fields=['status', 'completed_at'])
    return _json_success(
        {
            'result': {
                'passed': passed,
                'score_percent': evaluation['percent'],
                'passing_score_percent': passing_score,
                'course_assignment': _serialize_assignment(assignment),
            }
        },
        status=200 if passed else 409,
    )


@require_GET
def employee_checklists_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    profile = _get_employee_profile(auth_token.user)
    checklists = list(_assigned_checklists_queryset(profile))
    completions = {
        completion.checklist_id: completion
        for completion in SOPChecklistCompletion.objects.filter(
            business=profile.business,
            employee=auth_token.user,
            completed_for=timezone.localdate(),
        )
    }
    return _json_success({'checklists': [_serialize_checklist(item, completion=completions.get(item.id)) for item in checklists]})


@require_GET
def employee_checklist_detail_api_view(request, checklist_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    profile = _get_employee_profile(auth_token.user)
    checklist = get_object_or_404(_assigned_checklists_queryset(profile), id=checklist_id)
    completion = SOPChecklistCompletion.objects.filter(
        business=profile.business,
        checklist=checklist,
        employee=auth_token.user,
        completed_for=timezone.localdate(),
    ).first()
    return _json_success({'checklist': _serialize_checklist(checklist, completion=completion, include_items=True)})


@csrf_exempt
@require_POST
@transaction.atomic
def employee_checklist_complete_api_view(request, checklist_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_employee(auth_token.user):
        return _json_error('Employee access is required.', status=403, code='forbidden')
    payload = _load_json_body(request)
    profile = _get_employee_profile(auth_token.user)
    checklist = get_object_or_404(_assigned_checklists_queryset(profile), id=checklist_id)
    item_ids = {int(value) for value in payload.get('item_ids', []) if str(value).isdigit()}
    items = list(checklist.items.all())
    expected_item_ids = {item.id for item in items}
    if expected_item_ids and item_ids != expected_item_ids:
        return _json_error('All checklist items must be checked before completion.', code='missing_items')
    completion, created = SOPChecklistCompletion.objects.get_or_create(
        business=profile.business,
        checklist=checklist,
        employee=auth_token.user,
        completed_for=timezone.localdate(),
        defaults={'notes': (payload.get('notes') or '').strip()},
    )
    if not created:
        completion.notes = (payload.get('notes') or '').strip()
        completion.save(update_fields=['notes'])
    for item in items:
        SOPChecklistItemCompletion.objects.update_or_create(
            completion=completion,
            item=item,
            defaults={'is_checked': True},
        )
    return _json_success({'checklist': _serialize_checklist(checklist, completion=completion, include_items=True)})


@require_GET
def owner_dashboard_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    request.user = auth_token.user
    context = _business_owner_dashboard_context(request)
    return _json_success(
        {
            'dashboard': {
                'business': _serialize_business(context['business']),
                'employee_total': len(context['employees']),
                'course_total': len(context['courses']),
                'checklist_total': len(context['checklists']),
                'employees': [_serialize_employee_profile(item) for item in context['employees']],
                'assignable_courses': [
                    {
                        'id': course.id,
                        'title': course.title,
                        'business_name': course.business.name if course.business else '',
                    }
                    for course in context['assignable_courses']
                ],
            }
        }
    )


@require_GET
def owner_employees_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    employees = list(
        EmployeeProfile.objects.select_related('user', 'job_title')
        .filter(business=business, is_active=True, user__is_active=True)
        .order_by('user__first_name', 'user__last_name', 'user__username', 'id')
    )
    return _json_success({'employees': [_serialize_employee_profile(item) for item in employees]})


@csrf_exempt
@require_POST
@transaction.atomic
def owner_employee_create_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    payload = _load_json_body(request)
    form = BusinessOwnerEmployeeCreateForm(payload, business=business)
    if not form.is_valid():
        return _json_error(form.errors.as_json(), code='validation_error')
    username = form.cleaned_data['username']
    if EmployeeProfile.objects.filter(user__username=username).exists():
        return _json_error('Username is already in use.', code='validation_error')
    job_title_name = form.cleaned_data['job_title']
    job_title = JobTitle.objects.filter(business=business, name__iexact=job_title_name).order_by('id').first()
    if job_title is None:
        try:
            job_title = JobTitle.objects.create(business=business, name=job_title_name)
        except IntegrityError:
            job_title = JobTitle.objects.filter(business=business, name__iexact=job_title_name).order_by('id').first()
    first_name, last_name = _split_full_name(form.cleaned_data['full_name'])
    user = auth_token.user.__class__.objects.create_user(
        username=username,
        password=form.cleaned_data['password'],
        email=(form.cleaned_data.get('email') or '').strip(),
        first_name=first_name,
        last_name=last_name,
    )
    profile = EmployeeProfile.objects.create(
        user=user,
        business=business,
        job_title=job_title,
        created_by=auth_token.user,
    )
    return _json_success({'employee': _serialize_employee_profile(profile)}, status=201)


@require_GET
def owner_courses_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    _ensure_employee_courses_are_backed_by_db(business)
    courses = list(
        _accessible_business_courses_queryset(business)
        .select_related('business')
        .prefetch_related('content_items')
        .filter(is_active=True)
        .order_by('title', 'id')
    )
    return _json_success({'courses': [_serialize_owner_course(item, business=business) for item in courses]})


@csrf_exempt
@require_POST
@transaction.atomic
def owner_course_create_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    payload = _load_json_body(request)
    form = CourseForm(payload)
    if not form.is_valid():
        return _json_error(form.errors.as_json(), code='validation_error')
    course = form.save(commit=False)
    course.business = business
    course.created_by = auth_token.user
    course.save()
    for index, raw_item in enumerate(payload.get('content_items', []), start=1):
        if not isinstance(raw_item, dict):
            continue
        if not any(
            (
                (raw_item.get('title') or '').strip(),
                (raw_item.get('body') or '').strip(),
                (raw_item.get('material_url') or '').strip(),
            )
        ):
            continue
        CourseContentItem.objects.create(
            course=course,
            content_type=(raw_item.get('content_type') or CourseContentItem.ContentType.TEXT).strip(),
            title=(raw_item.get('title') or course.title).strip() or course.title,
            body=(raw_item.get('body') or '').strip(),
            material_url=(raw_item.get('material_url') or '').strip(),
            order=int(raw_item.get('order') or index),
        )
    return _json_success({'course': _serialize_owner_course(course, business=business)}, status=201)


@require_GET
def owner_course_detail_api_view(request, course_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    course = get_object_or_404(
        _accessible_business_courses_queryset(business).prefetch_related('content_items'),
        id=course_id,
    )
    return _json_success({'course': _serialize_owner_course(course, business=business)})


@csrf_exempt
@require_POST
@transaction.atomic
def owner_assign_course_api_view(request, course_id: int):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    payload = _load_json_body(request)
    course = get_object_or_404(_accessible_business_courses_queryset(business).filter(is_active=True), id=course_id)
    employee_ids = {int(value) for value in payload.get('employee_ids', []) if str(value).isdigit()}
    if not employee_ids:
        return _json_error('At least one employee must be selected.')
    employees = list(
        EmployeeProfile.objects.select_related('user', 'job_title')
        .filter(id__in=employee_ids, business=business, is_active=True, user__is_active=True)
    )
    if not employees:
        return _json_error('No valid employees were selected.', status=404, code='employees_not_found')
    created_count = 0
    duplicate_count = 0
    for employee in employees:
        created, _error = _assign_course_to_employee(
            business=business,
            course=course,
            employee_profile=employee,
            assigned_by=auth_token.user,
        )
        if created:
            created_count += 1
        else:
            duplicate_count += 1
    return _json_success(
        {
            'assignment_summary': {
                'created_count': created_count,
                'duplicate_count': duplicate_count,
            }
        }
    )


@require_GET
def owner_reports_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    request.user = auth_token.user
    context = _business_owner_dashboard_context(request)
    business = context['business']
    assignments = list(
        CourseAssignment.objects.filter(
            business=business,
            employee__employee_profile__business=business,
            employee__employee_profile__is_active=True,
            employee__is_active=True,
        ).select_related('course', 'employee__employee_profile__job_title')
    )
    total_assigned = len(assignments)
    total_completed = sum(1 for item in assignments if item.status == CourseAssignment.Status.COMPLETED)
    total_in_progress = sum(1 for item in assignments if item.status == CourseAssignment.Status.IN_PROGRESS)
    return _json_success(
        {
            'report': {
                'tracked_employee_total': len(context['employees']),
                'total_assigned': total_assigned,
                'total_completed': total_completed,
                'total_in_progress': total_in_progress,
                'overall_completion_rate': round((total_completed / total_assigned) * 100) if total_assigned else 0,
            }
        }
    )


@require_GET
def owner_checklists_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    checklists = list(business.sop_checklists.prefetch_related('items').order_by('title', 'id'))
    return _json_success(
        {
            'checklists': [
                {
                    'id': checklist.id,
                    'title': checklist.title,
                    'description': checklist.description,
                    'frequency': checklist.frequency,
                    'is_active': checklist.is_active,
                    'items': [
                        {
                            'id': item.id,
                            'title': item.title,
                            'order': item.order,
                        }
                        for item in checklist.items.all()
                    ],
                }
                for checklist in checklists
            ]
        }
    )


@csrf_exempt
@require_POST
@transaction.atomic
def owner_checklist_create_api_view(request):
    auth_token, error_response = _authenticate_mobile_request(request)
    if error_response:
        return error_response
    if not _is_business_owner(auth_token.user):
        return _json_error('Business owner access is required.', status=403, code='forbidden')
    business = _get_owned_business(auth_token.user)
    payload = _load_json_body(request)
    form_payload = {
        'title': payload.get('title'),
        'description': payload.get('description'),
        'frequency': payload.get('frequency'),
        'is_active': payload.get('is_active', True),
        'item_lines': '\n'.join(str(item).strip() for item in payload.get('items', []) if str(item).strip()),
    }
    form = SOPChecklistForm(form_payload)
    if not form.is_valid():
        return _json_error(form.errors.as_json(), code='validation_error')
    checklist = form.save(commit=False)
    checklist.business = business
    checklist.created_by = auth_token.user
    checklist.save()
    created_items = []
    for index, item_title in enumerate(form.cleaned_data['item_lines'], start=1):
        created_items.append(SOPChecklistItem.objects.create(checklist=checklist, title=item_title, order=index))
    return _json_success(
        {
            'checklist': {
                'id': checklist.id,
                'title': checklist.title,
                'description': checklist.description,
                'frequency': checklist.frequency,
                'is_active': checklist.is_active,
                'items': [{'id': item.id, 'title': item.title, 'order': item.order} for item in created_items],
            }
        },
        status=201,
    )
