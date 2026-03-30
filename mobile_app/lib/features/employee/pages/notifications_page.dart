part of '../../../main.dart';

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
      appBar: AppBar(title: Text(_tr(context, 'Notifications'))),
      body: ApiFutureBuilder(
        future: api.get('/notifications/'),
        builder: (context, payload) {
          final summary = _asMap(payload['summary']);
          final notifications = _asList(payload['notifications']);
          return _PageSliverBody(
            slivers: [
              _PageSliverSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tr(context, 'Activity for ')}${user.businessName}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: _muted),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _NotificationSummaryChip(
                          label: _tr(context, 'Unread chat'),
                          value: '${summary['unread_chat_count'] ?? 0}',
                        ),
                        _NotificationSummaryChip(
                          label: user.role == 'employee'
                              ? _tr(context, 'Pending courses')
                              : _tr(context, 'Active employees'),
                          value: user.role == 'employee'
                              ? '${summary['pending_course_count'] ?? 0}'
                              : '${summary['active_employee_count'] ?? 0}',
                        ),
                        _NotificationSummaryChip(
                          label: user.role == 'employee'
                              ? _tr(context, 'Pending checklists')
                              : _tr(context, 'Active courses'),
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
                _PageSliverSection(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: _SectionCard(
                    title: _tr(context, 'All caught up'),
                    child: Text(
                      _tr(context, 'There are no new notifications right now.'),
                    ),
                  ),
                )
              else
                _PageSliverList(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SectionCard(
                        title: _readString(item, 'title'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_readString(item, 'body')),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _StatusChip(
                                  label: _readString(item, 'kind')
                                      .replaceAll('_', ' '),
                                ),
                                const SizedBox(width: 8),
                                if (_readInt(item, 'unread_count') > 0)
                                  _StatusChip(
                                    label:
                                        '${_readInt(item, 'unread_count')} ${_tr(context, 'new')}',
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
