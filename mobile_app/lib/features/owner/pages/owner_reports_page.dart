// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

String _tr(BuildContext context, String english) => tr(context, english);
Map<String, dynamic> _asMap(Object? value) => asMap(value);
int _readInt(dynamic source, String key) => readInt(source, key);

const _brandTeal = brandTeal;
const _brandTealDark = brandTealDark;
const _line = lineColor;

typedef _PageBody = AppPageBody;
typedef _HeaderRow = AppHeaderRow;
typedef _DashboardMetricRow = AppDashboardMetricRow;
typedef _DashboardMetricData = AppDashboardMetricData;
typedef _StatusChip = AppStatusChip;

class OwnerReportsPage extends StatelessWidget {
  const OwnerReportsPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: api.get('/business-owner/reports/'),
      builder: (context, payload) {
        final report = _asMap(payload['report']);
        final trackedEmployeeTotal = _readInt(report, 'tracked_employee_total');
        final totalAssigned = _readInt(report, 'total_assigned');
        final totalCompleted = _readInt(report, 'total_completed');
        final totalInProgress = _readInt(report, 'total_in_progress');
        final completionRate = _readInt(report, 'overall_completion_rate');
        final completionProgress =
            totalAssigned == 0 ? 0.0 : totalCompleted / totalAssigned;
        return _PageBody(
          children: [
            const _HeaderRow(
              title: 'Reports',
              titleColor: _brandTealDark,
              titleFontSize: 26,
            ),
            const SizedBox(height: 18),
            _DashboardMetricRow(
              metrics: [
                _DashboardMetricData(
                  'Tracked',
                  '$trackedEmployeeTotal',
                  icon: Icons.people_alt_rounded,
                ),
                _DashboardMetricData(
                  'Assigned',
                  '$totalAssigned',
                  icon: Icons.assignment_turned_in_rounded,
                ),
                _DashboardMetricData(
                  'Completed',
                  '$totalCompleted',
                  icon: Icons.task_alt_rounded,
                ),
                _DashboardMetricData(
                  'In progress',
                  '$totalInProgress',
                  icon: Icons.timelapse_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x100F172A),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tr(context, 'Completion overview'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _StatusChip(label: '$completionRate% complete'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalAssigned == 0
                        ? _tr(
                            context,
                            'Once courses are assigned, you will see completion momentum and progress trends here.',
                          )
                        : _tr(
                            context,
                            'Track how many assignments are completed, still active, and where the next follow-up is needed.',
                          ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF61706C),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: completionProgress.clamp(0, 1),
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE7ECEF),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_brandTeal),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatusChip(label: '$totalCompleted completed'),
                      _StatusChip(
                          label: '${totalAssigned - totalCompleted} remaining'),
                      _StatusChip(label: '$totalInProgress in progress'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
