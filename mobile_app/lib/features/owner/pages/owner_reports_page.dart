// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

Map<String, dynamic> _asMap(Object? value) => asMap(value);
List<dynamic> _asList(Object? value) => asList(value);
int _readInt(dynamic source, String key) => readInt(source, key);
String _readString(dynamic source, String key) => readString(source, key);

const _brandTeal = brandTeal;
const _brandTealDark = brandTealDark;
const _line = lineColor;

typedef _PageBody = AppPageBody;
typedef _HeaderRow = AppHeaderRow;

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
        final assignedChecklistEmployeeTotal =
            _readInt(report, 'assigned_checklist_employee_total');
        final completedChecklistEmployeeTotal =
            _readInt(report, 'completed_checklist_employee_total');
        final pendingChecklistEmployeeTotal =
            _readInt(report, 'pending_checklist_employee_total');
        final todayChecklistStatuses =
            _asList(report['today_checklist_statuses']);
        final completionProgress =
            totalAssigned == 0 ? 0.0 : totalCompleted / totalAssigned;
        final dailyChecklistCompletionRate = assignedChecklistEmployeeTotal == 0
            ? 0
            : ((completedChecklistEmployeeTotal / assignedChecklistEmployeeTotal) *
                    100)
                .round();

        return _PageBody(
          children: [
            const _HeaderRow(
              title: 'التقارير',
              titleColor: _brandTealDark,
              titleFontSize: 26,
            ),
            const SizedBox(height: 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'نظرة عامة على الإكمال',
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: _brandTealDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F6F8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$completionRate% مكتمل',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: _brandTealDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalAssigned == 0
                        ? 'بعد إسناد الدورات ستظهر هنا حالة الإكمال ونسبة التقدم للموظفين.'
                        : 'تابع عدد الدورات المسندة والمكتملة والجارية لمعرفة أين تحتاج المتابعة التالية.',
                    textAlign: TextAlign.right,
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FCFB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      children: [
                        _ReportStatRow(
                          label: 'الموظفون المتابعون',
                          value: '$trackedEmployeeTotal',
                        ),
                        const Divider(height: 1, color: _line),
                        _ReportStatRow(
                          label: 'الدورات المسندة',
                          value: '$totalAssigned',
                        ),
                        const Divider(height: 1, color: _line),
                        _ReportStatRow(
                          label: 'الدورات المكتملة',
                          value: '$totalCompleted',
                        ),
                        const Divider(height: 1, color: _line),
                        _ReportStatRow(
                          label: 'قيد التنفيذ',
                          value: '$totalInProgress',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'حالة مهام اليوم',
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: _brandTealDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F6F8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$dailyChecklistCompletionRate% ${tr(context, 'Completed')}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: _brandTealDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    assignedChecklistEmployeeTotal == 0
                        ? 'لا توجد قوائم تحقق مسندة اليوم للموظفين المتابعين.'
                        : 'يوضح هذا القسم من أكمل قائمة التحقق اليومية ومن ما زال لديه عناصر معلقة.',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF61706C),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FCFB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      children: [
                        _ReportStatRow(
                          label: 'الموظفون بقوائم تحقق اليوم',
                          value: '$assignedChecklistEmployeeTotal',
                        ),
                        const Divider(height: 1, color: _line),
                        _ReportStatRow(
                          label: 'أكملوا اليوم',
                          value: '$completedChecklistEmployeeTotal',
                        ),
                        const Divider(height: 1, color: _line),
                        _ReportStatRow(
                          label: 'بانتظار الإكمال',
                          value: '$pendingChecklistEmployeeTotal',
                        ),
                      ],
                    ),
                  ),
                  if (todayChecklistStatuses.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    for (var index = 0;
                        index < todayChecklistStatuses.length;
                        index++) ...[
                      _ChecklistStatusTile(
                        item: _asMap(todayChecklistStatuses[index]),
                      ),
                      if (index < todayChecklistStatuses.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChecklistStatusTile extends StatelessWidget {
  const _ChecklistStatusTile({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final employee = _asMap(item['employee']);
    final assignedTotal = _readInt(item, 'assigned_checklist_total');
    final completedTotal = _readInt(item, 'completed_checklist_total');
    final pendingTotal = _readInt(item, 'pending_checklist_total');
    final statusCode = _readString(item, 'status_code');
    final statusLabel = _readString(item, 'status_label');
    final statusColor = switch (statusCode) {
      'completed' => const Color(0xFFEAF7F4),
      'pending' => const Color(0xFFFFF1E7),
      _ => const Color(0xFFF1F6F8),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tr(context, statusLabel),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _brandTealDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _readString(employee, 'display_name'),
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (_readString(employee, 'job_title').isNotEmpty)
                      Text(
                        _readString(employee, 'job_title'),
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ChecklistMiniStat(
                value: '$pendingTotal',
                label: 'Pending',
              ),
              const SizedBox(width: 10),
              _ChecklistMiniStat(
                value: '$completedTotal',
                label: 'Completed',
              ),
              const SizedBox(width: 10),
              _ChecklistMiniStat(
                value: '$assignedTotal',
                label: 'Assigned',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChecklistMiniStat extends StatelessWidget {
  const _ChecklistMiniStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _brandTealDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(context, label),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF61706C),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStatRow extends StatelessWidget {
  const _ReportStatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _brandTealDark,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF34433F),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
