// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

String _tr(BuildContext context, String english) => tr(context, english);
List<dynamic> _asList(Object? value) => asList(value);
String _readString(dynamic source, String key) => readString(source, key);
int _readInt(dynamic source, String key) => readInt(source, key);
void _showSnack(BuildContext context, String message) =>
    showSnack(context, message);

const _brandTealDark = brandTealDark;

typedef _HeaderRow = AppHeaderRow;
typedef _HeaderActionButton = AppHeaderActionButton;
typedef _DashboardMetricRow = AppDashboardMetricRow;
typedef _DashboardMetricData = AppDashboardMetricData;
typedef _ManagementRecordCard = AppManagementRecordCard;
typedef _RecordDetailLine = AppRecordDetailLine;
typedef _PageSliverBody = AppPageSliverBody;
typedef _PageSliverSection = AppPageSliverSection;
typedef _PageSliverList = AppPageSliverList;

class OwnerJobTitlesPage extends StatefulWidget {
  const OwnerJobTitlesPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<OwnerJobTitlesPage> createState() => _OwnerJobTitlesPageState();
}

class _OwnerJobTitlesPageState extends State<OwnerJobTitlesPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/business-owner/job-titles/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/business-owner/job-titles/');
    });
  }

  Future<void> _showCreateJobTitleDialog() async {
    final nameController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool saving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            Future<void> submit() async {
              setInnerState(() {
                saving = true;
                errorText = null;
              });
              try {
                await widget.api.post('/business-owner/job-titles/create/', {
                  'name': nameController.text.trim(),
                });
                if (!mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                setInnerState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                  saving = false;
                });
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFFF3FBF8),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  MediaQuery.of(context).viewInsets.bottom + 22,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr(context, 'Create Job Title'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _tr(
                          context,
                          'Create a reusable role title to keep employee setup and checklist assignment rules consistent.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      AppTextField(
                        controller: nameController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Title name')),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFC54C2B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: Text(_tr(context, 'Cancel')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'Saving...' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    if (created == true) {
      _showSnack(context, 'Job title created.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final jobTitles = _asList(payload['job_titles']);
        final staffedTitles = jobTitles
            .where((item) => _readInt(item, 'employee_count') > 0)
            .length;
        final emptyTitles = jobTitles.length - staffedTitles;
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderRow(
                    title: 'Job Titles',
                    titleColor: _brandTealDark,
                    titleFontSize: 26,
                    trailing: _HeaderActionButton(
                      label: 'Add',
                      icon: Icons.add,
                      onPressed: _showCreateJobTitleDialog,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Titles',
                        '${jobTitles.length}',
                        icon: Icons.category_rounded,
                      ),
                      _DashboardMetricData(
                        'Staffed',
                        '$staffedTitles',
                        icon: Icons.people_alt_rounded,
                      ),
                      _DashboardMetricData(
                        'Unfilled',
                        '$emptyTitles',
                        icon: Icons.hourglass_empty_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (jobTitles.isEmpty)
              _PageSliverSection(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _ManagementRecordCard(
                  title: 'Create your first role',
                  description:
                      'Job titles make onboarding, checklist automation, and employee organization much cleaner.',
                  icon: Icons.badge_rounded,
                  secondaryActionLabel: _tr(context, 'Create'),
                  onSecondaryAction: _showCreateJobTitleDialog,
                ),
              )
            else
              _PageSliverList(
                itemCount: jobTitles.length,
                itemBuilder: (context, index) {
                  final item = jobTitles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ManagementRecordCard(
                      title: _readString(item, 'name'),
                      description: _readInt(item, 'employee_count') == 0
                          ? 'No active employees are assigned to this title yet.'
                          : 'Use this title to keep assignment rules and employee setup aligned.',
                      icon: Icons.badge_outlined,
                      metadata: [
                        '${_readInt(item, 'employee_count')} active employees'
                      ],
                      detail: const _RecordDetailLine(
                        icon: Icons.rule_folder_outlined,
                        label:
                            'Keep course assignment and onboarding checklist rules anchored to clear job titles.',
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
