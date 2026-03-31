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
String _readPath(dynamic source, List<String> path) => readPath(source, path);
void _showSnack(BuildContext context, String message) =>
    showSnack(context, message);

const _brandTealDark = brandTealDark;

typedef _DashboardMetricRow = AppDashboardMetricRow;
typedef _DashboardMetricData = AppDashboardMetricData;
typedef _HeaderRow = AppHeaderRow;
typedef _HeaderActionButton = AppHeaderActionButton;
typedef _HeaderTonalButton = AppHeaderTonalButton;
typedef _ManagementRecordCard = AppManagementRecordCard;
typedef _RuleAssignmentTile = AppRuleAssignmentTile;
typedef _SectionCard = AppSectionCard;
typedef _LoadingState = AppLoadingState;
typedef _ErrorState = AppErrorState;
typedef _PageSliverBody = AppPageSliverBody;
typedef _PageSliverSection = AppPageSliverSection;
typedef _PageSliverList = AppPageSliverList;

class OwnerChecklistsPage extends StatefulWidget {
  const OwnerChecklistsPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<OwnerChecklistsPage> createState() => _OwnerChecklistsPageState();
}

class _OwnerChecklistsPageState extends State<OwnerChecklistsPage> {
  late Future<Map<String, dynamic>> checklistsFuture;
  late Future<Map<String, dynamic>> rulesFuture;
  late Future<Map<String, dynamic>> jobTitlesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      checklistsFuture = widget.api.get('/business-owner/checklists/');
      rulesFuture = widget.api.get('/business-owner/checklist-rules/');
      jobTitlesFuture = widget.api.get('/business-owner/job-titles/');
    });
  }

  Future<void> _showCreateChecklistDialog(List<dynamic> jobTitles) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final itemsController = TextEditingController();
    String frequency = 'DAILY';
    int? jobTitleId;
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
                await widget.api.post('/business-owner/checklists/create/', {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'frequency': frequency,
                  'is_active': true,
                  if (jobTitleId != null) 'job_title': jobTitleId,
                  'items': [
                    for (final line in itemsController.text.split('\n'))
                      if (line.trim().isNotEmpty) line.trim(),
                  ],
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
                        _tr(context, 'Create Checklist'),
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
                          'Design a repeatable routine with clear steps so teams know exactly what good looks like.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: titleController,
                        decoration:
                            InputDecoration(labelText: _tr(context, 'Title')),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Description')),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: frequency,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Frequency')),
                        items: [
                          DropdownMenuItem(
                              value: 'DAILY',
                              child: Text(_tr(context, 'Daily'))),
                          DropdownMenuItem(
                              value: 'WEEKLY',
                              child: Text(_tr(context, 'Weekly'))),
                          DropdownMenuItem(
                              value: 'ON_DEMAND',
                              child: Text(_tr(context, 'On demand'))),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            frequency = value ?? 'DAILY';
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        initialValue: jobTitleId,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Assign to job title')),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child:
                                Text(_tr(context, 'No automatic assignment')),
                          ),
                          for (final rawTitle in jobTitles)
                            DropdownMenuItem<int?>(
                              value: _readInt(rawTitle, 'id'),
                              child: Text(_readString(rawTitle, 'name')),
                            ),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            jobTitleId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: itemsController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: InputDecoration(
                          labelText: _tr(context, 'Items, one per line'),
                          alignLabelWithHint: true,
                        ),
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
    titleController.dispose();
    descriptionController.dispose();
    itemsController.dispose();
    if (created == true) {
      _showSnack(context, 'Checklist created.');
      _reload();
    }
  }

  Future<void> _showCreateRuleDialog(
      List<dynamic> checklists, List<dynamic> jobTitles) async {
    int? selectedChecklistId =
        checklists.isEmpty ? null : _readInt(checklists.first, 'id');
    int? selectedJobTitleId =
        jobTitles.isEmpty ? null : _readInt(jobTitles.first, 'id');
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
                await widget.api
                    .post('/business-owner/checklist-rules/create/', {
                  'job_title': selectedJobTitleId,
                  'checklist': selectedChecklistId,
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
                        _tr(context, 'Create Checklist Rule'),
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
                          'Link a role to the right checklist so onboarding and recurring routines stay automatic.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedJobTitleId,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Job title')),
                        items: [
                          for (final rawTitle in jobTitles)
                            DropdownMenuItem<int?>(
                              value: _readInt(rawTitle, 'id'),
                              child: Text(_readString(rawTitle, 'name')),
                            ),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            selectedJobTitleId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedChecklistId,
                        decoration: InputDecoration(
                            labelText: _tr(context, 'Checklist')),
                        items: [
                          for (final rawChecklist in checklists)
                            DropdownMenuItem<int?>(
                              value: _readInt(rawChecklist, 'id'),
                              child: Text(_readString(rawChecklist, 'title')),
                            ),
                        ],
                        onChanged: (value) {
                          setInnerState(() {
                            selectedChecklistId = value;
                          });
                        },
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
    if (created == true) {
      _showSnack(context, 'Checklist rule created.');
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([checklistsFuture, rulesFuture, jobTitlesFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }
        final checklists = _asList(snapshot.data![0]['checklists']);
        final rules = _asList(snapshot.data![1]['rules']);
        final jobTitles = _asList(snapshot.data![2]['job_titles']);
        final automatedTitleCount = {
          for (final item in rules) _readPath(item, ['job_title', 'name']),
        }.where((name) => name.trim().isNotEmpty).length;
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderRow(
                    title: 'Checklists',
                    titleColor: _brandTealDark,
                    titleFontSize: 26,
                    trailing: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderActionButton(
                          label: 'Add',
                          icon: Icons.add,
                          onPressed: () =>
                              _showCreateChecklistDialog(jobTitles),
                        ),
                        _HeaderTonalButton(
                          label: 'Rule',
                          onPressed: checklists.isEmpty || jobTitles.isEmpty
                              ? null
                              : () =>
                                  _showCreateRuleDialog(checklists, jobTitles),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Checklists',
                        '${checklists.length}',
                        icon: Icons.checklist_rounded,
                      ),
                      _DashboardMetricData(
                        'Rule',
                        '${rules.length}',
                        icon: Icons.account_tree_rounded,
                      ),
                      _DashboardMetricData(
                        'Titles',
                        '$automatedTitleCount',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (checklists.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _SectionCard(
                  title: 'Checklists',
                  child: Text('No checklists created.'),
                ),
              )
            else
              _PageSliverList(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  final checklistItems = _asList(item['items']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ManagementRecordCard(
                      title: _readString(item, 'title'),
                      description: _readString(item, 'description').isEmpty
                          ? 'No checklist description yet.'
                          : _readString(item, 'description'),
                      icon: Icons.checklist_rounded,
                      metadata: [
                        _readString(item, 'frequency'),
                        '${checklistItems.length} ${_tr(context, 'Items')}',
                      ],
                      detail: Column(
                        children: [
                          for (final checklistItem in checklistItems.take(3))
                            _ChecklistItemTile(
                              index: checklistItems.indexOf(checklistItem) + 1,
                              title: _readString(checklistItem, 'title'),
                              checked: false,
                            ),
                          if (checklistItems.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '+${checklistItems.length - 3} more items',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            _PageSliverSection(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _HeaderRow(title: 'Assignment rules'),
                  SizedBox(height: 16),
                ],
              ),
            ),
            if (rules.isEmpty)
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _SectionCard(
                  title: 'Assignment Rules',
                  child: Text('No checklist rules yet.'),
                ),
              )
            else
              _PageSliverList(
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  final item = rules[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RuleAssignmentTile(
                      jobTitle: _readPath(item, ['job_title', 'name']),
                      checklistTitle: _readPath(item, ['checklist', 'title']),
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

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.index,
    required this.title,
    required this.checked,
  });

  final int index;
  final String title;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFEAF7F4) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: checked ? const Color(0xFFD2EBE4) : lineColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: checked ? brandTeal : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: checked ? brandTeal : const Color(0xFFD6DEE8),
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: checked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        )
                      : Text(
                          '$index',
                          style: const TextStyle(
                            color: brandTealDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr(context, title),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.35,
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
