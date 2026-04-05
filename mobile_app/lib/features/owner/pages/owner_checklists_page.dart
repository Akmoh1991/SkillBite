// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:skillbite_mobile/app/localization/app_localizations.dart';
import 'package:skillbite_mobile/app/theme/app_theme_tokens.dart';
import 'package:skillbite_mobile/app/widgets/widgets.dart';
import 'package:skillbite_mobile/core/api/mobile_api_client.dart';
import 'package:skillbite_mobile/core/utils/utils.dart';

List<dynamic> _asList(Object? value) => asList(value);
String _readString(dynamic source, String key) => readString(source, key);
int _readInt(dynamic source, String key) => readInt(source, key);
String _readPath(dynamic source, List<String> path) => readPath(source, path);
void _showSnack(BuildContext context, String message) =>
    showSnack(context, message);

const _brandTealDark = brandTealDark;

typedef _HeaderRow = AppHeaderRow;
typedef _HeaderActionButton = AppHeaderActionButton;
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
  final Set<int> expandedChecklistIds = <int>{};

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

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  String _frequencyLabel(String raw) {
    switch (raw) {
      case 'DAILY':
        return 'يومي';
      case 'WEEKLY':
        return 'أسبوعي';
      case 'ON_DEMAND':
        return 'عند الحاجة';
      default:
        return raw;
    }
  }

  Future<void> _showAddMenuDialog(
    List<dynamic> checklists,
    List<dynamic> jobTitles,
  ) async {
    final action = await showDialog<String>(
      context: context,
      requestFocus: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF3FBF8),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () {
                          _dismissKeyboard();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'إغلاق',
                        iconSize: 34,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Text(
                            'إضافة',
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'اختر ما تريد إضافته إلى صفحة المهام.',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF61706C),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      _dismissKeyboard();
                      Navigator.of(context).pop('task');
                    },
                    child: const Text('إضافة مهمة'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: checklists.isEmpty || jobTitles.isEmpty
                        ? null
                        : () {
                            _dismissKeyboard();
                            Navigator.of(context).pop('rule');
                          },
                    child: const Text('إضافة قاعدة'),
                  ),
                ),
                if (checklists.isEmpty || jobTitles.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'لإضافة قاعدة، يجب أن توجد مهمة واحدة على الأقل ومسمى وظيفي واحد.',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF61706C),
                          height: 1.45,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'task') {
      await _showCreateChecklistDialog(jobTitles);
      return;
    }
    if (action == 'rule') {
      await _showCreateRuleDialog(checklists, jobTitles);
    }
  }

  Future<void> _showCreateChecklistDialog(List<dynamic> jobTitles) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final itemsController = TextEditingController();
    String frequency = 'DAILY';
    int? jobTitleId;
    final created = await showDialog<bool>(
      context: context,
      requestFocus: false,
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
                _dismissKeyboard();
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
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () {
                                      _dismissKeyboard();
                                      Navigator.of(context).pop(false);
                                    },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'إغلاق',
                              iconSize: 34,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Text(
                                  'إضافة مهمة',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'أنشئ مهمة متكررة بخطوات واضحة حتى يعرف الفريق ما الذي يجب تنفيذه بدقة.',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      AppTextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'العنوان'),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: frequency,
                        decoration: const InputDecoration(
                          labelText: 'التكرار',
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'DAILY',
                            child: Text('يومي'),
                          ),
                          DropdownMenuItem(
                            value: 'WEEKLY',
                            child: Text('أسبوعي'),
                          ),
                          DropdownMenuItem(
                            value: 'ON_DEMAND',
                            child: Text('عند الحاجة'),
                          ),
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
                        decoration: const InputDecoration(
                          labelText: 'ربط بمسمى وظيفي',
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('بدون ربط تلقائي'),
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
                      AppTextField(
                        controller: itemsController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'العناصر، عنصر في كل سطر',
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'جاري الحفظ...' : 'إنشاء'),
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
    _dismissKeyboard();
    titleController.dispose();
    descriptionController.dispose();
    itemsController.dispose();
    if (created == true) {
      _showSnack(context, 'تم إنشاء المهمة.');
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
      requestFocus: false,
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
                _dismissKeyboard();
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
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconButton(
                              onPressed: saving
                                  ? null
                                  : () {
                                      _dismissKeyboard();
                                      Navigator.of(context).pop(false);
                                    },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'إغلاق',
                              iconSize: 34,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: AlignmentDirectional.topEnd,
                                child: Text(
                                  'إضافة قاعدة',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'اربط المسمى الوظيفي بالمهمة المناسبة حتى يتم الإسناد تلقائيًا بشكل منظم.',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF61706C),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<int?>(
                        initialValue: selectedJobTitleId,
                        decoration: const InputDecoration(
                          labelText: 'المسمى الوظيفي',
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'المهمة',
                        ),
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: saving ? null : submit,
                          child: Text(saving ? 'جاري الحفظ...' : 'إنشاء'),
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
      _showSnack(context, 'تم إنشاء القاعدة.');
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
        return _PageSliverBody(
          slivers: [
            _PageSliverSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderRow(
                    title: 'المهام',
                    titleColor: _brandTealDark,
                    titleFontSize: 26,
                    trailing: _HeaderActionButton(
                      label: 'إضافة',
                      icon: Icons.add,
                      onPressed: () =>
                          _showAddMenuDialog(checklists, jobTitles),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (checklists.isEmpty)
              _PageSliverSection(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: _SectionCard(
                    title: 'المهام',
                    child: Text('لا توجد مهام مضافة حاليًا.'),
                  ),
                ),
              )
            else
              _PageSliverList(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  final checklistId = _readInt(item, 'id');
                  final checklistItems = _asList(item['items']);
                  final expanded = expandedChecklistIds.contains(checklistId);
                  final visibleItems = expanded
                      ? checklistItems
                      : checklistItems.take(3).toList(growable: false);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ManagementRecordCard(
                      title: _readString(item, 'title'),
                      description: _readString(item, 'description').isEmpty
                          ? 'لا يوجد وصف لهذه المهمة حتى الآن.'
                          : _readString(item, 'description'),
                      icon: Icons.checklist_rounded,
                      metadata: [
                        _frequencyLabel(_readString(item, 'frequency')),
                        '${checklistItems.length} عناصر',
                      ],
                      detail: Column(
                        children: [
                          for (final checklistItem in visibleItems)
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () {
                                    setState(() {
                                      if (expanded) {
                                        expandedChecklistIds
                                            .remove(checklistId);
                                      } else {
                                        expandedChecklistIds.add(checklistId);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      '+${checklistItems.length - 3} عناصر إضافية',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: brandTeal,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
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
                  _HeaderRow(
                    title: 'القواعد',
                    titleColor: _brandTealDark,
                    titleFontSize: 26,
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            if (rules.isEmpty)
              _PageSliverSection(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: _SectionCard(
                    title: 'القواعد',
                    child: Text('لا توجد قواعد مضافة حاليًا.'),
                  ),
                ),
              )
            else
              _PageSliverList(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
