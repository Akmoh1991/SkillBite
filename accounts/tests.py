import json
import os

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from django.urls import reverse

from accounts.models import BusinessTenant, EmployeeProfile, JobTitle
from training.models import (
    Course,
    CourseContentItem,
    CourseAssignment,
    CourseAssignmentRule,
    CourseExamSession,
    ExamTemplate,
    SOPChecklist,
    SOPChecklistAssignmentRule,
    SOPChecklistCompletion,
    SOPChecklistItem,
    SOPChecklistItemCompletion,
)


User = get_user_model()


class MultiTenantFlowTests(TestCase):
    def setUp(self):
        self.owner = User.objects.create_user(username='owner', password='pass12345')
        self.business = BusinessTenant.objects.create(owner=self.owner, name='Cafe North')
        self.job_title = JobTitle.objects.create(business=self.business, name='Barista')
        self.course = Course.objects.create(
            business=self.business,
            title='Food Safety Basics',
            estimated_minutes=20,
            created_by=self.owner,
        )
        CourseAssignmentRule.objects.create(
            business=self.business,
            job_title=self.job_title,
            course=self.course,
            assigned_by=self.owner,
        )
        self.checklist = SOPChecklist.objects.create(
            business=self.business,
            title='Opening Shift',
            frequency=SOPChecklist.Frequency.DAILY,
            created_by=self.owner,
        )
        self.checklist_item_1 = SOPChecklistItem.objects.create(checklist=self.checklist, title='Sanitize counters', order=1)
        self.checklist_item_2 = SOPChecklistItem.objects.create(checklist=self.checklist, title='Turn on POS', order=2)
        SOPChecklistAssignmentRule.objects.create(
            business=self.business,
            job_title=self.job_title,
            checklist=self.checklist,
            assigned_by=self.owner,
        )

    def test_home_redirects_business_owner_to_owner_dashboard(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.get(reverse('home'))
        self.assertRedirects(response, reverse('business_owner_dashboard'))
        dashboard_response = self.client.get(reverse('business_owner_dashboard'))
        self.assertEqual(dashboard_response.status_code, 200)

    def test_owner_creates_employee_and_job_title_course_assignment_is_provisioned(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_employee_create'),
            {
                'username': 'employee1',
                'email': 'employee1@example.com',
                'full_name': 'Employee One',
                'password': 'pass12345',
                'job_title': self.job_title.id,
            },
        )
        self.assertRedirects(response, reverse('business_owner_employees'))

        employee_user = User.objects.get(username='employee1')
        employee_profile = EmployeeProfile.objects.get(user=employee_user)
        self.assertEqual(employee_profile.business, self.business)
        self.assertEqual(employee_profile.job_title, self.job_title)

        assignment = CourseAssignment.objects.get(employee=employee_user, course=self.course)
        self.assertEqual(assignment.business, self.business)
        self.assertEqual(assignment.assigned_via_job_title, self.job_title)

    def test_employee_can_complete_assigned_course(self):
        employee_user = User.objects.create_user(username='employee2', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            assigned_via_job_title=self.job_title,
        )

        self.client.login(username='employee2', password='pass12345')
        dashboard_response = self.client.get(reverse('employee_dashboard'))
        self.assertEqual(dashboard_response.status_code, 200)
        response = self.client.post(reverse('employee_course_complete', args=[assignment.id]))
        self.assertRedirects(response, reverse('employee_courses'))

        assignment.refresh_from_db()
        self.assertEqual(assignment.status, CourseAssignment.Status.COMPLETED)
        self.assertIsNotNone(assignment.completed_at)

    def test_employee_can_complete_daily_sop_checklist(self):
        employee_user = User.objects.create_user(username='employee3', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee3', password='pass12345')
        response = self.client.post(
            reverse('employee_checklist_complete', args=[self.checklist.id]),
            {
                'item_ids': [self.checklist_item_1.id, self.checklist_item_2.id],
                'notes': 'Morning shift done',
            },
        )
        self.assertRedirects(response, reverse('employee_checklists'))

        completion = SOPChecklistCompletion.objects.get(employee=employee_user, checklist=self.checklist)
        self.assertEqual(completion.notes, 'Morning shift done')
        self.assertEqual(
            SOPChecklistItemCompletion.objects.filter(completion=completion, is_checked=True).count(),
            2,
        )

    def test_owner_navigation_pages_render(self):
        self.client.login(username='owner', password='pass12345')

        for route_name in (
            'business_owner_dashboard',
            'business_owner_employees',
            'business_owner_courses',
            'business_owner_course_content',
            'business_owner_checklists',
        ):
            response = self.client.get(reverse(route_name))
            self.assertEqual(response.status_code, 200)

    def test_owner_scorm_library_redirects_home(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.get(reverse('business_owner_scorm'))
        self.assertRedirects(response, reverse('home'), fetch_redirect_response=False)

    def test_owner_can_create_course_content_item(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_course_content_create'),
            {
                'course': self.course.id,
                'content_type': CourseContentItem.ContentType.LESSON,
                'title': 'Hand Washing Steps',
                'body': 'Wash hands before touching any food or equipment.',
                'video_file': SimpleUploadedFile('lesson.mp4', b'fake video content', content_type='video/mp4'),
                'order': 1,
            },
        )

        self.assertRedirects(response, f"{reverse('business_owner_course_content')}?course={self.course.id}")
        self.assertTrue(
            CourseContentItem.objects.filter(
                course=self.course,
                title='Hand Washing Steps',
                content_type=CourseContentItem.ContentType.LESSON,
            ).exists()
        )

    def test_employee_navigation_pages_render(self):
        employee_user = User.objects.create_user(username='employee_nav', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            assigned_via_job_title=self.job_title,
        )

        self.client.login(username='employee_nav', password='pass12345')

        routes = (
            reverse('employee_dashboard'),
            reverse('employee_courses'),
            reverse('employee_course_view', args=[assignment.id]),
            reverse('employee_checklists'),
        )
        for route in routes:
            response = self.client.get(route)
            self.assertEqual(response.status_code, 200)

    def test_employee_scorm_pages_redirect_home(self):
        employee_user = User.objects.create_user(username='employee_scorm_blocked', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        self.client.login(username='employee_scorm_blocked', password='pass12345')

        courses_response = self.client.get(reverse('employee_scorm_courses'))
        self.assertRedirects(courses_response, reverse('home'), fetch_redirect_response=False)

        detail_response = self.client.get(reverse('employee_scorm_course_view', args=['demo.zip']))
        self.assertRedirects(detail_response, reverse('home'), fetch_redirect_response=False)

    def test_employee_scorm_completion_post_is_rejected(self):
        employee_user = User.objects.create_user(username='employee_scorm_post', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        self.client.login(username='employee_scorm_post', password='pass12345')

        response = self.client.post(
            reverse('employee_scorm_check_complete_action', args=['demo.zip']),
            {'lesson_status': 'completed'},
        )

        self.assertEqual(response.status_code, 403)
        self.assertEqual(
            response.json()['message'],
            'SCORM completion tracking is disabled until a server-verified flow is implemented.',
        )

    def test_employee_dashboard_backfills_missing_course_assignments(self):
        employee_user = User.objects.create_user(username='employee_backfill', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        CourseAssignment.objects.filter(employee=employee_user, course=self.course).delete()

        self.client.login(username='employee_backfill', password='pass12345')
        response = self.client.get(reverse('employee_dashboard'))
        self.assertEqual(response.status_code, 200)
        self.assertTrue(CourseAssignment.objects.filter(employee=employee_user, course=self.course).exists())

    def test_single_job_title_business_implicitly_assigns_course_without_rule(self):
        CourseAssignmentRule.objects.all().delete()
        employee_user = User.objects.create_user(username='employee_implicit_course', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee_implicit_course', password='pass12345')
        response = self.client.get(reverse('employee_courses'))
        self.assertEqual(response.status_code, 200)
        self.assertTrue(CourseAssignment.objects.filter(employee=employee_user, course=self.course).exists())

    def test_employee_courses_page_backfills_nine_catalog_courses_from_database(self):
        CourseAssignment.objects.all().delete()
        CourseAssignmentRule.objects.all().delete()
        CourseContentItem.objects.all().delete()
        Course.objects.all().delete()
        employee_user = User.objects.create_user(username='employee_seeded_catalog', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee_seeded_catalog', password='pass12345')
        response = self.client.get(reverse('employee_courses'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'مهارات الكاشير')
        self.assertContains(response, 'أساسيات خدمة العملاء')
        self.assertEqual(Course.objects.filter(business=self.business).count(), 9)
        self.assertTrue(CourseAssignment.objects.filter(employee=employee_user, course__title='مهارات الكاشير').exists())

    def test_employee_courses_page_completes_catalog_when_one_matching_course_already_exists(self):
        Course.objects.all().delete()
        CourseAssignmentRule.objects.all().delete()
        CourseContentItem.objects.all().delete()
        Course.objects.create(
            business=self.business,
            title='مهارات الكاشير',
            description='دورة عن مهارات الكاشير',
            estimated_minutes=10,
            created_by=self.owner,
        )
        employee_user = User.objects.create_user(username='employee_partial_catalog', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee_partial_catalog', password='pass12345')
        response = self.client.get(reverse('employee_courses'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(Course.objects.filter(business=self.business).count(), 9)
        self.assertEqual(Course.objects.filter(business=self.business, title='مهارات الكاشير').count(), 1)

    def test_employee_courses_page_links_to_course_view_page(self):
        CourseContentItem.objects.create(
            course=self.course,
            content_type=CourseContentItem.ContentType.TEXT,
            title='Daily safety reminder',
            body='Keep chilled items below the required storage temperature.',
            order=1,
        )
        employee_user = User.objects.create_user(username='employee_content', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee_content', password='pass12345')
        response = self.client.get(reverse('employee_courses'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, self.course.title)
        self.assertContains(response, reverse('employee_course_view', args=[CourseAssignment.objects.get(employee=employee_user, course=self.course).id]))

    def test_employee_course_view_page_displays_authored_course_content(self):
        CourseContentItem.objects.create(
            course=self.course,
            content_type=CourseContentItem.ContentType.MATERIAL,
            title='Cash register opening',
            body='Verify float balance before serving customers.',
            video_file=SimpleUploadedFile('opening.mp4', b'fake video content', content_type='video/mp4'),
            order=1,
        )
        employee_user = User.objects.create_user(username='employee_course_view', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            assigned_via_job_title=self.job_title,
        )

        self.client.login(username='employee_course_view', password='pass12345')
        response = self.client.get(reverse('employee_course_view', args=[assignment.id]))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Cash register opening')
        self.assertContains(response, 'Verify float balance before serving customers.')
        self.assertContains(response, '/media/course_content_videos/')

        assignment.refresh_from_db()
        self.assertEqual(assignment.status, CourseAssignment.Status.IN_PROGRESS)

    def test_employee_course_view_includes_exam_button_and_exam_pages_render(self):
        CourseContentItem.objects.create(
            course=self.course,
            content_type=CourseContentItem.ContentType.TEXT,
            title='Hand washing steps',
            body='Wash, rinse, sanitize, and dry thoroughly.',
            order=1,
        )
        employee_user = User.objects.create_user(username='employee_exam_view', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            assigned_via_job_title=self.job_title,
        )

        self.client.login(username='employee_exam_view', password='pass12345')
        course_response = self.client.get(reverse('employee_course_view', args=[assignment.id]))
        exam_url = reverse('employee_course_exam', args=[assignment.id])

        self.assertEqual(course_response.status_code, 200)
        self.assertContains(course_response, exam_url)

        exam_response = self.client.get(exam_url)
        self.assertEqual(exam_response.status_code, 200)
        self.assertContains(exam_response, self.course.title)

        take_response = self.client.get(reverse('employee_course_exam_take', args=[assignment.id]))
        self.assertEqual(take_response.status_code, 200)
        self.assertContains(take_response, 'Hand washing steps')

    def test_single_job_title_business_implicitly_exposes_checklist_without_rule(self):
        SOPChecklistAssignmentRule.objects.all().delete()
        employee_user = User.objects.create_user(username='employee_implicit_checklist', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee_implicit_checklist', password='pass12345')
        response = self.client.get(reverse('employee_checklists'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, self.checklist.title)


class SuperAdminFlowTests(TestCase):
    def setUp(self):
        self.super_admin = User.objects.create_user(
            username='platform_admin',
            password='pass12345',
            is_staff=True,
            is_superuser=True,
        )
        self.owner = User.objects.create_user(username='owner_sa', password='pass12345')
        self.business = BusinessTenant.objects.create(owner=self.owner, name='Cafe South')
        self.job_title = JobTitle.objects.create(business=self.business, name='Cashier')
        self.course = Course.objects.create(
            business=self.business,
            title='Opening Basics',
            estimated_minutes=15,
            created_by=self.owner,
        )
        self.checklist = SOPChecklist.objects.create(
            business=self.business,
            title='Daily Open',
            frequency=SOPChecklist.Frequency.DAILY,
            created_by=self.owner,
        )
        self.scorm_dir = os.path.join(settings.MEDIA_ROOT, 'scorm')
        self.scorm_extracted_dir = os.path.join(settings.MEDIA_ROOT, 'scorm_extracted')

    def test_home_redirects_super_admin_to_super_admin_dashboard(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.get(reverse('home'))
        self.assertRedirects(response, reverse('super_admin_dashboard'))

    def test_super_admin_pages_require_super_admin_role(self):
        self.client.login(username='owner_sa', password='pass12345')
        response = self.client.get(reverse('super_admin_dashboard'))
        self.assertRedirects(response, reverse('home'), fetch_redirect_response=False)

    def test_super_admin_can_create_business_and_owner(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.post(
            reverse('super_admin_business_create'),
            {
                'business_name': 'Cafe East',
                'industry': 'Retail',
                'owner_username': 'east_owner',
                'owner_email': 'east@example.com',
                'owner_full_name': 'East Owner',
                'owner_password': 'pass12345',
                'is_active': 'on',
            },
        )
        self.assertRedirects(response, reverse('super_admin_businesses'))
        owner = User.objects.get(username='east_owner')
        business = BusinessTenant.objects.get(owner=owner)
        self.assertEqual(business.name, 'Cafe East')
        self.assertTrue(business.is_active)

    def test_super_admin_can_toggle_course_activity(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.post(reverse('super_admin_course_toggle', args=[self.course.id]))
        self.assertRedirects(response, reverse('super_admin_learning'))
        self.course.refresh_from_db()
        self.assertFalse(self.course.is_active)

    def test_super_admin_can_publish_employee_catalog_for_business(self):
        Course.objects.filter(business=self.business).delete()
        self.client.login(username='platform_admin', password='pass12345')

        response = self.client.post(
            reverse('super_admin_publish_employee_catalog'),
            {'business': self.business.id},
        )

        self.assertRedirects(response, reverse('super_admin_learning'))
        self.assertEqual(Course.objects.filter(business=self.business).count(), 9)
        self.assertTrue(CourseContentItem.objects.filter(course__business=self.business).exists())

    def test_super_admin_can_create_exam_template_and_session_for_course(self):
        self.client.login(username='platform_admin', password='pass12345')
        create_response = self.client.post(
            reverse('super_admin_exam_template_create'),
            {
                'business': self.business.id,
                'course': self.course.id,
                'name': 'Food Safety Final',
                'duration_minutes': 25,
                'passing_score_percent': 80,
                'instructions': 'Answer all questions.',
                'show_result_after_submit': 'on',
                'shuffle_questions': 'on',
            },
        )
        template = ExamTemplate.objects.get(name='Food Safety Final')
        self.assertRedirects(create_response, reverse('super_admin_exam_template_editor', args=[template.id]))

        self.course.refresh_from_db()
        self.assertEqual(self.course.exam_template_id, template.id)

        session_response = self.client.post(
            reverse('super_admin_exam_sessions'),
            {
                'business': self.business.id,
                'course': self.course.id,
                'exam_template': template.id,
                'exam_date': '2026-04-01T09:30',
                'access_code': 'SAFE101',
                'is_active': 'on',
            },
        )
        self.assertRedirects(session_response, reverse('super_admin_exam_sessions'))
        self.assertTrue(CourseExamSession.objects.filter(course=self.course, exam_template=template, access_code='SAFE101').exists())

        templates_page = self.client.get(reverse('super_admin_exam_templates'))
        self.assertEqual(templates_page.status_code, 200)
        self.assertContains(templates_page, 'Food Safety Final')

        grading_page = self.client.get(reverse('super_admin_exam_grading'))
        self.assertEqual(grading_page.status_code, 200)
        self.assertContains(grading_page, self.course.title)

    def test_super_admin_scorm_download_requires_super_admin_role(self):
        os.makedirs(self.scorm_dir, exist_ok=True)
        package_path = os.path.join(self.scorm_dir, 'demo.zip')
        with open(package_path, 'wb') as handle:
            handle.write(b'fake zip')

        self.client.login(username='owner_sa', password='pass12345')
        response = self.client.get(reverse('scorm_zip_download', args=['demo.zip']))
        self.assertEqual(response.status_code, 403)

        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.get(reverse('scorm_zip_download', args=['demo.zip']))
        self.assertEqual(response.status_code, 200)

    def test_super_admin_scorm_player_requires_super_admin_role(self):
        os.makedirs(self.scorm_dir, exist_ok=True)
        os.makedirs(self.scorm_extracted_dir, exist_ok=True)
        metadata_path = os.path.join(self.scorm_dir, 'metadata.json')
        with open(metadata_path, 'w', encoding='utf-8') as handle:
            json.dump({'demo.zip': {'folder': 'demo_folder', 'launch': 'index.html'}}, handle)

        package_dir = os.path.join(self.scorm_extracted_dir, 'demo_folder')
        os.makedirs(package_dir, exist_ok=True)
        with open(os.path.join(package_dir, 'index.html'), 'w', encoding='utf-8') as handle:
            handle.write('<html><body>demo</body></html>')

        player_url = reverse('scorm_player_file', args=['demo_folder', 'index.html'])

        self.client.login(username='owner_sa', password='pass12345')
        response = self.client.get(player_url)
        self.assertEqual(response.status_code, 403)

        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.get(player_url)
        self.assertEqual(response.status_code, 200)


class SeedSuperAdminCommandTests(TestCase):
    def test_seed_super_admin_command_creates_user(self):
        call_command(
            'seed_super_admin',
            username='seed_admin',
            password='pass12345',
            email='seed@example.com',
            full_name='Seed Admin',
        )
        user = User.objects.get(username='seed_admin')
        self.assertTrue(user.is_active)
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        self.assertEqual(user.email, 'seed@example.com')
        self.assertTrue(user.check_password('pass12345'))

    def test_seed_super_admin_command_upgrades_existing_user(self):
        user = User.objects.create_user(username='seed_existing', password='oldpass', is_staff=False, is_superuser=False, is_active=False)
        call_command(
            'seed_super_admin',
            username='seed_existing',
            password='newpass123',
            email='new@example.com',
            full_name='Existing Admin',
        )
        user.refresh_from_db()
        self.assertTrue(user.is_active)
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        self.assertEqual(user.email, 'new@example.com')
        self.assertEqual(user.first_name, 'Existing')
        self.assertEqual(user.last_name, 'Admin')
        self.assertTrue(user.check_password('newpass123'))
