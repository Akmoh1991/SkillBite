from django.urls import path
from .views import (
    home_view,
    register_view,
    login_view,
    logout_view,
    business_owner_dashboard_view,
    business_owner_employees_view,
    business_owner_courses_view,
    business_owner_checklists_view,
    business_owner_job_title_create_action,
    business_owner_employee_create_action,
    business_owner_course_create_action,
    business_owner_course_assignment_rule_create_action,
    business_owner_checklist_create_action,
    business_owner_checklist_assignment_rule_create_action,
    employee_dashboard_view,
    employee_course_complete_action,
    employee_checklist_complete_action,

    # Super Admin
    super_admin_dashboard_view,
    super_admin_scorm_upload_view,
    super_admin_programs_list_view,
    super_admin_program_create_view,
    super_admin_program_edit_view,
    super_admin_program_delete_action,
    super_admin_program_grading_config_view,
    super_admin_users_list_view,
    super_admin_set_user_role_action,
    super_admin_grant_trainer_role_action,
    super_admin_remove_trainer_role_action,
    super_admin_grant_training_coordinator_role_action,
    super_admin_remove_training_coordinator_role_action,
    super_admin_enroll_user_view,

    # Dashboards
    contractor_dashboard_view,
    contractor_document_upload_action,
    contractor_document_delete_action,
    trainer_dashboard_view,

    # Trainer – Reports
    trainer_reports_view,
    trainer_reports_export_csv,
    trainer_registered_trainees_view,

    # Contractor – My Requests
    contractor_requests_list_view,
    contractor_renewals_list_view,
    contractor_confirm_payment_action,
    contractor_book_exam_action,
    contractor_exam_sessions_view,

    # ✅ Contractor Exam Page
    contractor_exam_view,

    # Trainer – Review Requests
    trainer_requests_list_view,
    trainer_renewal_requests_list_view,
    trainer_exam_grading_view,
    trainer_review_request_action,
    trainer_confirm_payment_action,
    trainer_external_assessment_submit_action,

    # Trainer – Schedule Exam
    trainer_exam_sessions_view,
    trainer_schedule_exam_action,

    # Request Details
    enrollment_request_detail_view,

    # ✅ Trainer – Exam Templates (Create/Manage Questions + Excel Upload)
    trainer_exam_templates_list_view,
    trainer_exam_excel_template_download_view,
    trainer_exam_template_create_view,
    trainer_exam_template_editor_view,
    trainer_exam_question_delete_view,

    # ✅✅✅ NEW: Edit Question + Options
    trainer_exam_question_edit_view,

    # SCORM
    trainer_scorm_upload_view,
    contractor_scorm_courses_view,
    contractor_scorm_course_view,
    contractor_scorm_check_complete_action,
    scorm_player_file_view,
    scorm_player_file_redirect_view,

    # Training Coordinator
    training_coordinator_dashboard_view,
    training_coordinator_contractors_list_view,
    training_coordinator_register_existing_contractor_action,
    training_coordinator_register_contractor_view,
    training_coordinator_requests_list_view,
    training_coordinator_contractor_documents_view,
    training_coordinator_contractor_document_upload_action,
    training_coordinator_contractor_document_delete_action,
)

from .views import contractor_exam_submit_action

