import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';
import 'package:skillbite_mobile/features/chat/chat_page.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_course_detail_screen.dart';
import 'package:skillbite_mobile/features/employee/courses/pages/employee_courses_page.dart';
import 'package:skillbite_mobile/features/employee/pages/employee_checklists_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_courses_page.dart';
import 'package:skillbite_mobile/features/owner/pages/owner_employees_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

  int? _parseEntityId(String rawId, String prefix) {
    if (!rawId.startsWith(prefix)) {
      return null;
    }
    return int.tryParse(rawId.substring(prefix.length));
  }

  Future<void> _openNotification(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final kind = readString(item, 'kind');
    final rawId = readString(item, 'id');

    if (kind == 'team_chat' || kind == 'private_chat') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            api: api,
            roleBasePath:
                user.role == 'employee' ? '/employee' : '/business-owner',
            title: tr(context, 'Chat'),
            initialShowPrivate: kind == 'private_chat',
          ),
        ),
      );
      return;
    }

    if (user.role == 'employee' && kind == 'course_assignment') {
      final assignmentId = _parseEntityId(rawId, 'course-');
      if (assignmentId != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmployeeCourseDetailScreen(
              api: api,
              assignmentId: assignmentId,
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EmployeeCoursesPage(api: api)),
      );
      return;
    }

    if (user.role == 'employee' && kind == 'checklist') {
      final checklistId = _parseEntityId(rawId, 'checklist-');
      if (checklistId != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmployeeChecklistDetailScreen(
              api: api,
              checklistId: checklistId,
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeChecklistsPage(api: api),
        ),
      );
      return;
    }

    if (user.role == 'business_owner' && kind == 'employee') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OwnerEmployeesPage(api: api)),
      );
      return;
    }

    if (user.role == 'business_owner' && kind == 'course_catalog') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OwnerCoursesExplorerScreen(api: api),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'Notifications'))),
      body: ApiFutureBuilder(
        future: api.get('/notifications/'),
        builder: (context, payload) {
          final summary = asMap(payload['summary']);
          final notifications = asList(payload['notifications']);
          return AppPageSliverBody(
            slivers: [
              AppPageSliverSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tr(context, 'Activity for ')}${user.businessName}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: mutedColor),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        AppNotificationSummaryChip(
                          label: tr(context, 'Unread chat'),
                          value: '${summary['unread_chat_count'] ?? 0}',
                        ),
                        AppNotificationSummaryChip(
                          label: user.role == 'employee'
                              ? tr(context, 'Pending courses')
                              : tr(context, 'Active employees'),
                          value: user.role == 'employee'
                              ? '${summary['pending_course_count'] ?? 0}'
                              : '${summary['active_employee_count'] ?? 0}',
                        ),
                        AppNotificationSummaryChip(
                          label: user.role == 'employee'
                              ? tr(context, 'Pending checklists')
                              : tr(context, 'Active courses'),
                          value: user.role == 'employee'
                              ? '${summary['pending_checklist_count'] ?? 0}'
                              : '${summary['active_course_count'] ?? 0}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (notifications.isEmpty)
                AppPageSliverSection(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: AppSectionCard(
                    title: tr(context, 'All caught up'),
                    child: Text(
                      tr(context, 'There are no new notifications right now.'),
                    ),
                  ),
                )
              else
                AppPageSliverList(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = asMap(notifications[index]);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openNotification(context, item),
                        child: AppSectionCard(
                          title: readString(item, 'title'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(readString(item, 'body')),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  AppStatusChip(
                                    label: readString(item, 'kind')
                                        .replaceAll('_', ' '),
                                  ),
                                  const SizedBox(width: 8),
                                  if (readInt(item, 'unread_count') > 0)
                                    AppStatusChip(
                                      label:
                                          '${readInt(item, 'unread_count')} ${tr(context, 'new')}',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () =>
                                      _openNotification(context, item),
                                  child: Text(tr(context, 'Open')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
