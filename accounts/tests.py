from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse

from accounts.models import BusinessTenant, ContractorProfile, EmployeeProfile, JobTitle
from training.models import (
    Course,
    CourseAssignment,
    CourseAssignmentRule,
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
        self.assertRedirects(response, reverse('business_owner_dashboard'))

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
        self.assertRedirects(response, reverse('employee_dashboard'))

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
        self.assertRedirects(response, reverse('employee_dashboard'))

        completion = SOPChecklistCompletion.objects.get(employee=employee_user, checklist=self.checklist)
        self.assertEqual(completion.notes, 'Morning shift done')
        self.assertEqual(
            SOPChecklistItemCompletion.objects.filter(completion=completion, is_checked=True).count(),
            2,
        )

    def test_legacy_contractor_is_redirected_to_business_owner_dashboard(self):
        legacy_user = User.objects.create_user(username='legacy_owner', password='pass12345')
        ContractorProfile.objects.create(
            user=legacy_user,
            company_name='Legacy Cafe',
            phone_number='0500000000',
        )

        self.client.login(username='legacy_owner', password='pass12345')
        response = self.client.get(reverse('home'))
        self.assertRedirects(response, reverse('business_owner_dashboard'))
        self.assertTrue(BusinessTenant.objects.filter(owner=legacy_user, name='Legacy Cafe').exists())
