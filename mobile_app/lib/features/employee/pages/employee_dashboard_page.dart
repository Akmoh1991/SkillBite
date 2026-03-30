part of '../../../main.dart';

class EmployeeDashboardPage extends StatelessWidget {
  const EmployeeDashboardPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  Future<void> _openAssignmentCourse(
      BuildContext context, int assignmentId) async {
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
    return _PageBody(
      bottomPadding: 24,
      children: [
        _HeaderRow(
          title: 'Courses',
          titleColor: _brandTealDark,
          titleFontSize: 26,
          trailing: _sectionLink(
            'View all',
            onTap: () => _openCoursesPage(context),
          ),
        ),
        const SizedBox(height: 16),
        if (assignments.isEmpty)
          const _SectionCard(
              title: 'Courses', child: Text('No active courses.'))
        else
          for (var index = 0; index < visibleAssignments.length; index++) ...[
            _NativeCoursePromoCard(
              eyebrow: _readString(visibleAssignments[index], 'status_label'),
              title: _readPath(visibleAssignments[index], ['course', 'title']),
              meta: '${_readPath(visibleAssignments[index], [
                    'course',
                    'estimated_minutes'
                  ])} ${_tr(context, 'min')}',
              supporting: _readString(
                _asMap(visibleAssignments[index]['course']),
                'description',
              ),
              imageUrl: api.resolveUrl(
                _readPath(
                    visibleAssignments[index], ['course', 'card_image_url']),
              ),
              onTap: () => _openAssignmentCourse(
                context,
                _readInt(visibleAssignments[index], 'id'),
              ),
            ),
            if (index < visibleAssignments.length - 1)
              const SizedBox(height: 14),
          ],
        const SizedBox(height: 8),
        const _HeaderRow(
          title: 'Checklists',
          titleColor: _brandTealDark,
          titleFontSize: 26,
        ),
        const SizedBox(height: 14),
        if (checklists.isEmpty)
          const _SectionCard(
            title: 'Checklists',
            child: Text('No checklists assigned.'),
          )
        else
          for (var index = 0; index < visibleChecklists.length; index++) ...[
            _NativeLessonTile(
              title: _readString(visibleChecklists[index], 'title'),
              subtitle: _readBool(visibleChecklists[index], 'completed_today')
                  ? 'Completed today'
                  : 'Pending checklist',
              accent: const Color(0xFFEAF7F4),
              trailingIcon: Icons.checklist_rounded,
              onTap: () => _openChecklist(
                context,
                _readInt(visibleChecklists[index], 'id'),
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
        final dashboard = _asMap(payload['dashboard']);
        final assignments = _asList(dashboard['dashboard_course_assignments']);
        final checklists = _asList(dashboard['assigned_checklists']);
        return _buildNativeView(context, dashboard, assignments, checklists);
      },
    );
  }
}
