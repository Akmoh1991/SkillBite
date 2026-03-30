// ignore_for_file: use_build_context_synchronously

part of '../../../main.dart';

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
          courseId: _readInt(course, 'id'),
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
    return _PageBody(
      children: [
        const _HeaderRow(
          title: 'Workspace overview',
          titleColor: _brandTealDark,
          titleFontSize: 26,
        ),
        const SizedBox(height: 18),
        _DashboardMetricRow(
          metrics: [
            _DashboardMetricData(
              'Employees',
              '${dashboard['employee_total'] ?? 0}',
              icon: Icons.group_outlined,
            ),
            _DashboardMetricData(
              'Courses',
              '${dashboard['course_total'] ?? 0}',
              icon: Icons.menu_book_outlined,
            ),
            _DashboardMetricData(
              'Checklists',
              '${dashboard['checklist_total'] ?? 0}',
              icon: Icons.checklist_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _HeaderRow(
          title: 'Your people',
          trailing: _sectionLink(
            'View all',
            onTap: () => _openEmployeesPage(context),
          ),
        ),
        const SizedBox(height: 14),
        if (employees.isEmpty)
          const _SectionCard(
              title: 'Employees', child: Text('No employees yet.'))
        else
          for (final item in employees.take(3)) ...[
            _NativeLessonTile(
              title: _readString(item, 'display_name'),
              subtitle: _readString(item, 'job_title').isEmpty
                  ? _readString(item, 'username')
                  : _readString(item, 'job_title'),
              accent: const Color(0xFFEFF5FF),
              trailingIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 6),
        _HeaderRow(
          title: 'Courses',
          trailing: _sectionLink(
            'View all',
            onTap: () => _openCoursesPage(context),
          ),
        ),
        const SizedBox(height: 14),
        if (courses.isEmpty)
          const _SectionCard(
              title: 'Courses', child: Text('No assignable courses.'))
        else
          for (final item in courses.take(3)) ...[
            _NativeCoursePromoCard(
              eyebrow: _readString(item, 'business_name').isEmpty
                  ? 'Shared'
                  : 'Workspace',
              title: _readString(item, 'title'),
              meta: _readString(item, 'business_name').isEmpty
                  ? user.businessName
                  : _readString(item, 'business_name'),
              supporting: _readString(item, 'description').isEmpty
                  ? _tr(context, 'Suggested course pushes')
                  : _readString(item, 'description'),
              imageUrl: api.resolveUrl(_readString(item, 'card_image_url')),
              icon: Icons.auto_awesome_motion_rounded,
              onTap: () => _openCourse(context, _asMap(item)),
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
        final dashboard = _asMap(payload['dashboard']);
        final employees = _asList(dashboard['employees']);
        final courses = _asList(dashboard['assignable_courses']);
        return _buildNativeView(context, dashboard, employees, courses);
      },
    );
  }
}
