import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

class EmployeeChecklistsPage extends StatefulWidget {
  const EmployeeChecklistsPage({super.key, required this.api});

  final MobileApiClient api;

  @override
  State<EmployeeChecklistsPage> createState() => _EmployeeChecklistsPageState();
}

class _EmployeeChecklistsPageState extends State<EmployeeChecklistsPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/employee/checklists/');
  }

  void _reload() {
    setState(() {
      future = widget.api.get('/employee/checklists/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder(
      future: future,
      builder: (context, payload) {
        final checklists = asList(payload['checklists']);
        final completedToday =
            checklists.where((item) => readBool(item, 'completed_today')).length;
        final pendingCount = checklists.length - completedToday;
        return AppPageSliverBody(
          slivers: [
            AppPageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeaderRow(
                    title: 'Checklists',
                    titleColor: brandTealDark,
                    titleFontSize: 26,
                    trailing: AppRoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _reload,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppDashboardMetricRow(
                    metrics: [
                      AppDashboardMetricData(
                        'Checklists',
                        '${checklists.length}',
                        icon: Icons.fact_check_outlined,
                      ),
                      AppDashboardMetricData(
                        'Completed today',
                        '$completedToday',
                        icon: Icons.task_alt_rounded,
                      ),
                      AppDashboardMetricData(
                        'Pending checklists',
                        '$pendingCount',
                        icon: Icons.pending_actions_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (checklists.isEmpty)
              const AppPageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: AppSectionCard(
                  title: 'Checklists',
                  child: Text('No checklists assigned.'),
                ),
              )
            else
              AppPageSliverList(
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppLessonTile(
                      title: readString(item, 'title'),
                      subtitle: readBool(item, 'completed_today')
                          ? 'Completed today'
                          : 'Pending checklist',
                      accent: readBool(item, 'completed_today')
                          ? const Color(0xFFEAF7F4)
                          : const Color(0xFFFFF1E7),
                      trailingIcon: readBool(item, 'completed_today')
                          ? Icons.task_alt_rounded
                          : Icons.checklist_rounded,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmployeeChecklistDetailScreen(
                              api: widget.api,
                              checklistId: readInt(item, 'id'),
                            ),
                          ),
                        );
                        _reload();
                      },
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

class EmployeeChecklistDetailScreen extends StatefulWidget {
  const EmployeeChecklistDetailScreen({
    super.key,
    required this.api,
    required this.checklistId,
  });

  final MobileApiClient api;
  final int checklistId;

  @override
  State<EmployeeChecklistDetailScreen> createState() =>
      _EmployeeChecklistDetailScreenState();
}

class _EmployeeChecklistDetailScreenState
    extends State<EmployeeChecklistDetailScreen> {
  late Future<Map<String, dynamic>> future;
  bool submitting = false;
  final Set<int> selectedItemIds = <int>{};

  @override
  void initState() {
    super.initState();
    future = widget.api.get('/employee/checklists/${widget.checklistId}/');
  }

  Future<void> _completeChecklist(List<dynamic> items) async {
    setState(() => submitting = true);
    try {
      await widget.api.post('/employee/checklists/${widget.checklistId}/complete/', {
        'item_ids': selectedItemIds.toList(growable: false),
        'notes': '',
      });
      if (!mounted) return;
      showSnack(context, 'Checklist completed.');
      setState(() {
        selectedItemIds
          ..clear()
          ..addAll([for (final item in items) readInt(item, 'id')]);
        future = widget.api.get('/employee/checklists/${widget.checklistId}/');
      });
    } catch (error) {
      if (!mounted) return;
      showSnack(context, error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 20,
        title: Text(
          tr(context, 'Checklist'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: brandTealDark,
                fontSize: 26,
              ),
        ),
      ),
      body: ApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final checklist = asMap(payload['checklist']);
          final items = asList(checklist['items']);
          final completed = readBool(checklist, 'completed_today');
          final frequency = readString(checklist, 'frequency');
          final checklistTitle = readString(checklist, 'title');
          final itemCountLabel = '${items.length} ${tr(context, 'Items')}';
          final selectedCount = completed ? items.length : selectedItemIds.length;
          final allItemsSelected =
              completed || selectedItemIds.length == items.length;
          final canSubmit =
              !completed && !submitting && items.isNotEmpty && allItemsSelected;
          return AppPageBody(
            children: [
              AppHeaderRow(
                title: checklistTitle.isEmpty ? 'Checklist' : checklistTitle,
                titleColor: brandTealDark,
                titleFontSize: 26,
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (frequency.isNotEmpty) tr(context, frequency),
                  itemCountLabel,
                ].join('  |  '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 20),
              AppSectionCard(
                title: 'Items',
                child: items.isEmpty
                    ? const Text('No checklist items.')
                    : Column(
                        children: [
                          for (var index = 0; index < items.length; index++)
                            _ChecklistItemTile(
                              index: index + 1,
                              title: readString(asMap(items[index]), 'title'),
                              checked: completed ||
                                  selectedItemIds.contains(
                                    readInt(asMap(items[index]), 'id'),
                                  ),
                              enabled: !completed && !submitting,
                              onTap: completed || submitting
                                  ? null
                                  : () {
                                      final itemId =
                                          readInt(asMap(items[index]), 'id');
                                      setState(() {
                                        if (!selectedItemIds.add(itemId)) {
                                          selectedItemIds.remove(itemId);
                                        }
                                      });
                                    },
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: canSubmit ? () => _completeChecklist(items) : null,
                child: Text(
                  completed
                      ? 'Already Completed'
                      : submitting
                          ? 'Submitting...'
                          : selectedCount == items.length
                              ? 'Complete Checklist'
                              : 'Check All Items',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.index,
    required this.title,
    required this.checked,
    this.enabled = true,
    this.onTap,
  });

  final int index;
  final String title;
  final bool checked;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                        color: enabled || checked ? null : mutedColor,
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
