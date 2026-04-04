// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

Map<String, dynamic> _asMap(Object? value) => asMap(value);
int _readInt(dynamic source, String key) => readInt(source, key);

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
        final completionProgress =
            totalAssigned == 0 ? 0.0 : totalCompleted / totalAssigned;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'نظرة عامة على الإكمال',
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
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
          ],
        );
      },
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
