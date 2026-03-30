// ignore_for_file: use_build_context_synchronously

part of '../../../main.dart';

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
        final checklists = _asList(payload['checklists']);
        final completedToday = checklists
            .where((item) => _readBool(item, 'completed_today'))
            .length;
        final pendingCount = checklists.length - completedToday;
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
                    trailing: _RoundIconButton(
                      icon: Icons.refresh_rounded,
                      onTap: _reload,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DashboardMetricRow(
                    metrics: [
                      _DashboardMetricData(
                        'Checklists',
                        '${checklists.length}',
                        icon: Icons.fact_check_outlined,
                      ),
                      _DashboardMetricData(
                        'Completed today',
                        '$completedToday',
                        icon: Icons.task_alt_rounded,
                      ),
                      _DashboardMetricData(
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
              const _PageSliverSection(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: _SectionCard(
                  title: 'Checklists',
                  child: Text('No checklists assigned.'),
                ),
              )
            else
              _PageSliverList(
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _NativeLessonTile(
                      title: _readString(item, 'title'),
                      subtitle: _readBool(item, 'completed_today')
                          ? 'Completed today'
                          : 'Pending checklist',
                      accent: _readBool(item, 'completed_today')
                          ? const Color(0xFFEAF7F4)
                          : const Color(0xFFFFF1E7),
                      trailingIcon: _readBool(item, 'completed_today')
                          ? Icons.task_alt_rounded
                          : Icons.checklist_rounded,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmployeeChecklistDetailScreen(
                              api: widget.api,
                              checklistId: _readInt(item, 'id'),
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
      await widget.api
          .post('/employee/checklists/${widget.checklistId}/complete/', {
        'item_ids': selectedItemIds.toList(growable: false),
        'notes': '',
      });
      if (!mounted) return;
      _showSnack(context, 'Checklist completed.');
      setState(() {
        selectedItemIds
          ..clear()
          ..addAll([for (final item in items) _readInt(item, 'id')]);
        future = widget.api.get('/employee/checklists/${widget.checklistId}/');
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
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
          _tr(context, 'Checklist'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _brandTealDark,
                fontSize: 26,
              ),
        ),
      ),
      body: ApiFutureBuilder(
        future: future,
        builder: (context, payload) {
          final checklist = _asMap(payload['checklist']);
          final items = _asList(checklist['items']);
          final completed = _readBool(checklist, 'completed_today');
          final frequency = _readString(checklist, 'frequency');
          final checklistTitle = _readString(checklist, 'title');
          final itemCountLabel = '${items.length} ${_tr(context, 'Items')}';
          final selectedCount =
              completed ? items.length : selectedItemIds.length;
          final allItemsSelected =
              completed || selectedItemIds.length == items.length;
          final canSubmit =
              !completed && !submitting && items.isNotEmpty && allItemsSelected;
          return _PageBody(
            children: [
              _HeaderRow(
                title: checklistTitle.isEmpty ? 'Checklist' : checklistTitle,
                titleColor: _brandTealDark,
                titleFontSize: 26,
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (frequency.isNotEmpty) _tr(context, frequency),
                  itemCountLabel,
                ].join('  |  '),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Items',
                child: items.isEmpty
                    ? const Text('No checklist items.')
                    : Column(
                        children: [
                          for (var index = 0; index < items.length; index++)
                            _ChecklistItemTile(
                              index: index + 1,
                              title: _readString(_asMap(items[index]), 'title'),
                              checked: completed ||
                                  selectedItemIds.contains(
                                    _readInt(_asMap(items[index]), 'id'),
                                  ),
                              enabled: !completed && !submitting,
                              onTap: completed || submitting
                                  ? null
                                  : () {
                                      final itemId =
                                          _readInt(_asMap(items[index]), 'id');
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
              color: checked ? const Color(0xFFD2EBE4) : _line,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: checked ? _brandTeal : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: checked ? _brandTeal : const Color(0xFFD6DEE8),
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
                            color: _brandTealDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _tr(context, title),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.35,
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                        color: enabled || checked ? null : _muted,
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
