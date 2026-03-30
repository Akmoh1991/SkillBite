// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_course_detail_screen.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_courses_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_employees_page.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  Future<void> _openCoursesPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerCoursesExplorerScreen(api: api),
      ),
    );
  }

  Future<void> _openEmployeesPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerEmployeesPage(api: api),
      ),
    );
  }

  Future<void> _openCourse(
    BuildContext context,
    Map<String, dynamic> course,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerCourseDetailScreen(
          api: api,
          courseId: readInt(course, 'id'),
          initialCourse: course,
        ),
      ),
    );
  }

  Widget _buildNativeView(
    BuildContext context,
    Map<String, dynamic> dashboard,
    List<dynamic> employees,
    List<dynamic> courses,
  ) {
    return AppPageBody(
      children: [
        const AppHeaderRow(
          title: 'Workspace overview',
          titleColor: brandTealDark,
          titleFontSize: 26,
        ),
        const SizedBox(height: 18),
        AppDashboardMetricRow(
          metrics: [
            AppDashboardMetricData(
              'Employees',
              '${dashboard['employee_total'] ?? 0}',
              icon: Icons.group_outlined,
            ),
            AppDashboardMetricData(
              'Courses',
              '${dashboard['course_total'] ?? 0}',
              icon: Icons.menu_book_outlined,
            ),
            AppDashboardMetricData(
              'Checklists',
              '${dashboard['checklist_total'] ?? 0}',
              icon: Icons.checklist_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppHeaderRow(
          title: 'Your people',
          trailing: AppSectionLink(
            label: 'View all',
            onTap: () => _openEmployeesPage(context),
          ),
        ),
        const SizedBox(height: 14),
        if (employees.isEmpty)
          const AppSectionCard(
            title: 'Employees',
            child: Text('No employees yet.'),
          )
        else
          for (final item in employees.take(3)) ...[
            AppLessonTile(
              title: readString(item, 'display_name'),
              subtitle: readString(item, 'job_title').isEmpty
                  ? readString(item, 'username')
                  : readString(item, 'job_title'),
              accent: const Color(0xFFEFF5FF),
              trailingIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 6),
        AppHeaderRow(
          title: 'Courses',
          trailing: AppSectionLink(
            label: 'View all',
            onTap: () => _openCoursesPage(context),
          ),
        ),
        const SizedBox(height: 14),
        if (courses.isEmpty)
          const AppSectionCard(
            title: 'Courses',
            child: Text('No assignable courses.'),
          )
        else
          for (final item in courses.take(3)) ...[
            AppCoursePromoCard(
              eyebrow: readString(item, 'business_name').isEmpty
                  ? 'Shared'
                  : 'Workspace',
              title: readString(item, 'title'),
              meta: readString(item, 'business_name').isEmpty
                  ? user.businessName
                  : readString(item, 'business_name'),
              supporting: readString(item, 'description').isEmpty
                  ? tr(context, 'Suggested course pushes')
                  : readString(item, 'description'),
              imageUrl: api.resolveUrl(readString(item, 'card_image_url')),
              icon: Icons.auto_awesome_motion_rounded,
              onTap: () => _openCourse(context, asMap(item)),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/business-owner/dashboard/'),
      builder: (context, payload) {
        final dashboard = asMap(payload['dashboard']);
        final employees = asList(dashboard['employees']);
        final courses = asList(dashboard['assignable_courses']);
        return _buildNativeView(context, dashboard, employees, courses);
      },
    );
  }
}