urlpatterns = [

    # =========================
    # Home
    # =========================
    path('', home_view, name='home'),

    # =========================
    # Authentication
    # =========================
    path('register/', register_view, name='register'),
    path('login/', login_view, name='login'),
    path('logout/', logout_view, name='logout'),
    path('business-owner/dashboard/', business_owner_dashboard_view, name='business_owner_dashboard'),
    path('business-owner/employees/', business_owner_employees_view, name='business_owner_employees'),
    path('business-owner/courses/', business_owner_courses_view, name='business_owner_courses'),
    path('business-owner/checklists/', business_owner_checklists_view, name='business_owner_checklists'),
    path('business-owner/job-titles/create/', business_owner_job_title_create_action, name='business_owner_job_title_create'),
    path('business-owner/employees/create/', business_owner_employee_create_action, name='business_owner_employee_create'),
    path('business-owner/courses/create/', business_owner_course_create_action, name='business_owner_course_create'),
    path('business-owner/course-rules/create/', business_owner_course_assignment_rule_create_action, name='business_owner_course_rule_create'),
    path('business-owner/checklists/create/', business_owner_checklist_create_action, name='business_owner_checklist_create'),
    path('business-owner/checklist-rules/create/', business_owner_checklist_assignment_rule_create_action, name='business_owner_checklist_rule_create'),
    path('employee/dashboard/', employee_dashboard_view, name='employee_dashboard'),
    path('employee/courses/<int:assignment_id>/complete/', employee_course_complete_action, name='employee_course_complete'),
    path('employee/checklists/<int:checklist_id>/complete/', employee_checklist_complete_action, name='employee_checklist_complete'),

    # =========================
    # Dashboards
    # =========================
    path('super-admin/dashboard/', super_admin_dashboard_view, name='super_admin_dashboard'),
    path('super-admin/scorm/upload/', super_admin_scorm_upload_view, name='super_admin_scorm_upload'),
    path('super-admin/programs/', super_admin_programs_list_view, name='super_admin_programs'),
    path('super-admin/programs/create/', super_admin_program_create_view, name='super_admin_program_create'),
    path('super-admin/programs/<int:program_id>/edit/', super_admin_program_edit_view, name='super_admin_program_edit'),
    path('super-admin/programs/<int:program_id>/delete/', super_admin_program_delete_action, name='super_admin_program_delete'),
    path(
        'super-admin/programs/<int:program_id>/grading/',
        super_admin_program_grading_config_view,
        name='super_admin_program_grading_config'
    ),
    path('super-admin/users/', super_admin_users_list_view, name='super_admin_users'),
    path('super-admin/users/<int:user_id>/role/set/', super_admin_set_user_role_action, name='super_admin_set_user_role'),
    path('super-admin/users/<int:user_id>/trainer/grant/', super_admin_grant_trainer_role_action, name='super_admin_grant_trainer_role'),
    path('super-admin/users/<int:user_id>/trainer/remove/', super_admin_remove_trainer_role_action, name='super_admin_remove_trainer_role'),
    path('super-admin/users/<int:user_id>/coordinator/grant/', super_admin_grant_training_coordinator_role_action, name='super_admin_grant_training_coordinator_role'),
    path('super-admin/users/<int:user_id>/coordinator/remove/', super_admin_remove_training_coordinator_role_action, name='super_admin_remove_training_coordinator_role'),
    path('super-admin/enroll/', super_admin_enroll_user_view, name='super_admin_enroll_user'),
    path('contractor/dashboard/', contractor_dashboard_view, name='contractor_dashboard'),
    path('contractor/documents/upload/', contractor_document_upload_action, name='contractor_document_upload_action'),
    path('contractor/documents/<int:doc_id>/delete/', contractor_document_delete_action, name='contractor_document_delete_action'),
    path('trainer/dashboard/', trainer_dashboard_view, name='trainer_dashboard'),

    # =========================
    # Training Coordinator
    # =========================
    path('training-coordinator/dashboard/', training_coordinator_dashboard_view, name='training_coordinator_dashboard'),
    path('training-coordinator/contractors/', training_coordinator_contractors_list_view, name='training_coordinator_contractors_list'),
    path('training-coordinator/contractors/<int:contractor_user_id>/register-existing/', training_coordinator_register_existing_contractor_action, name='training_coordinator_register_existing_contractor_action'),
    path('training-coordinator/contractors/register/', training_coordinator_register_contractor_view, name='training_coordinator_register_contractor'),
    path('training-coordinator/requests/', training_coordinator_requests_list_view, name='training_coordinator_requests'),
    path('training-coordinator/requests/<int:request_id>/', enrollment_request_detail_view, name='training_coordinator_request_detail'),
    path('training-coordinator/contractors/<int:contractor_user_id>/documents/', training_coordinator_contractor_documents_view, name='training_coordinator_contractor_documents'),
    path('training-coordinator/contractors/<int:contractor_user_id>/documents/upload/', training_coordinator_contractor_document_upload_action, name='training_coordinator_contractor_document_upload_action'),
    path('training-coordinator/contractors/<int:contractor_user_id>/documents/<int:doc_id>/delete/', training_coordinator_contractor_document_delete_action, name='training_coordinator_contractor_document_delete_action'),

    # =========================
    # Trainer – Reports
    # =========================
    path('trainer/reports/', trainer_reports_view, name='trainer_reports'),
    path('trainer/reports/export.csv', trainer_reports_export_csv, name='trainer_reports_export_csv'),

    # =========================
    # Trainer – Registered Trainees
    # =========================
    path('trainer/trainees/', trainer_registered_trainees_view, name='trainer_registered_trainees'),

    # =========================
    # Contractor – My Training Requests
    # =========================
    path('contractor/requests/', contractor_requests_list_view, name='contractor_requests'),
    path('contractor/renewals/', contractor_renewals_list_view, name='contractor_renewals'),

    # تفاصيل الطلب (مقاول)
    path(
        'contractor/requests/<int:request_id>/',
        enrollment_request_detail_view,
        name='contractor_request_detail'
    ),

    # ✅ صفحة الاختبار للمقاول
    path(
        'contractor/requests/<int:request_id>/exam/',
        contractor_exam_view,
        name='contractor_exam_view'
    ),

    # Confirm Payment (Contractor)
    path(
        'contractor/requests/<int:request_id>/confirm-payment/',
        contractor_confirm_payment_action,
        name='contractor_confirm_payment_action'
    ),

    # Book Exam (Contractor)
    path(
        'contractor/requests/<int:request_id>/book-exam/',
        contractor_book_exam_action,
        name='contractor_book_exam_action'
    ),
    path(
        'contractor/requests/<int:request_id>/exam-sessions/',
        contractor_exam_sessions_view,
        name='contractor_exam_sessions_view'
    ),

    # =========================
    # Trainer – Review Training Requests
    # =========================
    path('trainer/requests/', trainer_requests_list_view, name='trainer_requests'),
    path('trainer/renewal-requests/', trainer_renewal_requests_list_view, name='trainer_renewal_requests'),
    path('trainer/exam-grading/', trainer_exam_grading_view, name='trainer_exam_grading_view'),

    # تفاصيل الطلب (مدرب)
    path(
        'trainer/requests/<int:request_id>/',
        enrollment_request_detail_view,
        name='trainer_request_detail'
    ),

    # approve/reject
    path(
        'trainer/requests/<int:request_id>/action/',
        trainer_review_request_action,
        name='trainer_request_action'
    ),

    # Confirm Payment (Trainer)
    path(
        'trainer/requests/<int:request_id>/confirm-payment/',
        trainer_confirm_payment_action,
        name='trainer_confirm_payment_action'
    ),

    # External part assessment (Practical/Project)
    path(
        'trainer/requests/<int:request_id>/external-assessment/',
        trainer_external_assessment_submit_action,
        name='trainer_external_assessment_submit_action'
    ),

    # Schedule Exam
    path(
        'trainer/requests/<int:request_id>/schedule-exam/',
        trainer_schedule_exam_action,
        name='trainer_schedule_exam_action'
    ),
    path(
        'trainer/exam-sessions/',
        trainer_exam_sessions_view,
        name='trainer_exam_sessions_view'
    ),

    # =========================
    # Trainer – Exam Templates
    # =========================
    path('trainer/exam-templates/', trainer_exam_templates_list_view, name='trainer_exam_templates'),
    path(
        'trainer/exam-templates/excel-template/',
        trainer_exam_excel_template_download_view,
        name='trainer_exam_excel_template_download'
    ),
    path('trainer/exam-templates/create/', trainer_exam_template_create_view, name='trainer_exam_template_create'),

    # لو أحد دخل "editor" بدون id
    path(
        'trainer/exam-templates/editor/',
        trainer_exam_template_create_view,
        name='trainer_exam_template_editor_create_redirect'
    ),

    # مسار واضح /editor/ مع id
    path(
        'trainer/exam-templates/<int:template_id>/editor/',
        trainer_exam_template_editor_view,
        name='trainer_exam_template_editor_v2'
    ),

    # المسار الأساسي الحالي
    path(
        'trainer/exam-templates/<int:template_id>/',
        trainer_exam_template_editor_view,
        name='trainer_exam_template_editor'
    ),

    # ✅✅✅ NEW: edit question + options (هذا هو المسار اللي كان ناقص)
    path(
        'trainer/exam-templates/<int:template_id>/questions/<int:question_id>/edit/',
        trainer_exam_question_edit_view,
        name='trainer_exam_question_edit'
    ),

    # delete question
    path(
        'trainer/exam-templates/<int:template_id>/questions/<int:question_id>/delete/',
        trainer_exam_question_delete_view,
        name='trainer_exam_question_delete'
    ),
    path(
    'contractor/requests/<int:request_id>/exam/submit/',
    contractor_exam_submit_action,
    name='contractor_exam_submit_action'
),

    # =========================
    # SCORM
    # =========================
    path('trainer/scorm/upload/', trainer_scorm_upload_view, name='trainer_scorm_upload'),
    path('contractor/scorm/', contractor_scorm_courses_view, name='contractor_scorm_courses'),
    path('contractor/scorm/<str:filename>/', contractor_scorm_course_view, name='contractor_scorm_course_view'),
    path('contractor/scorm/<str:filename>/check-complete/', contractor_scorm_check_complete_action, name='contractor_scorm_check_complete_action'),
    path('scorm/player/<str:folder>/<path:filepath>', scorm_player_file_view, name='scorm_player_file'),
    path('scorm/player/<str:folder>/<path:filepath>/', scorm_player_file_redirect_view, name='scorm_player_file_slash_redirect'),

]
