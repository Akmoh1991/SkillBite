import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_course_detail_screen.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_courses_page.dart';
import 'package:skillbite_mobile/features/employee/pages/employee_checklists_page.dart';

class EmployeeDashboardPage extends StatelessWidget {
  const EmployeeDashboardPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  Future<void> _openAssignmentCourse(
    BuildContext context,
    int assignmentId,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeCourseDetailScreen(
          api: api,
          assignmentId: assignmentId,
        ),
      ),
    );
  }

  Future<void> _openChecklist(BuildContext context, int checklistId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeChecklistDetailScreen(
          api: api,
          checklistId: checklistId,
        ),
      ),
    );
  }

  Future<void> _openCoursesPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EmployeeCoursesPage(api: api)),
    );
  }

  Widget _buildNativeView(
    BuildContext context,
    Map<String, dynamic> dashboard,
    List<dynamic> assignments,
    List<dynamic> checklists,
  ) {
    final visibleAssignments = assignments.take(3).toList(growable: false);
    final visibleChecklists = checklists.take(3).toList(growable: false);
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
        if (assignments.isEmpty)
          const AppSectionCard(
            title: 'Courses',
            child: Text('No active courses.'),
          )
        else
          for (var index = 0; index < visibleAssignments.length; index++) ...[
            AppCoursePromoCard(
              eyebrow: readString(visibleAssignments[index], 'status_label'),
              title: readPath(visibleAssignments[index], ['course', 'title']),
              meta: '${readPath(visibleAssignments[index], [
                    'course',
                    'estimated_minutes'
                  ])} ${tr(context, 'min')}',
              supporting: readString(
                asMap(visibleAssignments[index]['course']),
                'description',
              ),
              imageUrl: api.resolveUrl(
                readPath(
                  visibleAssignments[index],
                  ['course', 'card_image_url'],
                ),
              ),
              onTap: () => _openAssignmentCourse(
                context,
                readInt(visibleAssignments[index], 'id'),
              ),
            ),
            if (index < visibleAssignments.length - 1)
              const SizedBox(height: 14),
          ],
        const SizedBox(height: 8),
        const AppHeaderRow(
          title: 'Checklists',
          titleColor: brandTealDark,
          titleFontSize: 26,
        ),
        const SizedBox(height: 14),
        if (checklists.isEmpty)
          const AppSectionCard(
            title: 'Checklists',
            child: Text('No checklists assigned.'),
          )
        else
          for (var index = 0; index < visibleChecklists.length; index++) ...[
            AppLessonTile(
              title: readString(visibleChecklists[index], 'title'),
              subtitle: readBool(visibleChecklists[index], 'completed_today')
                  ? 'Completed today'
                  : 'Pending checklist',
              accent: const Color(0xFFEAF7F4),
              trailingIcon: Icons.checklist_rounded,
              onTap: () => _openChecklist(
                context,
                readInt(visibleChecklists[index], 'id'),
              ),
            ),
            if (index < visibleChecklists.length - 1)
              const SizedBox(height: 14),
          ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/employee/dashboard/'),
      builder: (context, payload) {
        final dashboard = asMap(payload['dashboard']);
        final assignments = asList(dashboard['dashboard_course_assignments']);
        final checklists = asList(dashboard['assigned_checklists']);
        return _buildNativeView(context, dashboard, assignments, checklists);
      },
    );
  }
}
