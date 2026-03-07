from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.db import IntegrityError
from django.db.models import Q
import re

from django.utils import timezone
from django.views.decorators.http import require_POST

from .models import Program, EnrollmentRequest
from .program_catalog import PROGRAM_HIERARCHY
from accounts.models import ContractorProfile, ContractorDocument
from certification.models import Certificate

@login_required
def training_program_categories_view(request):
    is_coordinator = ContractorProfile.objects.filter(
        user=request.user,
        is_training_coordinator=True,
    ).exists()

    is_contractor = ContractorProfile.objects.filter(
        user=request.user,
        is_training_coordinator=False,
    ).exists()

    categories = [
        {
            'code': Program.ProgramType.COURSE_ATTENDANCE,
            'label': 'الدورات',
        },
        {
            'code': Program.ProgramType.TECHNICAL_EXAM,
            'label': 'اختبارات التأهيل الفني',
        },
        {
            'code': Program.ProgramType.SOLAR_POWER_EXAM,
            'label': 'اختبارات الطاقة الشمسية',
        },
    ]

    return render(
        request,
        'training-templates/program_categories.html',
        {
            'categories': categories,
            'is_training_coordinator': is_coordinator,
            'is_contractor': is_contractor,
        }
    )


@login_required
def training_programs_list_view(request):
    """
    عرض قائمة البرامج التدريبية النشطة
    مع ربط تسجيل المستخدم (إن وجد) بكل برنامج
    """

    allowed_categories = {
        Program.ProgramType.COURSE_ATTENDANCE,
        Program.ProgramType.TECHNICAL_EXAM,
        Program.ProgramType.SOLAR_POWER_EXAM,
    }
    selected_category = (request.GET.get('category') or '').strip()
    selected_subcategory = (request.GET.get('subcategory') or '').strip()
    selected_tertiary = (request.GET.get('tertiary') or '').strip()
    search_query = (request.GET.get('q') or '').strip()

    programs = Program.objects.filter(is_active=True)
    if selected_category in allowed_categories:
        programs = programs.filter(program_type=selected_category)
    else:
        selected_subcategory = ''
        selected_tertiary = ''

    subcategories = PROGRAM_HIERARCHY.get(selected_category, [])
    selected_subcategory_obj = None
    tertiary_levels = []
    selected_tertiary_obj = None
    if subcategories:
        selected_subcategory_obj = next(
            (item for item in subcategories if item['code'] == selected_subcategory),
            None
        )
        if selected_subcategory and selected_subcategory_obj is None:
            programs = programs.none()
        elif selected_subcategory_obj:
            tertiary_levels = selected_subcategory_obj.get('tertiary_levels') or []

            def _programs_match_query(program_rows):
                q = Q()
                for row in program_rows:
                    for value in (row.get('en', ''), row.get('ar', '')):
                        name = (value or '').strip()
                        if not name:
                            continue
                        q |= (
                            Q(title__iexact=name)
                            | Q(title_ar__iexact=name)
                            | Q(title_en__iexact=name)
                            | Q(title__icontains=name)
                            | Q(title_ar__icontains=name)
                                | Q(title_en__icontains=name)
                        )
                return q

            def _tertiary_label_match_query(level):
                q = Q()
                raw_values = [
                    level.get('label_en', ''),
                    level.get('label_ar', ''),
                    level.get('code', ''),
                ]
                tokens = set()
                for value in raw_values:
                    text = (value or '').strip()
                    if not text:
                        continue
                    tokens.add(text)
                    tokens.add(text.replace('-', ' '))
                    tokens.add(text.replace('_', ' '))
                expanded_tokens = set(tokens)
                for token in list(tokens):
                    compact = re.sub(r'\s+', ' ', token.lower()).strip()
                    m = re.match(r'^(\d+(?:\.\d+)?)\s*kv$', compact)
                    if m:
                        expanded_tokens.add(f"KV {m.group(1)}")
                    m = re.match(r'^kv\s*(\d+(?:\.\d+)?)$', compact)
                    if m:
                        expanded_tokens.add(f"{m.group(1)} KV")
                for token in expanded_tokens:
                    token = token.strip()
                    if not token:
                        continue
                    q |= (
                        Q(title__icontains=token)
                        | Q(title_ar__icontains=token)
                        | Q(title_en__icontains=token)
                    )
                return q

            if tertiary_levels:
                selected_tertiary_obj = next(
                    (item for item in tertiary_levels if item.get('code') == selected_tertiary),
                    None
                )
                if selected_tertiary and selected_tertiary_obj is None:
                    programs = programs.none()
                elif selected_tertiary_obj:
                    match_query = _programs_match_query(selected_tertiary_obj.get('programs', []))
                    match_query |= _tertiary_label_match_query(selected_tertiary_obj)
                    programs = programs.filter(
                        Q(program_subcategory=selected_subcategory) & match_query
                    ) if match_query else programs.none()
                else:
                    programs = programs.none()
            else:
                match_query = _programs_match_query(selected_subcategory_obj.get('programs', []))
                # Prefer explicit subcategory assignment, but keep legacy title matching.
                programs = programs.filter(
                    Q(program_subcategory=selected_subcategory) | match_query
                ) if match_query else programs.filter(program_subcategory=selected_subcategory)
        else:
            programs = programs.none()

    if search_query:
        programs = programs.filter(
            Q(title__icontains=search_query)
            | Q(title_ar__icontains=search_query)
            | Q(title_en__icontains=search_query)
            | Q(description__icontains=search_query)
        )

    is_coordinator = ContractorProfile.objects.filter(
        user=request.user,
        is_training_coordinator=True,
    ).exists()

    is_contractor = ContractorProfile.objects.filter(
        user=request.user,
        is_training_coordinator=False,
    ).exists()

    # جلب جميع تسجيلات المستخدم مرة واحدة (تحسين أداء)
    # مع السماح بوجود أكثر من طلب لنفس البرنامج عبر الزمن.
    user_enrollments = EnrollmentRequest.objects.none()
    active_enrollment_map = {}
    rejected_enrollment_map = {}
    if is_contractor:
        user_enrollments = (
            EnrollmentRequest.objects
            .filter(contractor=request.user)
            .select_related('program')
            .order_by('-created_at', '-id')
        )

        # Keep latest active request per program for button locking.
        # Rejected requests should not block re-apply, but we still expose the latest
        # rejection reason separately for user guidance.
        for enrollment in user_enrollments:
            if (
                enrollment.status == EnrollmentRequest.Status.REJECTED
                and enrollment.program_id not in rejected_enrollment_map
            ):
                rejected_enrollment_map[enrollment.program_id] = enrollment
                continue

            if (
                enrollment.status != EnrollmentRequest.Status.REJECTED
                and enrollment.program_id not in active_enrollment_map
            ):
                active_enrollment_map[enrollment.program_id] = enrollment

    for program in programs:
        program.user_enrollment = active_enrollment_map.get(program.id)
        program.latest_rejected_enrollment = rejected_enrollment_map.get(program.id)

    contractor_documents = []
    if is_contractor:
        contractor_documents = list(
            ContractorDocument.objects
            .filter(owner=request.user)
            .order_by('-uploaded_at', '-id')
        )

    return render(
        request,
        'training-templates/programs_list.html',
        {
            'programs': programs,
            'contractor_documents': contractor_documents,
            'is_training_coordinator': is_coordinator,
            'is_contractor': is_contractor,
            'selected_category': selected_category,
            'selected_subcategory': selected_subcategory,
            'selected_subcategory_obj': selected_subcategory_obj,
            'selected_tertiary': selected_tertiary,
            'selected_tertiary_obj': selected_tertiary_obj,
            'tertiary_levels': tertiary_levels,
            'subcategories': subcategories,
            'search_query': search_query,
        }
    )


