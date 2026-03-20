import os
import re
import unittest

os.environ.setdefault("DJANGO_ALLOW_ASYNC_UNSAFE", "true")

from django.contrib.auth import get_user_model
from django.contrib.staticfiles.testing import StaticLiveServerTestCase
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse

from accounts.models import BusinessTenant, EmployeeProfile, JobTitle
from certification.models import ScormCertificate
from training.models import (
    Course,
    CourseAssignment,
    CourseContentItem,
    SOPChecklist,
    SOPChecklistAssignmentRule,
    SOPChecklistCompletion,
    SOPChecklistItem,
)

try:
    from playwright.sync_api import expect, sync_playwright
except ImportError:  # pragma: no cover
    expect = None
    sync_playwright = None


User = get_user_model()


def _env_bool(key: str, default: bool = False) -> bool:
    return os.getenv(key, str(default)).strip().lower() in {"1", "true", "yes", "on"}


@override_settings(ALLOWED_HOSTS=["localhost", "127.0.0.1", "[::1]"])
class BrowserE2ESmokeTests(StaticLiveServerTestCase):
    host = "localhost"

    @classmethod
    def setUpClass(cls):
        if not _env_bool("RUN_BROWSER_E2E"):
            raise unittest.SkipTest("Set RUN_BROWSER_E2E=1 to run Playwright browser tests.")
        if sync_playwright is None:
            raise unittest.SkipTest("Playwright is not installed.")

        super().setUpClass()
        cls._playwright = sync_playwright().start()
        cls.browser = None

        requested_channel = os.getenv("PLAYWRIGHT_BROWSER_CHANNEL", "").strip()
        channels = [requested_channel] if requested_channel else ["chrome", "msedge"]
        launch_errors = []

        try:
            for channel in channels:
                try:
                    cls.browser = cls._playwright.chromium.launch(
                        channel=channel,
                        headless=_env_bool("PLAYWRIGHT_HEADLESS", True),
                    )
                    break
                except Exception as exc:  # pragma: no cover
                    launch_errors.append(f"{channel}: {exc}")
            if cls.browser is None:
                raise RuntimeError("Unable to launch a supported browser channel.\n" + "\n".join(launch_errors))
        except Exception:
            cls._playwright.stop()
            super().tearDownClass()
            raise

    @classmethod
    def tearDownClass(cls):
        if getattr(cls, "browser", None) is not None:
            cls.browser.close()
        if getattr(cls, "_playwright", None) is not None:
            cls._playwright.stop()
        super().tearDownClass()

    def setUp(self):
        self.owner = User.objects.create_user(username="e2e_owner", password="pass12345")
        self.super_admin = User.objects.create_user(
            username="e2e_admin",
            password="pass12345",
            is_staff=True,
            is_superuser=True,
        )
        self.business = BusinessTenant.objects.create(owner=self.owner, name="E2E Cafe")
        self.job_title = JobTitle.objects.create(business=self.business, name="Cashier")

        self.active_course = Course.objects.create(
            business=self.business,
            title="Cash Register Basics",
            description="Daily opening and closing flow for the register.",
            estimated_minutes=12,
            created_by=self.owner,
        )
        CourseContentItem.objects.create(
            course=self.active_course,
            content_type=CourseContentItem.ContentType.MATERIAL,
            title="Cash register opening",
            body="Verify float balance before serving customers.",
            material_url="https://example.com/register-opening",
            order=1,
        )

        self.history_course = Course.objects.create(
            business=self.business,
            title="Food Safety Basics",
            description="Core hygiene and handling standards for store staff.",
            estimated_minutes=15,
            created_by=self.owner,
        )
        self.assignable_course = Course.objects.create(
            business=self.business,
            title="Shift Handover",
            description="How to pass the shift clearly to the next employee.",
            estimated_minutes=8,
            created_by=self.owner,
        )
        self.toggle_course = Course.objects.create(
            business=self.business,
            title="Inventory Control",
            description="Stock count and reconciliation workflow.",
            estimated_minutes=14,
            created_by=self.owner,
        )

        self.employee_user = User.objects.create_user(username="e2e_employee", password="pass12345")
        self.employee_profile = EmployeeProfile.objects.create(
            user=self.employee_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )
        self.removable_user = User.objects.create_user(username="e2e_remove_me", password="pass12345")
        self.removable_profile = EmployeeProfile.objects.create(
            user=self.removable_user,
            business=self.business,
            job_title=self.job_title,
            created_by=self.owner,
        )
        self.toggle_user = User.objects.create_user(username="e2e_toggle_user", password="pass12345")

        self.active_assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.active_course,
            employee=self.employee_user,
            assigned_by=self.owner,
        )
        self.completed_assignment = CourseAssignment.objects.create(
            business=self.business,
            course=self.history_course,
            employee=self.employee_user,
            assigned_by=self.owner,
            status=CourseAssignment.Status.COMPLETED,
        )
        self.completed_assignment.completed_at = self.completed_assignment.assigned_at
        self.completed_assignment.save(update_fields=["completed_at"])

        certificate = ScormCertificate.objects.create(
            owner=self.employee_user,
            scorm_filename=f"course_exam_{self.history_course.id}",
            course_name=self.history_course.title,
            verification_code="E2E-CERT-1234",
        )
        certificate.pdf_file.save(
            "e2e_history_certificate.pdf",
            SimpleUploadedFile("e2e_history_certificate.pdf", b"%PDF-1.4 e2e certificate", content_type="application/pdf"),
            save=True,
        )

        checklist = SOPChecklist.objects.create(
            business=self.business,
            title="Opening Checklist",
            created_by=self.owner,
        )
        SOPChecklistItem.objects.create(checklist=checklist, title="Count register float", order=1)
        SOPChecklistAssignmentRule.objects.create(
            business=self.business,
            job_title=self.job_title,
            checklist=checklist,
            assigned_by=self.owner,
        )

        self.context = self.browser.new_context(base_url=self.live_server_url)
        self.page = self.context.new_page()
        self.page.set_default_timeout(10000)

    def tearDown(self):
        if getattr(self, "context", None) is not None:
            self.context.close()

    def _url(self, name, *args):
        return f"{self.live_server_url}{reverse(name, args=args)}"

    def _login(self, username: str, password: str, expected_path: str):
        self.page.goto(self._url("login"))
        self.page.locator('input[name="username"]').fill(username)
        self.page.locator('input[name="password"]').fill(password)
        self.page.locator('button[type="submit"]').click()
        self.page.wait_for_url(f"{self.live_server_url}{expected_path}")

    def _logout(self):
        self.page.goto(self._url("logout"))
        self.page.wait_for_url(f"{self.live_server_url}{reverse('home')}")

    def test_business_owner_can_assign_course_from_dashboard_modal(self):
        self._login("e2e_owner", "pass12345", reverse("business_owner_dashboard"))

        modal = self.page.locator("#assign-course-modal")
        self.page.locator("[data-open-assign-modal]").first.click()

        expect(modal).to_have_attribute("aria-hidden", "false")
        option_values = self.page.locator("#assign-course-id option").evaluate_all("nodes => nodes.map(node => node.value)")
        self.assertIn(str(self.assignable_course.id), option_values)
        self.assertNotIn(str(self.active_course.id), option_values)

        self.page.locator("#assign-course-id").select_option(str(self.assignable_course.id))
        self.page.locator("#assign-course-submit").click()
        self.page.wait_for_url(self._url("business_owner_dashboard"))

        expect(self.page.locator(".message-card.success")).to_be_visible()
        self.assertTrue(
            CourseAssignment.objects.filter(
                business=self.business,
                course=self.assignable_course,
                employee=self.employee_user,
            ).exists()
        )

    def test_business_owner_can_create_employee_from_form(self):
        self._login("e2e_owner", "pass12345", reverse("business_owner_dashboard"))

        self.page.goto(self._url("business_owner_employees"))
        self.page.locator("#employee-username").fill("browser_created_employee")
        self.page.locator("#employee-email").fill("browser-created@example.com")
        self.page.locator("#employee-name").fill("Browser Created")
        self.page.locator("#employee-password").fill("pass12345")
        self.page.locator("#employee-job-title").select_option(str(self.job_title.id))
        self.page.locator('form[action="' + reverse("business_owner_employee_create") + '"] button[type="submit"]').click()
        self.page.wait_for_url(self._url("business_owner_employees"))

        expect(self.page.locator(".message-card.success")).to_be_visible()
        self.assertTrue(User.objects.filter(username="browser_created_employee").exists())

        self.page.goto(self._url("business_owner_dashboard"))
        expect(self.page.locator("body")).to_contain_text("browser_created_employee")

    def test_business_owner_can_delete_employee_from_dashboard(self):
        self._login("e2e_owner", "pass12345", reverse("business_owner_dashboard"))

        self.page.once("dialog", lambda dialog: dialog.accept())
        self.page.locator(
            f'form[action="{reverse("business_owner_dashboard_delete_employee", args=[self.removable_profile.id])}"] button'
        ).click()
        self.page.wait_for_url(self._url("business_owner_dashboard"))

        expect(self.page.locator(".message-card.success")).to_be_visible()
        expect(self.page.locator("body")).not_to_contain_text(self.removable_user.username)
        self.removable_profile.refresh_from_db()
        self.removable_user.refresh_from_db()
        self.assertFalse(self.removable_profile.is_active)
        self.assertFalse(self.removable_user.is_active)

    def test_business_owner_can_create_checklist_and_employee_can_complete_it(self):
        self._login("e2e_owner", "pass12345", reverse("business_owner_dashboard"))

        checklist_title = "Closing Checklist Browser"
        self.page.goto(self._url("business_owner_checklists"))
        self.page.locator("#checklist-title").fill(checklist_title)
        self.page.locator("#checklist-description").fill("End-of-shift closure tasks.")
        self.page.locator("#checklist-frequency").select_option("DAILY")
        self.page.locator("#checklist-items").fill("Lock the register\nClean the counter")
        self.page.locator("#checklist-job-title").select_option(str(self.job_title.id))
        self.page.locator('form[action="' + reverse("business_owner_checklist_create") + '"] button[type="submit"]').click()
        self.page.wait_for_url(self._url("business_owner_checklists"))

        expect(self.page.locator(".message-card.success")).to_be_visible()
        checklist = SOPChecklist.objects.get(title=checklist_title)
        self.assertEqual(checklist.items.count(), 2)

        self._logout()
        self._login("e2e_employee", "pass12345", reverse("employee_dashboard"))

        self.page.goto(self._url("employee_checklist_detail", checklist.id))
        expect(self.page.locator(".employee-checklist-detail-page-title")).to_have_text(checklist_title)
        self.page.locator('input[name="item_ids"]').nth(0).check()
        self.page.locator('input[name="item_ids"]').nth(1).check()
        self.page.locator('textarea[name="notes"]').fill("All closing tasks done.")
        self.page.locator('form[action="' + reverse("employee_checklist_complete", args=[checklist.id]) + '"] button[type="submit"]').click()
        self.page.wait_for_url(self._url("employee_checklist_detail", checklist.id))

        expect(self.page.locator(".employee-checklist-done")).to_be_visible()
        completion = SOPChecklistCompletion.objects.get(checklist=checklist, employee=self.employee_user)
        self.assertEqual(completion.notes, "All closing tasks done.")

    def test_employee_can_open_course_details_from_dashboard(self):
        self._login("e2e_employee", "pass12345", reverse("employee_dashboard"))

        self.page.locator(f'a[href="{reverse("employee_course_view", args=[self.active_assignment.id])}"]').first.click()
        self.page.wait_for_url(self._url("employee_course_view", self.active_assignment.id))

        expect(self.page.locator(".course-item-title")).to_have_text("Cash register opening")
        expect(self.page.locator(".course-item-body")).to_contain_text("Verify float balance before serving customers.")
        expect(self.page.locator(".course-item-link a")).to_have_attribute("href", "https://example.com/register-opening")

        self.active_assignment.refresh_from_db()
        self.assertEqual(self.active_assignment.status, CourseAssignment.Status.IN_PROGRESS)

    def test_employee_learning_history_search_filters_rows(self):
        self._login("e2e_employee", "pass12345", reverse("employee_dashboard"))

        self.page.locator(f'a[href="{reverse("employee_learning_history")}"]').click()
        self.page.wait_for_url(self._url("employee_learning_history"))

        visible_row = self.page.locator(".employee-history-row")
        expect(visible_row).to_be_visible()
        expect(self.page.locator(".employee-history-certificate")).to_be_visible()

        self.page.locator("#employee-history-search").fill("nonexistent")
        expect(visible_row).to_be_hidden()
        expect(self.page.locator("#employee-history-empty")).to_have_class(re.compile(r"\bis-visible\b"))

        self.page.locator("#employee-history-search").fill("food safety")
        expect(visible_row).to_be_visible()

    def test_super_admin_can_toggle_course_from_learning_page(self):
        self._login("e2e_admin", "pass12345", reverse("super_admin_dashboard"))

        self.page.goto(self._url("super_admin_learning"))
        self.page.locator(
            f'form[action="{reverse("super_admin_course_toggle", args=[self.toggle_course.id])}"] button'
        ).click()
        self.page.wait_for_url(self._url("super_admin_learning"))

        self.toggle_course.refresh_from_db()
        self.assertFalse(self.toggle_course.is_active)

    def test_super_admin_can_create_business_from_form(self):
        self._login("e2e_admin", "pass12345", reverse("super_admin_dashboard"))

        self.page.goto(self._url("super_admin_business_create_view"))
        self.page.locator("#id_business_name").fill("Browser Launch Co")
        self.page.locator("#id_industry").fill("Retail")
        self.page.locator("#id_owner_username").fill("browser_launch_owner")
        self.page.locator("#id_owner_email").fill("browser-owner@example.com")
        self.page.locator("#id_owner_full_name").fill("Browser Owner")
        self.page.locator("#id_owner_password").fill("pass12345")
        self.page.locator('form[action="' + reverse("super_admin_business_create") + '"] button[type="submit"]').click()
        self.page.wait_for_url(self._url("super_admin_businesses"))

        expect(self.page.locator(".message-card.success")).to_be_visible()
        expect(self.page.locator("body")).to_contain_text("Browser Launch Co")
        self.assertTrue(BusinessTenant.objects.filter(name="Browser Launch Co", owner__username="browser_launch_owner").exists())

    def test_super_admin_can_toggle_business_from_businesses_page(self):
        self._login("e2e_admin", "pass12345", reverse("super_admin_dashboard"))

        self.page.goto(self._url("super_admin_businesses"))
        self.page.locator(
            f'form[action="{reverse("super_admin_business_toggle", args=[self.business.id])}"] button'
        ).click()
        self.page.wait_for_url(self._url("super_admin_businesses"))

        self.business.refresh_from_db()
        self.assertFalse(self.business.is_active)

    def test_super_admin_can_create_user_from_form(self):
        self._login("e2e_admin", "pass12345", reverse("super_admin_dashboard"))

        self.page.goto(self._url("super_admin_user_create_view"))
        self.page.locator("#id_username").fill("browser_admin_user")
        self.page.locator("#id_email").fill("browser-admin@example.com")
        self.page.locator("#id_full_name").fill("Browser Admin")
        self.page.locator("#id_password").fill("pass12345")
        self.page.locator("#id_role").select_option("super_admin")
        self.page.locator('form[action="' + reverse("super_admin_user_create") + '"] button[type="submit"]').click()
        self.page.wait_for_url(self._url("super_admin_users"))

        expect(self.page.locator(".message-card.success")).to_be_visible()
        expect(self.page.locator("body")).to_contain_text("Browser Admin")
        created_user = User.objects.get(username="browser_admin_user")
        self.assertTrue(created_user.is_staff)
        self.assertTrue(created_user.is_superuser)

    def test_super_admin_can_toggle_user_active_from_users_page(self):
        self._login("e2e_admin", "pass12345", reverse("super_admin_dashboard"))

        self.page.goto(self._url("super_admin_users"))
        self.page.locator(
            f'form[action="{reverse("super_admin_user_toggle_active", args=[self.toggle_user.id])}"] button'
        ).click()
        self.page.wait_for_url(self._url("super_admin_users"))

        self.toggle_user.refresh_from_db()
        self.assertFalse(self.toggle_user.is_active)
