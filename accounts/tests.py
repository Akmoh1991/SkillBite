import json
import os
from unittest.mock import PropertyMock, patch

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.management import call_command
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.urls import reverse

from accounts.models import BusinessTenant, EmployeeProfile, JobTitle
from certification.models import ScormCertificate
from training.models import (
    Course,
    CourseContentItem,
    CourseAssignment,
    ExamOption,
    ExamQuestion,
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

    def test_public_registration_accepts_visible_signup_fields(self):
        response = self.client.post(
            reverse('register'),
            {
                'username': 'newowner',
                'email': 'owner@example.com',
                'full_name_en': 'Ahmed Al Ahmed',
                'password': 'StrongPass123!',
                'role': 'business_owner',
                'company_name': 'Brave Cafe',
                'region': 'Eastern region',
                'phone_number': '0555555555',
            },
        )

        self.assertRedirects(response, reverse('business_owner_dashboard'), fetch_redirect_response=False)
        user = User.objects.get(username='newowner')
        business = BusinessTenant.objects.get(owner=user)
        self.assertEqual(user.email, 'owner@example.com')
        self.assertEqual(user.first_name, 'Ahmed Al Ahmed')
        self.assertEqual(business.name, 'Brave Cafe')

    def test_home_redirects_business_owner_to_owner_dashboard(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.get(reverse('home'))
        self.assertRedirects(response, reverse('business_owner_dashboard'))
        dashboard_response = self.client.get(reverse('business_owner_dashboard'))
        self.assertEqual(dashboard_response.status_code, 200)

    def test_owner_creates_employee_without_auto_course_assignment(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_employee_create'),
            {
                'username': 'employee1',
                'email': 'employee1@example.com',
                'full_name': 'Employee One',
                'password': 'pass12345',
                'job_title': self.job_title.name,
            },
        )
        self.assertRedirects(response, reverse('business_owner_employees'))

        employee_user = User.objects.get(username='employee1')
        employee_profile = EmployeeProfile.objects.get(user=employee_user)
        self.assertEqual(employee_profile.business, self.business)
        self.assertEqual(employee_profile.job_title, self.job_title)
        self.assertFalse(CourseAssignment.objects.filter(employee=employee_user, course=self.course).exists())

    def test_owner_can_create_employee_with_new_text_job_title(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_employee_create'),
            {
                'username': 'employee2a',
                'email': 'employee2a@example.com',
                'full_name': 'Employee Two',
                'password': 'pass12345',
                'job_title': 'Shift Lead',
            },
        )
        self.assertRedirects(response, reverse('business_owner_employees'))

        employee_user = User.objects.get(username='employee2a')
        employee_profile = EmployeeProfile.objects.get(user=employee_user)
        self.assertEqual(employee_profile.job_title.name, 'Shift Lead')
        self.assertTrue(JobTitle.objects.filter(business=self.business, name='Shift Lead').exists())

    def test_employee_can_complete_assigned_course(self):
        employee_user = User.objects.create_user(username='employee2', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
        )

        self.client.login(username='employee2', password='pass12345')
        dashboard_response = self.client.get(reverse('employee_dashboard'))
        self.assertEqual(dashboard_response.status_code, 200)
        self.client.get(reverse('employee_course_view', args=[assignment.id]))
        response = self.client.post(reverse('employee_course_complete', args=[assignment.id]))
        self.assertRedirects(response, reverse('employee_courses'))

        assignment.refresh_from_db()
        self.assertEqual(assignment.status, CourseAssignment.Status.COMPLETED)
        self.assertIsNotNone(assignment.completed_at)

    def test_cloudinary_video_playback_url_does_not_duplicate_mp4_extension(self):
        item = CourseContentItem.objects.create(
            course=self.course,
            content_type=CourseContentItem.ContentType.LESSON,
            title='Video lesson',
            video_file='course_content_videos/sample-video.mp4',
            order=1,
        )

        with patch('django.db.models.fields.files.FieldFile.url', new_callable=PropertyMock) as mocked_url:
            mocked_url.return_value = 'https://res.cloudinary.com/dtmyrie3t/video/upload/v1/media/course_content_videos/sample-video.mp4'
            self.assertEqual(
                item.video_playback_url,
                'https://res.cloudinary.com/dtmyrie3t/video/upload/v1/course_content_videos/sample-video.mp4',
            )
            self.assertEqual(item.video_mime_type, 'video/mp4')

    def test_certificate_download_url_uses_signed_cloudinary_pdf_download(self):
        from accounts.views import _certificate_file_url

        class DummyFieldFile:
            name = 'media/certificates/sample-certificate.pdf'
            url = 'https://res.cloudinary.com/dtmyrie3t/raw/upload/v1/media/certificates/sample-certificate.pdf'

        with patch('accounts.views.private_download_url', return_value='https://api.cloudinary.com/v1_1/dtmyrie3t/raw/download?signature=test') as mocked_download_url:
            result = _certificate_file_url(DummyFieldFile())

        mocked_download_url.assert_called_once_with(
            'media/certificates/sample-certificate',
            'pdf',
            resource_type='raw',
            type='upload',
            attachment='sample-certificate.pdf',
            secure=True,
        )
        self.assertEqual(result, 'https://api.cloudinary.com/v1_1/dtmyrie3t/raw/download?signature=test')

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
            'business_owner_checklists',
        ):
            response = self.client.get(reverse(route_name))
            self.assertEqual(response.status_code, 200)
        course_content_response = self.client.get(reverse('business_owner_course_content'))
        self.assertRedirects(course_content_response, reverse('business_owner_course_list'), fetch_redirect_response=False)

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

        self.assertRedirects(
            response,
            f"{reverse('business_owner_course_content')}?course={self.course.id}",
            fetch_redirect_response=False,
        )
        self.assertTrue(
            CourseContentItem.objects.filter(
                course=self.course,
                title='Hand Washing Steps',
                content_type=CourseContentItem.ContentType.LESSON,
            ).exists()
        )

    def test_owner_rejects_unsupported_video_format_when_creating_course_content_item(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_course_content_create'),
            {
                'course': self.course.id,
                'content_type': CourseContentItem.ContentType.LESSON,
                'title': 'Unsupported lesson',
                'body': 'This should be rejected.',
                'video_file': SimpleUploadedFile('lesson.mov', b'fake video content', content_type='video/quicktime'),
                'order': 1,
            },
        )

        self.assertRedirects(
            response,
            f"{reverse('business_owner_course_content')}?course={self.course.id}",
            fetch_redirect_response=False,
        )
        self.assertFalse(
            CourseContentItem.objects.filter(
                course=self.course,
                title='Unsupported lesson',
            ).exists()
        )

    def test_owner_rejects_unsupported_video_format_when_creating_course_with_initial_content(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_course_create'),
            {
                'title': 'Unsupported Video Course',
                'description': 'Course should not be created with unsupported video.',
                'estimated_minutes': 15,
                'content_title': 'Initial lesson',
                'content_type': CourseContentItem.ContentType.LESSON,
                'content_order': 1,
                'content_video_file': SimpleUploadedFile('intro.mov', b'fake video content', content_type='video/quicktime'),
            },
        )

        self.assertRedirects(response, reverse('business_owner_courses'), fetch_redirect_response=False)
        self.assertFalse(Course.objects.filter(business=self.business, title='Unsupported Video Course').exists())

    def test_owner_course_view_shows_assign_course_button(self):
        self.client.login(username='owner', password='pass12345')
        response = self.client.get(reverse('business_owner_course_view', args=[self.course.id]))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'إدراج الدورة')

    def test_owner_can_assign_course_to_selected_employees_from_course_view(self):
        self.client.login(username='owner', password='pass12345')
        manual_course = Course.objects.create(
            business=self.business,
            title='Kitchen Safety',
            estimated_minutes=15,
            created_by=self.owner,
        )
        employee_user_1 = User.objects.create_user(username='selected_emp_1', password='pass12345')
        employee_user_2 = User.objects.create_user(username='selected_emp_2', password='pass12345')
        employee_profile_1 = EmployeeProfile.objects.create(user=employee_user_1, business=self.business, created_by=self.owner)
        employee_profile_2 = EmployeeProfile.objects.create(user=employee_user_2, business=self.business, created_by=self.owner)

        response = self.client.post(
            reverse('business_owner_course_assign_employees', args=[manual_course.id]),
            {'employee_ids': [employee_profile_1.id, employee_profile_2.id]},
        )
        self.assertRedirects(response, reverse('business_owner_course_view', args=[manual_course.id]))
        self.assertTrue(CourseAssignment.objects.filter(course=manual_course, employee=employee_user_1).exists())
        self.assertTrue(CourseAssignment.objects.filter(course=manual_course, employee=employee_user_2).exists())

    def test_owner_can_assign_course_to_all_employees_from_course_view(self):
        self.client.login(username='owner', password='pass12345')
        manual_course = Course.objects.create(
            business=self.business,
            title='Service Basics',
            estimated_minutes=10,
            created_by=self.owner,
        )
        employee_user_1 = User.objects.create_user(username='all_emp_1', password='pass12345')
        employee_user_2 = User.objects.create_user(username='all_emp_2', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user_1, business=self.business, created_by=self.owner)
        EmployeeProfile.objects.create(user=employee_user_2, business=self.business, created_by=self.owner)

        response = self.client.post(
            reverse('business_owner_course_assign_employees', args=[manual_course.id]),
            {'assign_scope': 'all'},
        )
        self.assertRedirects(response, reverse('business_owner_course_view', args=[manual_course.id]))
        self.assertEqual(CourseAssignment.objects.filter(course=manual_course).count(), 2)

    def test_owner_dashboard_assign_modal_marks_already_assigned_courses_for_employee(self):
        self.client.login(username='owner', password='pass12345')
        employee_user = User.objects.create_user(username='dashboard_emp', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        response = self.client.get(reverse('business_owner_dashboard'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'data-assigned-course-ids="')
        self.assertContains(response, 'data-assigned-course-ids=""')

    def test_owner_dashboard_assign_modal_marks_only_manual_assignments_as_already_assigned(self):
        self.client.login(username='owner', password='pass12345')
        employee_user = User.objects.create_user(username='dashboard_manual_emp', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        manual_course = Course.objects.create(
            business=self.business,
            title='Manual Dashboard Course',
            estimated_minutes=18,
            created_by=self.owner,
        )
        CourseAssignment.objects.create(
            business=self.business,
            course=manual_course,
            employee=employee_user,
            assigned_by=self.owner,
        )

        response = self.client.get(reverse('business_owner_dashboard'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, f'data-assigned-course-ids="{manual_course.id}"')

    def test_owner_dashboard_assign_modal_hides_active_courses_from_other_businesses(self):
        other_owner = User.objects.create_user(username='owner_other', password='pass12345')
        other_business = BusinessTenant.objects.create(owner=other_owner, name='Cafe South')
        external_course = Course.objects.create(
            business=other_business,
            title='Latte Art Mastery',
            estimated_minutes=35,
            created_by=other_owner,
        )

        self.client.login(username='owner', password='pass12345')
        response = self.client.get(reverse('business_owner_dashboard'))

        self.assertEqual(response.status_code, 200)
        self.assertNotContains(response, f'{external_course.title} - {other_business.name}')

    def test_owner_dashboard_assign_modal_hides_inactive_courses_from_other_businesses(self):
        other_owner = User.objects.create_user(username='owner_other_inactive', password='pass12345')
        other_business = BusinessTenant.objects.create(owner=other_owner, name='Cafe West')
        external_course = Course.objects.create(
            business=other_business,
            title='Cold Brew Archive',
            estimated_minutes=25,
            is_active=False,
            created_by=other_owner,
        )

        self.client.login(username='owner', password='pass12345')
        response = self.client.get(reverse('business_owner_dashboard'))

        self.assertEqual(response.status_code, 200)
        self.assertNotContains(response, f'{external_course.title} - {other_business.name}')

    def test_owner_cannot_assign_active_course_from_other_business_on_dashboard(self):
        employee_user = User.objects.create_user(username='cross_business_emp', password='pass12345')
        employee_profile = EmployeeProfile.objects.create(
            user=employee_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )
        other_owner = User.objects.create_user(username='owner_remote', password='pass12345')
        other_business = BusinessTenant.objects.create(owner=other_owner, name='Cafe East')
        external_course = Course.objects.create(
            business=other_business,
            title='Coffee Roasting 101',
            estimated_minutes=40,
            created_by=other_owner,
        )

        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_dashboard_assign_course', args=[employee_profile.id]),
            {'course_id': external_course.id},
            follow=True,
        )

        self.assertEqual(response.status_code, 200)
        self.assertFalse(
            CourseAssignment.objects.filter(
                business=self.business,
                course=external_course,
                employee=employee_user,
            ).exists()
        )

    def test_owner_cannot_assign_inactive_course_from_other_business_on_dashboard(self):
        employee_user = User.objects.create_user(username='cross_business_inactive_emp', password='pass12345')
        employee_profile = EmployeeProfile.objects.create(
            user=employee_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )
        other_owner = User.objects.create_user(username='owner_remote_inactive', password='pass12345')
        other_business = BusinessTenant.objects.create(owner=other_owner, name='Cafe Archive')
        external_course = Course.objects.create(
            business=other_business,
            title='Legacy Espresso Basics',
            estimated_minutes=40,
            is_active=False,
            created_by=other_owner,
        )

        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_dashboard_assign_course', args=[employee_profile.id]),
            {'course_id': external_course.id},
            follow=True,
        )

        self.assertEqual(response.status_code, 200)
        self.assertFalse(
            CourseAssignment.objects.filter(
                business=self.business,
                course=external_course,
                employee=employee_user,
            ).exists()
        )

    def test_owner_dashboard_delete_employee_deactivates_profile_and_user(self):
        self.client.login(username='owner', password='pass12345')
        employee_user = User.objects.create_user(username='delete_employee', password='pass12345')
        employee_profile = EmployeeProfile.objects.create(
            user=employee_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )

        response = self.client.post(
            reverse('business_owner_dashboard_delete_employee', args=[employee_profile.id]),
            follow=True,
        )

        self.assertEqual(response.status_code, 200)
        employee_profile.refresh_from_db()
        employee_user.refresh_from_db()
        self.assertFalse(employee_profile.is_active)
        self.assertFalse(employee_user.is_active)

    def test_owner_dashboard_delete_employee_missing_profile_redirects_without_404(self):
        self.client.login(username='owner', password='pass12345')
        employee_user = User.objects.create_user(username='inactive_delete', password='pass12345')
        employee_profile = EmployeeProfile.objects.create(
            user=employee_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
            is_active=False,
        )
        employee_user.is_active = False
        employee_user.save(update_fields=['is_active'])

        response = self.client.post(
            reverse('business_owner_dashboard_delete_employee', args=[employee_profile.id]),
            follow=True,
        )

        self.assertEqual(response.status_code, 200)
        self.assertRedirects(response, reverse('business_owner_dashboard'))

    def test_owner_dashboard_hides_deleted_employee_from_list_after_delete(self):
        self.client.login(username='owner', password='pass12345')
        deleted_user = User.objects.create_user(username='deleted_employee', password='pass12345')
        active_user = User.objects.create_user(username='active_employee', password='pass12345')
        deleted_profile = EmployeeProfile.objects.create(
            user=deleted_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )
        EmployeeProfile.objects.create(
            user=active_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )

        response = self.client.post(
            reverse('business_owner_dashboard_delete_employee', args=[deleted_profile.id]),
            follow=True,
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'active_employee')
        self.assertNotContains(response, 'deleted_employee')

    def test_owner_bulk_assign_shows_error_when_course_already_visible_to_selected_employees(self):
        self.client.login(username='owner', password='pass12345')
        employee_user = User.objects.create_user(username='duplicate_emp', password='pass12345')
        employee_profile = EmployeeProfile.objects.create(user=employee_user, business=self.business, created_by=self.owner)
        CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
        )

        response = self.client.post(
            reverse('business_owner_course_assign_employees', args=[self.course.id]),
            {'employee_ids': [employee_profile.id]},
            follow=True,
        )
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'message-card error')
        self.assertContains(response, 'هذه الدورة مدرجة بالفعل للموظفين المحددين وتظهر لهم في لوحة الموظف.')

    def test_manual_assignment_remains_manual_for_employee(self):
        employee_user = User.objects.create_user(username='manual_assignment_emp', password='pass12345')
        employee_profile = EmployeeProfile.objects.create(
            user=employee_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
        )

        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_dashboard_assign_course', args=[employee_profile.id]),
            {'course_id': self.course.id},
            follow=True,
        )

        self.assertEqual(response.status_code, 200)
        assignment.refresh_from_db()
        self.assertEqual(assignment.employee, employee_profile.user)
        self.assertEqual(
            CourseAssignment.objects.filter(employee=employee_profile.user, course=self.course).count(),
            1,
        )

    def test_dashboard_manual_assignment_makes_course_visible_to_employee(self):
        employee_user = User.objects.create_user(username='manual_visible_emp', password='pass12345')
        employee_profile = EmployeeProfile.objects.create(
            user=employee_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )

        self.client.login(username='owner', password='pass12345')
        response = self.client.post(
            reverse('business_owner_dashboard_assign_course', args=[employee_profile.id]),
            {'course_id': self.course.id},
            follow=True,
        )

        self.assertEqual(response.status_code, 200)
        assignment = CourseAssignment.objects.get(employee=employee_user, course=self.course)
        self.assertEqual(assignment.assigned_by, self.owner)

        self.client.logout()
        self.client.login(username='manual_visible_emp', password='pass12345')
        employee_courses_response = self.client.get(reverse('employee_courses'))
        self.assertEqual(employee_courses_response.status_code, 200)
        self.assertContains(employee_courses_response, self.course.title)

    def test_employee_navigation_pages_render(self):
        employee_user = User.objects.create_user(username='employee_nav', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
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

    def test_employee_dashboard_shows_only_latest_three_active_assigned_courses(self):
        employee_user = User.objects.create_user(username='employee_many_courses', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, created_by=self.owner)
        extra_courses = [
            Course.objects.create(business=self.business, title=f'Extra Course {index}', estimated_minutes=10 + index, created_by=self.owner)
            for index in range(4)
        ]
        for course in extra_courses:
            CourseAssignment.objects.create(
                business=self.business,
                course=course,
                employee=employee_user,
                assigned_by=self.owner,
            )

        self.client.login(username='employee_many_courses', password='pass12345')
        response = self.client.get(reverse('employee_dashboard'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Extra Course 3')
        self.assertContains(response, 'Extra Course 2')
        self.assertContains(response, 'Extra Course 1')
        self.assertNotContains(response, 'Extra Course 0')

    def test_employee_courses_page_shows_manual_assignments(self):
        employee_user = User.objects.create_user(username='employee_visible_courses', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        owner_assigned_course = Course.objects.create(
            business=self.business,
            title='Owner Assigned Course',
            estimated_minutes=20,
            created_by=self.owner,
        )
        CourseAssignment.objects.create(
            business=self.business,
            course=owner_assigned_course,
            employee=employee_user,
            assigned_by=self.owner,
        )
        manual_second_course = Course.objects.create(
            business=self.business,
            title='Manual Follow Up',
            estimated_minutes=15,
            created_by=self.owner,
        )
        CourseAssignment.objects.create(
            business=self.business,
            course=manual_second_course,
            employee=employee_user,
            assigned_by=self.owner,
        )

        self.client.login(username='employee_visible_courses', password='pass12345')
        response = self.client.get(reverse('employee_courses'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Owner Assigned Course')
        self.assertContains(response, manual_second_course.title)

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

    def test_employee_dashboard_does_not_backfill_missing_course_assignments(self):
        employee_user = User.objects.create_user(username='employee_backfill', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        CourseAssignment.objects.filter(employee=employee_user, course=self.course).delete()

        self.client.login(username='employee_backfill', password='pass12345')
        response = self.client.get(reverse('employee_dashboard'))
        self.assertEqual(response.status_code, 200)
        self.assertFalse(CourseAssignment.objects.filter(employee=employee_user, course=self.course).exists())

    def test_job_titles_do_not_implicitly_assign_course(self):
        employee_user = User.objects.create_user(username='employee_implicit_course', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee_implicit_course', password='pass12345')
        response = self.client.get(reverse('employee_courses'))
        self.assertEqual(response.status_code, 200)
        self.assertFalse(CourseAssignment.objects.filter(employee=employee_user, course=self.course).exists())
        self.assertNotContains(response, self.course.title)

    def test_employee_courses_page_backfills_nine_catalog_courses_from_database(self):
        CourseAssignment.objects.all().delete()
        CourseContentItem.objects.all().delete()
        Course.objects.all().delete()
        employee_user = User.objects.create_user(username='employee_seeded_catalog', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)

        self.client.login(username='employee_seeded_catalog', password='pass12345')
        response = self.client.get(reverse('employee_courses'))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(Course.objects.filter(business=self.business).count(), 9)
        self.assertEqual(CourseAssignment.objects.filter(employee=employee_user).count(), 0)
        return
        self.assertContains(response, 'مهارات الكاشير')
        self.assertContains(response, 'أساسيات خدمة العملاء')
        self.assertEqual(Course.objects.filter(business=self.business).count(), 9)
        self.assertTrue(CourseAssignment.objects.filter(employee=employee_user, course__title='مهارات الكاشير').exists())

    def test_employee_courses_page_completes_catalog_when_one_matching_course_already_exists(self):
        Course.objects.all().delete()
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
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
        )

        self.client.login(username='employee_content', password='pass12345')
        response = self.client.get(reverse('employee_courses'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, self.course.title)
        self.assertContains(response, reverse('employee_course_view', args=[assignment.id]))

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
        )

        self.client.login(username='employee_course_view', password='pass12345')
        response = self.client.get(reverse('employee_course_view', args=[assignment.id]))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Cash register opening')
        self.assertContains(response, '/media/course_content_videos/')

        assignment.refresh_from_db()
        self.assertEqual(assignment.status, CourseAssignment.Status.IN_PROGRESS)

    def test_employee_learning_history_lists_completed_courses_without_certificate_links(self):
        employee_user = User.objects.create_user(username='employee_learning_history', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        completed_assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            status=CourseAssignment.Status.COMPLETED,
        )
        completed_assignment.completed_at = completed_assignment.assigned_at
        completed_assignment.save(update_fields=['completed_at'])

        pending_course = Course.objects.create(
            business=self.business,
            title='Customer Service Basics',
            estimated_minutes=15,
        )
        CourseAssignment.objects.create(
            business=self.business,
            course=pending_course,
            employee=employee_user,
            assigned_by=self.owner,
            status=CourseAssignment.Status.IN_PROGRESS,
        )

        self.client.login(username='employee_learning_history', password='pass12345')
        response = self.client.get(reverse('employee_learning_history'))

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'سجل الدورات المكتملة')
        self.assertContains(response, self.course.title)
        self.assertNotContains(response, pending_course.title)
        self.assertNotContains(response, 'PDF')
        return
        self.assertContains(response, 'تنزيل PDF')
        self.assertNotContains(response, 'PDF')

    def test_employee_course_complete_action_marks_course_completed_without_certificate(self):
        employee_user = User.objects.create_user(username='employee_course_complete_cert', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            status=CourseAssignment.Status.IN_PROGRESS,
        )

        self.client.login(username='employee_course_complete_cert', password='pass12345')
        self.client.get(reverse('employee_course_view', args=[assignment.id]))
        response = self.client.post(reverse('employee_course_complete', args=[assignment.id]), follow=True)

        self.assertEqual(response.status_code, 200)
        assignment.refresh_from_db()
        self.assertEqual(assignment.status, CourseAssignment.Status.COMPLETED)
        self.assertIsNotNone(assignment.completed_at)
        self.assertFalse(
            ScormCertificate.objects.filter(owner=employee_user, scorm_filename=f'course_exam_{self.course.id}').exists()
        )
        self.assertNotContains(response, 'PDF')

        history_response = self.client.get(reverse('employee_learning_history'))
        self.assertContains(history_response, self.course.title)
        self.assertNotContains(history_response, 'PDF')
        return

        certificate = ScormCertificate.objects.get(owner=employee_user, scorm_filename=f'course_exam_{self.course.id}')
        self.assertTrue(bool(certificate.pdf_file))
        self.assertContains(response, certificate.pdf_file.url)

        history_response = self.client.get(reverse('employee_learning_history'))
        self.assertContains(history_response, self.course.title)
        self.assertContains(history_response, certificate.pdf_file.url)

    def test_employee_course_complete_requires_course_view_before_manual_completion(self):
        employee_user = User.objects.create_user(username='employee_course_manual_guard', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            status=CourseAssignment.Status.IN_PROGRESS,
        )

        self.client.login(username='employee_course_manual_guard', password='pass12345')
        response = self.client.post(reverse('employee_course_complete', args=[assignment.id]), follow=True)

        self.assertEqual(response.status_code, 200)
        assignment.refresh_from_db()
        self.assertNotEqual(assignment.status, CourseAssignment.Status.COMPLETED)

    def test_employee_course_complete_rejects_exam_protected_courses(self):
        template = ExamTemplate.objects.create(
            business=self.business,
            name='Completion Gate',
            duration_minutes=15,
            total_questions=1,
            created_by=self.owner,
        )
        self.course.exam_template = template
        self.course.save(update_fields=['exam_template'])

        employee_user = User.objects.create_user(username='employee_exam_guard', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
            status=CourseAssignment.Status.IN_PROGRESS,
        )

        self.client.login(username='employee_exam_guard', password='pass12345')
        self.client.get(reverse('employee_course_view', args=[assignment.id]))
        response = self.client.post(reverse('employee_course_complete', args=[assignment.id]), follow=True)

        self.assertEqual(response.status_code, 200)
        assignment.refresh_from_db()
        self.assertNotEqual(assignment.status, CourseAssignment.Status.COMPLETED)

    def test_employee_exam_uses_course_template_and_completes_course_on_submit(self):
        template = ExamTemplate.objects.create(
            business=self.business,
            name='Food Safety Final',
            duration_minutes=20,
            total_questions=0,
            created_by=self.owner,
        )
        ExamQuestion.objects.create(
            template=template,
            order=1,
            question_text='What is the safe storage temperature?',
            question_type=ExamQuestion.QuestionType.MCQ_SINGLE,
            points=1,
        )
        question = template.questions.get()
        ExamOption.objects.create(question=question, order=1, option_text='Below 5C', is_correct=True)
        ExamOption.objects.create(question=question, order=2, option_text='Above 20C', is_correct=False)
        template.total_questions = 1
        template.save(update_fields=['total_questions'])
        self.course.exam_template = template
        self.course.save(update_fields=['exam_template'])

        employee_user = User.objects.create_user(username='employee_exam_view', password='pass12345')
        EmployeeProfile.objects.create(user=employee_user, business=self.business, job_title=self.job_title, created_by=self.owner)
        assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.course,
            employee=employee_user,
            assigned_by=self.owner,
        )

        self.client.login(username='employee_exam_view', password='pass12345')
        course_response = self.client.get(reverse('employee_course_view', args=[assignment.id]))
        exam_url = reverse('employee_course_exam', args=[assignment.id])

        self.assertEqual(course_response.status_code, 200)
        self.assertContains(course_response, exam_url)

        exam_response = self.client.get(exam_url)
        self.assertEqual(exam_response.status_code, 200)
        self.assertContains(exam_response, 'Food Safety Final')
        self.assertContains(exam_response, reverse('employee_course_exam_take', args=[assignment.id]))

        take_response = self.client.get(reverse('employee_course_exam_take', args=[assignment.id]))
        self.assertEqual(take_response.status_code, 200)
        self.assertContains(take_response, 'What is the safe storage temperature?')
        attempt_token = self.client.session.get(f'exam-attempt:{assignment.id}', {}).get('token')

        submit_response = self.client.post(
            reverse('employee_course_exam_submit', args=[assignment.id]),
            {
                'attempt_token': attempt_token,
                f'question_{question.id}': str(question.options.get(is_correct=True).id),
            },
            follow=True,
        )
        self.assertEqual(submit_response.status_code, 200)
        self.assertEqual(submit_response.request['PATH_INFO'], reverse('employee_courses'))

        assignment.refresh_from_db()
        self.assertEqual(assignment.status, CourseAssignment.Status.COMPLETED)
        self.assertIsNotNone(assignment.completed_at)
        self.assertFalse(
            ScormCertificate.objects.filter(owner=employee_user, scorm_filename=f'course_exam_{self.course.id}').exists()
        )
        self.assertNotContains(submit_response, 'PDF')
        return

        certificate = ScormCertificate.objects.get(owner=employee_user, scorm_filename=f'course_exam_{self.course.id}')
        self.assertEqual(certificate.course_name, self.course.title)
        self.assertTrue(bool(certificate.pdf_file))

        self.assertContains(submit_response, 'تم اجتياز الاختبار بنجاح')
        self.assertContains(submit_response, 'عرض الشهادة PDF')
        self.assertContains(submit_response, certificate.pdf_file.url)
        return

        courses_response = submit_response
        self.assertContains(courses_response, 'تم اجتياز الاختبار بنجاح')
        self.assertContains(courses_response, 'عرض الشهادة PDF')
        self.assertContains(courses_response, certificate.pdf_file.url)

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

    def test_super_admin_course_list_requires_super_admin_role(self):
        self.client.login(username='owner_sa', password='pass12345')
        response = self.client.get(reverse('super_admin_course_list'))
        self.assertRedirects(response, reverse('home'), fetch_redirect_response=False)

    def test_super_admin_course_list_is_available_for_super_admin(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.get(reverse('super_admin_course_list'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, self.course.title)

    def test_super_admin_scorm_page_is_hidden_when_disabled(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.get(reverse('super_admin_scorm'))
        self.assertRedirects(response, reverse('home'), fetch_redirect_response=False)

    @override_settings(SUPER_ADMIN_SCORM_PAGE_ENABLED=True)
    def test_super_admin_scorm_page_is_available_when_enabled(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.get(reverse('super_admin_scorm'))
        self.assertEqual(response.status_code, 200)

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

    def test_super_admin_can_create_exam_template_and_assign_it_to_single_course(self):
        second_course = Course.objects.create(
            business=self.business,
            title='Kitchen Hygiene',
            estimated_minutes=15,
            created_by=self.owner,
        )
        self.client.login(username='platform_admin', password='pass12345')
        create_response = self.client.post(
            reverse('super_admin_exam_template_create'),
            {
                'primary_course': self.course.id,
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
        second_course.refresh_from_db()
        self.assertEqual(self.course.exam_template_id, template.id)
        self.assertIsNone(second_course.exam_template_id)

        templates_page = self.client.get(reverse('super_admin_exam_templates'))
        self.assertEqual(templates_page.status_code, 200)
        self.assertContains(templates_page, 'Food Safety Final')
        self.assertContains(templates_page, '1')

    def test_super_admin_can_create_question_with_multiple_options(self):
        template = ExamTemplate.objects.create(
            business=self.business,
            name='Capital Cities',
            duration_minutes=15,
            total_questions=0,
            created_by=self.super_admin,
        )
        self.client.login(username='platform_admin', password='pass12345')

        response = self.client.post(
            reverse('super_admin_exam_question_create', args=[template.id]),
            {
                'question_text': 'What is the capital of Saudi Arabia?',
                'question_type': 'MCQ_MULTI',
                'points': 1,
                'is_required': 'on',
                'shuffle_options': 'on',
                'explanation': '',
                'options-TOTAL_FORMS': '4',
                'options-INITIAL_FORMS': '0',
                'options-MIN_NUM_FORMS': '0',
                'options-MAX_NUM_FORMS': '1000',
                'options-0-id': '',
                'options-0-option_text': 'Riyadh',
                'options-0-is_correct': 'on',
                'options-1-id': '',
                'options-1-option_text': 'Alexandria',
                'options-2-id': '',
                'options-2-option_text': 'Jeddah',
                'options-3-id': '',
                'options-3-option_text': 'Cairo',
            },
        )

        self.assertRedirects(response, reverse('super_admin_exam_template_editor', args=[template.id]))
        question = template.questions.get()
        options = list(question.options.order_by('order', 'id'))
        self.assertEqual(len(options), 4)
        self.assertEqual([option.order for option in options], [1, 2, 3, 4])
        self.assertEqual(options[0].option_text, 'Riyadh')

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

    def test_staff_without_superuser_does_not_gain_super_admin_access(self):
        partial_admin = User.objects.create_user(
            username='partial_admin',
            password='pass12345',
            is_staff=True,
            is_superuser=False,
        )
        self.client.login(username='partial_admin', password='pass12345')
        response = self.client.get(reverse('super_admin_dashboard'))
        self.assertRedirects(response, reverse('home'), fetch_redirect_response=False)

    def test_last_active_super_admin_cannot_be_deactivated(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.post(reverse('super_admin_user_toggle_active', args=[self.super_admin.id]), follow=True)

        self.assertEqual(response.status_code, 200)
        self.super_admin.refresh_from_db()
        self.assertTrue(self.super_admin.is_active)

    def test_super_admin_cannot_remove_own_super_admin_role(self):
        self.client.login(username='platform_admin', password='pass12345')
        response = self.client.post(reverse('super_admin_user_toggle_role', args=[self.super_admin.id]), follow=True)
        self.assertEqual(response.status_code, 200)
        self.super_admin.refresh_from_db()
        self.assertTrue(self.super_admin.is_staff)
        self.assertTrue(self.super_admin.is_superuser)


class LoginSecurityTests(TestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user(username='login_guard', password='pass12345')

    def test_login_rate_limit_blocks_after_repeated_failures(self):
        login_url = reverse('login')
        for _ in range(5):
            response = self.client.post(login_url, {'username': 'login_guard', 'password': 'wrong-pass'})
            self.assertEqual(response.status_code, 200)

        response = self.client.post(login_url, {'username': 'login_guard', 'password': 'wrong-pass'})
        self.assertEqual(response.status_code, 429)
        self.assertIn('Retry-After', response.headers)

    def test_login_rate_limit_is_cleared_after_successful_login(self):
        login_url = reverse('login')
        for _ in range(3):
            self.client.post(login_url, {'username': 'login_guard', 'password': 'wrong-pass'})

        response = self.client.post(login_url, {'username': 'login_guard', 'password': 'pass12345'})
        self.assertEqual(response.status_code, 302)


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