@login_required
def create_registration(request, program_id):
    """
    زر التسجيل = نقطة بداية Workflow
    """

    # Only contractors can create enrollments for themselves.
    if not ContractorProfile.objects.filter(user=request.user, is_training_coordinator=False).exists():
        messages.error(request, 'غير مصرح لك بالتسجيل في البرامج')
        return redirect('training:programs_list')

    if request.method != 'POST':
        messages.info(request, 'اختر المرفقات المطلوبة ثم تابع التسجيل')
        return redirect('training:programs_list')

    program = get_object_or_404(
        Program,
        id=program_id,
        is_active=True
    )

    document_ids = request.POST.getlist('document_ids')
    if not document_ids:
        messages.error(request, 'اختر ملفات PDF المطلوبة قبل متابعة التسجيل')
        return redirect('training:programs_list')

    documents = ContractorDocument.objects.filter(
        owner=request.user,
        id__in=document_ids,
    )

    if not documents.exists():
        messages.error(request, 'لم يتم العثور على ملفات PDF صالحة')
        return redirect('training:programs_list')

    try:
        terminal_statuses = {
            EnrollmentRequest.Status.REJECTED,
            EnrollmentRequest.Status.FAILED,
            EnrollmentRequest.Status.CERTIFIED,
            EnrollmentRequest.Status.COMPLETED_WITH_PASS_CARD,
        }

        active_existing = (
            EnrollmentRequest.objects
            .filter(contractor=request.user, program=program)
            .exclude(status__in=terminal_statuses)
            .order_by('-created_at', '-id')
            .first()
        )

        if active_existing is not None:
            messages.info(
                request,
                f'لديك طلب تسجيل قائم بالفعل. الحالة الحالية: {active_existing.get_status_display()}'
            )
            return redirect('training:programs_list')

        latest_cert = (
            Certificate.objects
            .filter(owner=request.user, program=program)
            .order_by('-issued_at', '-id')
            .first()
        )

        request_type = EnrollmentRequest.RequestType.INITIAL
        source_certificate = None
        if latest_cert is not None:
            # Ensure expires_at is present for legacy rows.
            try:
                latest_cert.ensure_expires_at()
                if latest_cert.expires_at:
                    latest_cert.save(update_fields=['expires_at'])
            except Exception:
                pass

            if latest_cert.expires_at:
                now = timezone.now()
                renewal_months = 6
                try:
                    renewal_months = int(getattr(program, 'renewal_window_months', 6) or 6)
                except Exception:
                    renewal_months = 6
                if now >= latest_cert.expires_at:
                    # Expired: renewal window missed -> user must re-enroll.
                    request_type = EnrollmentRequest.RequestType.INITIAL
                else:
                    renewal_start = getattr(latest_cert, 'renewal_window_starts_at', None)
                    if renewal_start and renewal_start <= now < latest_cert.expires_at:
                        request_type = EnrollmentRequest.RequestType.RENEWAL
                        source_certificate = latest_cert
                    else:
                        messages.info(
                            request,
                            (
                                f'الشهادة ما زالت سارية حتى {latest_cert.expires_at.date()}. '
                                f'يمكنك التقديم للتجديد خلال آخر {renewal_months} شهر '
                                f'بدءاً من {renewal_start.date() if renewal_start else "—"}.'
                            )
                        )
                        return redirect('training:programs_list')

        enrollment = EnrollmentRequest.objects.create(
            contractor=request.user,
            program=program,
            request_type=request_type,
            source_certificate=source_certificate,
        )
        created = True
    except IntegrityError:
        messages.error(request, 'حدث خطأ أثناء إنشاء الطلب')
        return redirect('training:programs_list')

    if created:
        # 🔴 الحل هنا
        enrollment.start_workflow()
        enrollment.save(update_fields=['status'])

        try:
            enrollment.supporting_documents.set(documents)
            enrollment.snapshot_supporting_documents(documents)
        except Exception:
            pass

        messages.success(
            request,
            f'تم بدء إجراءات التسجيل بنجاح. الحالة الحالية: {enrollment.get_status_display()}'
        )

    return redirect('training:programs_list')


