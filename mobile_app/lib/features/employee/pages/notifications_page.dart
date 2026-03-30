import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/session/session_user.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.api,
    required this.user,
  });

  final MobileApiClient api;
  final SessionUser user;

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
                    final item = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
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
                          ],
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
