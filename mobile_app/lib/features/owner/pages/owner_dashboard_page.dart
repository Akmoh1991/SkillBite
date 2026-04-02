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
    final visibleCourses = courses.take(3).toList(growable: false);
    final visibleEmployees = employees.take(3).toList(growable: false);
    return AppPageBody(
      bottomPadding: 24,
      children: [
        AppHeaderRow(
          title: 'Courses',
          titleColor: brandTealDark,
          titleFontSize: 26,
          trailing: AppSectionLink(
            label: 'View all',
            onTap: () => _openCoursesPage(context),
          ),
        ),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          const AppSectionCard(
            title: 'Courses',
            child: Text('No assignable courses.'),
          )
        else
          for (var index = 0; index < visibleCourses.length; index++) ...[
            AppCoursePromoCard(
              eyebrow: '${dashboard['employee_total'] ?? 0} موظف',
              title: readString(visibleCourses[index], 'title'),
              meta: '',
              forceEyebrowLeft: true,
              inlineTitleWithEyebrow: true,
              supporting: readString(visibleCourses[index], 'description').isEmpty
                  ? tr(context, 'Suggested course pushes')
                  : readString(visibleCourses[index], 'description'),
              imageUrl: api.resolveUrl(
                readString(visibleCourses[index], 'card_image_url'),
              ),
              onTap: () => _openCourse(context, asMap(visibleCourses[index])),
            ),
            if (index < visibleCourses.length - 1)
              const SizedBox(height: 14),
          ],
        const SizedBox(height: 8),
        AppHeaderRow(
          title: 'Employees',
          titleColor: brandTealDark,
          titleFontSize: 26,
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
          for (var index = 0; index < visibleEmployees.length; index++) ...[
            AppLessonTile(
              title: readString(visibleEmployees[index], 'display_name'),
              subtitle: readString(visibleEmployees[index], 'job_title').isEmpty
                  ? (readString(visibleEmployees[index], 'username').isEmpty
                      ? user.businessName
                      : readString(visibleEmployees[index], 'username'))
                  : readString(visibleEmployees[index], 'job_title'),
              accent: const Color(0xFFEAF7F4),
              trailingIcon: Icons.person_outline_rounded,
            ),
            if (index < visibleEmployees.length - 1)
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