@login_required
@require_POST
def apply_renewal(request, certificate_id: int):
    # Only contractors can renew for themselves.
    if not ContractorProfile.objects.filter(user=request.user, is_training_coordinator=False).exists():
        messages.error(request, 'غير مصرح لك بالتجديد')
        return redirect('contractor_renewals')

    cert = get_object_or_404(Certificate, id=certificate_id, owner=request.user)

    try:
        cert.ensure_expires_at()
        if cert.expires_at and not Certificate.objects.filter(id=cert.id, expires_at=cert.expires_at).exists():
            cert.save(update_fields=['expires_at'])
    except Exception:
        pass

    if not cert.expires_at:
        messages.error(request, 'تعذر تحديد تاريخ انتهاء الشهادة')
        return redirect('contractor_renewals')

    now = timezone.now()
    if now >= cert.expires_at:
        messages.error(
            request,
            'الشهادة منتهية. يجب التسجيل والالتحاق بالبرنامج مجددًا وإكمال إجراءات الاعتماد للحصول على شهادة جديدة.'
        )
        return redirect('contractor_renewals')

    renewal_start = cert.renewal_window_starts_at
    if not renewal_start or now < renewal_start:
        renewal_months = 6
        try:
            renewal_months = int(getattr(getattr(cert, 'program', None), 'renewal_window_months', 6) or 6)
        except Exception:
            renewal_months = 6
        messages.info(
            request,
            f'التجديد متاح فقط خلال آخر {renewal_months} شهر قبل الانتهاء. '
            f'متاح بدءاً من: {renewal_start.date() if renewal_start else "—"}'
        )
        return redirect('contractor_renewals')

    terminal_statuses = {
        EnrollmentRequest.Status.REJECTED,
        EnrollmentRequest.Status.FAILED,
        EnrollmentRequest.Status.CERTIFIED,
        EnrollmentRequest.Status.COMPLETED_WITH_PASS_CARD,
    }
    existing = (
        EnrollmentRequest.objects
        .filter(contractor=request.user, program=cert.program, request_type=EnrollmentRequest.RequestType.RENEWAL)
        .exclude(status__in=terminal_statuses)
        .order_by('-created_at', '-id')
        .first()
    )
    if existing is not None:
        messages.info(request, f'لديك طلب تجديد قائم بالفعل. الحالة الحالية: {existing.get_status_display()}')
        return redirect('contractor_renewals')

    enrollment = EnrollmentRequest.objects.create(
        contractor=request.user,
        program=cert.program,
        request_type=EnrollmentRequest.RequestType.RENEWAL,
        source_certificate=cert,
    )
    enrollment.start_workflow()
    enrollment.save(update_fields=['status'])

    # Best effort: reuse documents from the original enrollment if present.
    try:
        if getattr(cert, 'enrollment', None) is not None:
            docs = cert.enrollment.supporting_documents.all()
            if docs.exists():
                enrollment.supporting_documents.set(docs)
                enrollment.snapshot_supporting_documents(docs)
    except Exception:
        pass

    messages.success(request, f'تم إنشاء طلب تجديد بنجاح. الحالة الحالية: {enrollment.get_status_display()}')
    return redirect('contractor_renewals')
